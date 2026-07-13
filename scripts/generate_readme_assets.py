"""Validate the bundled sources and regenerate the README's quantitative assets.

The transformations mirror the repository's T-SQL for the checks and metrics
used in the documentation. Run this file from any working directory.
"""

from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
DATASETS = ROOT / "datasets"
ASSETS = ROOT / "assets"
OUTPUTS = ROOT / "analysis_outputs"
ASSETS.mkdir(exist_ok=True)
OUTPUTS.mkdir(exist_ok=True)


def read_csv(relative_path: str) -> pd.DataFrame:
    return pd.read_csv(DATASETS / relative_path, na_values=["", "NA"])


customers_raw = read_csv("source_crm/cust_info.csv")
products_raw = read_csv("source_crm/prd_info.csv")
sales_raw = read_csv("source_crm/sales_details.csv")
erp_customers = read_csv("source_erp/CUST_AZ12.csv")
erp_locations = read_csv("source_erp/LOC_A101.csv")
erp_categories = read_csv("source_erp/PX_CAT_G1V2.csv")

# Customer Silver logic: remove null IDs and keep the newest record per ID.
customers = customers_raw.dropna(subset=["cst_id"]).copy()
customers["cst_create_date"] = pd.to_datetime(customers["cst_create_date"])
customers = (
    customers.sort_values(["cst_id", "cst_create_date"], ascending=[True, False])
    .drop_duplicates("cst_id", keep="first")
    .reset_index(drop=True)
)

erp_locations = erp_locations.copy()
erp_locations["customer_number"] = erp_locations["CID"].str.replace("-", "", regex=False)
country_map = {"DE": "Germany", "US": "United States", "USA": "United States"}
erp_locations["country"] = (
    erp_locations["CNTRY"].str.strip().replace(country_map).fillna("n/a")
)
customers = customers.merge(
    erp_locations[["customer_number", "country"]],
    left_on="cst_key",
    right_on="customer_number",
    how="left",
    validate="one_to_one",
)

# Product Silver logic: split the compound product key and harmonize the known
# CRM CO_PE versus ERP CO_PD representation for Components / Pedals.
products = products_raw.copy()
products["start_date"] = pd.to_datetime(products["prd_start_dt"])
products["category_id_before_harmonization"] = (
    products["prd_key"].str.slice(0, 5).str.replace("-", "_", regex=False)
)
products["category_id"] = products["category_id_before_harmonization"].replace(
    {"CO_PE": "CO_PD"}
)
products["product_number"] = products["prd_key"].str.slice(6)
products["product_line"] = (
    products["prd_line"]
    .str.strip()
    .str.upper()
    .map({"M": "Mountain", "R": "Road", "S": "Other Sales", "T": "Touring"})
    .fillna("n/a")
)
active_products = (
    products.sort_values(["prd_key", "start_date"])
    .drop_duplicates("prd_key", keep="last")
    .merge(
        erp_categories.rename(
            columns={
                "ID": "category_id",
                "CAT": "category",
                "SUBCAT": "subcategory",
                "MAINTENANCE": "maintenance",
            }
        ),
        on="category_id",
        how="left",
        validate="many_to_one",
    )
)

# Sales Silver logic, including SQL CASE semantics when either sales or price
# is missing. The source's invalid integer dates become null DATE values.
sales = sales_raw.copy()
quantity = sales["sls_quantity"]
raw_amount = sales["sls_sales"]
raw_price = sales["sls_price"]
amount_needs_repair = (
    raw_amount.isna()
    | raw_amount.le(0)
    | (raw_amount.notna() & raw_price.notna() & raw_amount.ne(quantity * raw_price.abs()))
)
price_needs_repair = raw_price.isna() | raw_price.le(0)

sales["sales_amount"] = raw_amount.copy()
sales.loc[amount_needs_repair, "sales_amount"] = (
    quantity[amount_needs_repair] * raw_price[amount_needs_repair].abs()
)
sales["price"] = raw_price.copy()
sales.loc[price_needs_repair, "price"] = (
    raw_amount[price_needs_repair] / quantity[price_needs_repair]
)


def parse_integer_date(series: pd.Series) -> pd.Series:
    text = series.astype("Int64").astype("string")
    text = text.where(text.str.len().eq(8) & text.ne("0"))
    return pd.to_datetime(text, format="%Y%m%d", errors="coerce")


sales["order_date"] = parse_integer_date(sales["sls_order_dt"])
sales["shipping_date"] = parse_integer_date(sales["sls_ship_dt"])
sales["due_date"] = parse_integer_date(sales["sls_due_dt"])
sales = sales.merge(
    customers[["cst_id", "country"]],
    left_on="sls_cust_id",
    right_on="cst_id",
    how="left",
    validate="many_to_one",
)
sales = sales.merge(
    active_products[["product_number", "product_line", "category"]],
    left_on="sls_prd_key",
    right_on="product_number",
    how="left",
    validate="many_to_one",
)

# High-value assertions: failures here mean the documented warehouse grain or
# metrics no longer agree with the committed sources and transformations.
assert len(customers_raw) == 18_494
assert len(products_raw) == 397
assert len(sales_raw) == 60_398
assert len(customers) == 18_484 and customers["cst_id"].is_unique
assert len(active_products) == 295 and active_products["product_number"].is_unique
assert sales["cst_id"].notna().all() and sales["product_number"].notna().all()
assert active_products[["category", "subcategory", "maintenance"]].notna().all().all()
assert sales[["sales_amount", "price"]].notna().all().all()
assert int(sales["sales_amount"].sum()) == 29_356_250

metrics = pd.DataFrame(
    [
        ("raw_crm_customer_rows", len(customers_raw)),
        ("raw_crm_product_rows", len(products_raw)),
        ("raw_crm_sales_rows", len(sales_raw)),
        ("raw_customer_null_ids", int(customers_raw["cst_id"].isna().sum())),
        (
            "raw_customer_duplicate_id_excess",
            int(customers_raw["cst_id"].notna().sum() - customers_raw["cst_id"].nunique()),
        ),
        ("silver_customer_rows", len(customers)),
        ("silver_product_rows", len(products)),
        ("gold_active_product_rows", len(active_products)),
        ("gold_fact_sales_rows", len(sales)),
        ("sales_amount_rows_repaired", int(amount_needs_repair.sum())),
        ("sales_price_rows_repaired", int(price_needs_repair.sum())),
        ("sales_missing_order_date_rows", int(sales["order_date"].isna().sum())),
        (
            "active_product_category_matches_before_harmonization",
            int(
                products.sort_values(["prd_key", "start_date"])
                .drop_duplicates("prd_key", keep="last")[
                    "category_id_before_harmonization"
                ]
                .isin(erp_categories["ID"])
                .sum()
            ),
        ),
        ("active_product_category_matches_after_harmonization", 295),
        ("total_revenue", int(sales["sales_amount"].sum())),
        ("distinct_orders", int(sales["sls_ord_num"].nunique())),
        ("distinct_customers_in_fact", int(sales["sls_cust_id"].nunique())),
        (
            "average_order_value",
            float(sales.groupby("sls_ord_num")["sales_amount"].sum().mean()),
        ),
        (
            "average_revenue_per_customer",
            float(sales.groupby("sls_cust_id")["sales_amount"].sum().mean()),
        ),
    ],
    columns=["metric", "value"],
)
metrics["value"] = metrics["value"].map(lambda value: f"{value:.12g}")
metrics.to_csv(OUTPUTS / "validated_metrics.csv", index=False)

# Chart 1: small multiples avoid comparing differently sized entities on one
# misleading shared scale. Exact values remain visible above every bar.
row_flow = {
    "Customers": [len(customers_raw), len(customers), len(customers)],
    "Products": [len(products_raw), len(products), len(active_products)],
    "Sales lines": [len(sales_raw), len(sales), len(sales)],
}
layers = ["Bronze", "Silver", "Gold"]
colors = ["#1F4E79", "#D9A441", "#D9822B"]

fig, axes = plt.subplots(1, 3, figsize=(12, 4.8))
for axis, (entity, values) in zip(axes, row_flow.items()):
    bars = axis.bar(layers, values, color=colors, edgecolor="#263238", linewidth=0.8)
    axis.set_title(entity, fontsize=12, fontweight="bold", color="#263238")
    axis.set_ylim(0, max(values) * 1.22)
    axis.yaxis.set_major_formatter(mtick.StrMethodFormatter("{x:,.0f}"))
    axis.grid(axis="y", color="#E0E4E8", linewidth=0.8)
    axis.set_axisbelow(True)
    axis.spines[["top", "right"]].set_visible(False)
    for bar, value in zip(bars, values):
        axis.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + max(values) * 0.025,
            f"{value:,}",
            ha="center",
            va="bottom",
            fontsize=9,
            color="#263238",
        )

fig.suptitle(
    "Expected record flow across warehouse layers",
    fontsize=16,
    fontweight="bold",
    color="#263238",
    y=1.02,
)
fig.text(
    0.5,
    0.955,
    "Independent scales by entity; Gold products retain the 295 active versions",
    ha="center",
    fontsize=10,
    color="#546E7A",
)
fig.text(
    0.01,
    0.01,
    "Source: bundled CRM/ERP CSVs; transformations mirror warehouse_queries/silver/proc_load_silver.sql",
    fontsize=8.5,
    color="#607D8B",
)
fig.tight_layout(rect=[0, 0.055, 1, 0.92])
fig.savefig(ASSETS / "warehouse_record_flow.png", dpi=220, bbox_inches="tight", facecolor="white")
plt.close(fig)

# Chart 2: 38 monthly observations are sufficient for a trend view. The first
# and last months are partial, and 19 invalid-date rows are explicitly excluded.
monthly = (
    sales.dropna(subset=["order_date"])
    .set_index("order_date")["sales_amount"]
    .resample("MS")
    .sum()
)
assert len(monthly) == 38

fig, axis = plt.subplots(figsize=(10, 5))
axis.plot(
    monthly.index,
    monthly.values,
    color="#1F4E79",
    linewidth=2.2,
    marker="o",
    markersize=3.5,
    markerfacecolor="white",
    markeredgewidth=1.2,
)
axis.fill_between(monthly.index, monthly.values, color="#1F4E79", alpha=0.08)
axis.set_ylim(bottom=0)
axis.yaxis.set_major_formatter(mtick.FuncFormatter(lambda value, _: f"${value / 1_000_000:.1f}M"))
axis.grid(axis="y", color="#E0E4E8", linewidth=0.8)
axis.set_axisbelow(True)
axis.spines[["top", "right"]].set_visible(False)
axis.set_title(
    "Monthly sales revenue",
    loc="left",
    fontsize=16,
    fontweight="bold",
    color="#263238",
    pad=24,
)
axis.text(
    0,
    1.02,
    "38 monthly points from 60,379 dated sales lines; endpoint months are partial",
    transform=axis.transAxes,
    fontsize=10,
    color="#546E7A",
)
fig.text(
    0.01,
    0.01,
    "Note: 19 lines with invalid source order dates ($4,992 revenue) are excluded. Source: sales_details.csv.",
    fontsize=8.5,
    color="#607D8B",
)
fig.tight_layout(rect=[0, 0.055, 1, 1])
fig.savefig(ASSETS / "monthly_sales_revenue.png", dpi=220, bbox_inches="tight", facecolor="white")
plt.close(fig)

print("Validated metrics and README figures generated successfully.")
