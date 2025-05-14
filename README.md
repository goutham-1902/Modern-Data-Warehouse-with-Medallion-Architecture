Modern Data Warehouse Project with SQL Server (Docker-Based)
============================================================

Overview
--------

This project demonstrates how to build a modern, cloud-ready data warehouse using **SQL Server hosted in Docker**, modeled around the **Medallion Architecture (Bronze, Silver, Gold layers)**. It simulates a business use case by consolidating sales data from two systems — ERP and CRM — delivered as CSV files. The pipeline transforms raw data into analytical insights through dimensional modeling and structured ETL workflows.

This setup is ideal for developers, data engineers, or analysts looking to understand the complete lifecycle of enterprise data management using open technologies.

Architecture
------------

**Medallion Architecture** is followed to ensure clarity, scalability, and data quality:

*   **Bronze Layer:**Raw ingestion of ERP and CRM CSV files, minimal transformation for traceability.
    
*   **Silver Layer:**Cleansing (null handling, format normalization), deduplication, and joining of CRM and ERP data.
    
*   **Gold Layer:**Dimensional modeling into Fact and Dimension tables ready for analytics and business intelligence.
    

Tech Stack
----------

*   SQL Server (Azure SQL Edge via Docker)
    
*   SQL Server Management Studio (SSMS) / VS Code SQL Tools Extension
    
*   Python + Jupyter Notebook
    
*   Pandas, pyodbc (for DB connection and querying)
    
*   GitHub (Version Control)
    

ETL Pipeline Breakdown
----------------------

Each layer of the ETL process builds on the previous, transitioning data from raw to refined:

1.  **Extract:** Load CSV data into SQL Server's Bronze Layer.
    
2.  **Transform:** Cleanse and merge CRM and ERP data in Silver Layer.
    
3.  **Load:** Model structured Fact and Dimension tables in Gold Layer.
    
4.  **Analyze:** Use Jupyter Notebook to query and visualize insights directly from Gold Layer.
    

Key transformations include:

*   Date parsing & normalization
    
*   Null handling & deduplication
    
*   Surrogate key generation
    
*   Merging customer and sales datasets
    

Analytics & Insights
--------------------

Using Python and Jupyter, the Gold Layer enables advanced analysis:

*   Top-performing products and regions
    
*   Monthly sales trends
    
*   Customer segmentation by sales volume
    

These insights support data-driven decisions and simulate real-world business intelligence use cases.

Installation & Setup
--------------------

### Prerequisites

*   Docker installed on your machine
    
*   SQL Server Management Studio (SSMS) or VS Code with SQL Tools Extension
    
*   Python 3.8+ with pip
    
*   Jupyter Notebook or Jupyter Lab
    

### Step 1: Launch SQL Server via Docker

Run the following command in your terminal:

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   bashCopyEditdocker run \    -e "ACCEPT_EULA=1" \    -e "MSSQL_SA_PASSWORD=MyStrongPass123" \    -e "MSSQL_PID=Developer" \    -p 1433:1433 \    -v ~/projects/my_dwh_prj:/my_dwh_prj \    --name sqlserver \    -d mcr.microsoft.com/azure-sql-edge   `

This spins up a SQL Server instance inside a container, making your project portable and replicable across machines or teams.

> **Note**: You can stop and start the server using docker stop sqlserver and docker start sqlserver.

### Step 2: Connect to SQL Server

#### Option A: Using SSMS

*   Open SSMS and connect to:
    
    *   **Server name:** localhost,1433
        
    *   **Authentication:** SQL Server Authentication
        
    *   **Login:** sa
        
    *   **Password:** MyStrongPass123
        

#### Option B: Using VS Code

*   Install the **SQL Server (mssql)** extension.
    
*   Create a new connection using the same credentials as above.
    

### Step 3: Install Python Dependencies

Create a virtual environment and install required libraries:

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   bashCopyEditpython -m venv venv  source venv/bin/activate  # For Windows: venv\Scripts\activate  pip install pandas pyodbc jupyter notebook   `

Ensure you have an ODBC Driver for SQL Server installed (ODBC Driver 17+ recommended).

### Step 4: Run SQL Scripts and Notebooks

1.  Run SQL scripts for schema creation and ETL from the repository in SSMS or VS Code.
    
2.  Open the provided Jupyter notebook and execute cells to:
    
    *   Connect to the SQL Server
        
    *   Run queries on the Gold Layer
        
    *   Visualize business insights
        

Skills Demonstrated
-------------------

*   Data Architecture & Modeling
    
*   SQL Development & Optimization
    
*   ETL Pipeline Engineering
    
*   Python + SQL Integration
    
*   Docker-based Infrastructure
    
*   Business Intelligence and Analytics
    

Future Work
-----------

To extend this project into a production-grade data solution:

*   **Azure Integration**: Connect SQL Server to Azure Blob Storage for scalable data ingestion.
    
*   **Web Scraping Pipeline**: Integrate a Python-based web scraping pipeline to collect external data and feed it through the same ETL process.
    
*   **Automation & Scheduling**: Add orchestration using Apache Airflow or Azure Data Factory.
    
*   **Power BI or Looker**: Connect Gold Layer to BI tools for dashboarding.
    

License
-------

This project is provided under the MIT License.
