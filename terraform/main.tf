terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "dynamicportfolio" {
  name     = "portfolio-resources"
  location = "Central India"
}

# Storage Account for Static Website
resource "azurerm_storage_account" "portfolioStorage" {
  name                     = "portfoliostorageacct" # Must be globally unique
  resource_group_name      = azurerm_resource_group.dynamicportfolio.name
  location                 = azurerm_resource_group.dynamicportfolio.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

# Storage Container for Static Content
resource "azurerm_storage_container" "static_content" {
  name                  = "$web"
  storage_account_name  = azurerm_storage_account.portfolioStorage.name
  container_access_type = "blob"
}

# Upload Static Files
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.portfolioStorage.name
  storage_container_name = azurerm_storage_container.static_content.name
  type                   = "Block"
  source                 = "resume/index.html"
}

resource "azurerm_storage_blob" "style_css" {
  name                   = "style.css"
  storage_account_name   = azurerm_storage_account.portfolioStorage.name
  storage_container_name = azurerm_storage_container.static_content.name
  type                   = "Block"
  source                 = "resume/style.css"
}

resource "azurerm_storage_blob" "script_js" {
  name                   = "script.js"
  storage_account_name   = azurerm_storage_account.portfolioStorage.name
  storage_container_name = azurerm_storage_container.static_content.name
  type                   = "Block"
  source                 = "resume/script.js"
}

resource "azurerm_storage_blob" "image1" {
  name                   = "image1.jpg"
  storage_account_name   = azurerm_storage_account.portfolioStorage.name
  storage_container_name = azurerm_storage_container.static_content.name
  type                   = "Block"
  source                 = "resume/image1.jpg"
}

resource "azurerm_storage_blob" "resume_pdf" {
  name                   = "resume.pdf"
  storage_account_name   = azurerm_storage_account.portfolioStorage.name
  storage_container_name = azurerm_storage_container.static_content.name
  type                   = "Block"
  source                 = "resume/assets/resume.pdf"
}

# App Service Plan for Function App
resource "azurerm_service_plan" "portfolio_plan" {
  name                = "portfolio-service-plan"
  location            = azurerm_resource_group.dynamicportfolio.location
  resource_group_name = azurerm_resource_group.dynamicportfolio.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = "resumefunctionstore"
  resource_group_name      = azurerm_resource_group.dynamicportfolio.name
  location                 = azurerm_resource_group.dynamicportfolio.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Function App for Feedback Handling
resource "azurerm_linux_function_app" "portfolio_function_app" {
  name                       = "portfoliofuncapp"
  location                   = azurerm_resource_group.dynamicportfolio.location
  resource_group_name        = azurerm_resource_group.dynamicportfolio.name
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.portfolio_plan.id
  site_config {}
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "portfolio_cosmosdb" {
  name                = "portfoliocdb" # Must be globally unique, lowercase letters, numbers, and hyphens only
  location            = azurerm_resource_group.dynamicportfolio.location
  resource_group_name = azurerm_resource_group.dynamicportfolio.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.dynamicportfolio.location
    failover_priority = 0
  }
}

# Cosmos DB Mongo Database
resource "azurerm_cosmosdb_mongo_database" "resume_db" {
  name                = "feedback-db"
  resource_group_name = azurerm_resource_group.dynamicportfolio.name
  account_name        = azurerm_cosmosdb_account.portfolio_cosmosdb.name
  throughput          = 400
}

# Cosmos DB Mongo Collection
resource "azurerm_cosmosdb_mongo_collection" "resume_container" {
  name                = "feedback-container"
  resource_group_name = azurerm_resource_group.dynamicportfolio.name
  account_name        = azurerm_cosmosdb_account.portfolio_cosmosdb.name
  database_name       = azurerm_cosmosdb_mongo_database.resume_db.name
  shard_key           = "id" # Ensure this matches your document structure
}

# CDN for Static Content Delivery (Optional)
# resource "azurerm_cdn_profile" "cdn_profile" {
#     name                = "portfolio-cdn-profile" # Must be globally unique
#     location            = "Central India" # Use the same region as your resources.
#     resource_group_name = azurerm_resource_group.dynamicportfolio.name
#     sku                 = "Standard_Verizon"
# }