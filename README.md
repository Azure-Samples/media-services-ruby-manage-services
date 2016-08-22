---
services: media-services
platforms: ruby
author: vishrutshah
---

# Manage Azure media services with Ruby

This sample demonstrates how to manage Azure media services using the Ruby SDK.

# Manage Azure resources and resource groups with Ruby

**On this page**

- [Run this sample](#run)
- [What is example.rb doing?](#example)
    - [Create a media service](#create)
    - [List media services](#list)
    - [Delete a media service](#delete)

<a id="run"></a>
## Run this sample

1. If you don't already have it, [install Ruby and the Ruby DevKit](https://www.ruby-lang.org/en/documentation/installation/).

1. If you don't have bundler, install it.

    ```
    gem install bundler
    ```

1. Clone the repository.

    ```
    git clone https://github.com/Azure-Samples/media-services-ruby-manage-services.git
    ```

1. Install the dependencies using bundle.

    ```
    cd media-services-ruby-manage-services
    bundle install
    ```

1. Create an Azure service principal either through
    [Azure CLI](https://azure.microsoft.com/documentation/articles/resource-group-authenticate-service-principal-cli/),
    [PowerShell](https://azure.microsoft.com/documentation/articles/resource-group-authenticate-service-principal/)
    or [the portal](https://azure.microsoft.com/documentation/articles/resource-group-create-service-principal-portal/).

1. Set the following environment variables using the information from the service principle that you created.

    ```
    export AZURE_TENANT_ID={your tenant id}
    export AZURE_CLIENT_ID={your client id}
    export AZURE_CLIENT_SECRET={your client secret}
    export AZURE_SUBSCRIPTION_ID={your subscription id}
    ```

    > [AZURE.NOTE] On Windows, use `set` instead of `export`.

1. Run the sample.

    ```
    bundle exec ruby example.rb
    ```

<a id="example"></a>
## What is example.rb doing?

The sample walks you through several media service management operations.
It starts by setting up `ResourceManagementClient`, `StorageManagementClient`, and `MediaServiceManagementClient` objects
using your subscription and credentials.

```ruby
#
# Create the Resource Manager Client with an Application (service principal) token provider
#
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
provider = MsRestAzure::ApplicationTokenProvider.new(
    ENV['AZURE_TENANT_ID'],
    ENV['AZURE_CLIENT_ID'],
    ENV['AZURE_CLIENT_SECRET'])
credentials = MsRest::TokenCredentials.new(provider)

# resource client
resource_client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
resource_client.subscription_id = subscription_id

# storage client
storage_client = Azure::ARM::Storage::StorageManagementClient.new(credentials)
storage_client.subscription_id = subscription_id

# media services client
media_services_client = Azure::ARM::MediaServices::MediaServicesManagementClient.new(credentials)
media_services_client.subscription_id = subscription_id
```

It registers the subscription for the "Microsoft.Media" namespace
and creates a resource group and a storage account where the media services will be managed.

```ruby
#
# Register subscription for 'Microsoft.Media' namespace
#
provider = resource_client.providers.register('Microsoft.Media')

#
# Create a resource group
#
resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = REGION
end

resource_group = resource_client.resource_groups.create_or_update(RESOURCE_GROUP_NAME, resource_group_params)

#
# Create a storage account
#
param = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new.tap do |acc|
    acc.sku = Azure::ARM::Storage::Models::Sku.new.tap do |sku|
        sku.name = Azure::ARM::Storage::Models::SkuName::StandardLRS
        sku.tier = Azure::ARM::Storage::Models::SkuTier::Standard
    end
    acc.kind = Azure::ARM::Storage::Models::Kind::Storage
    acc.location = REGION
end
storage_account = storage_client.storage_accounts.create(RESOURCE_GROUP_NAME, STORAGE_ACC_NAME, param)
```

There are a couple of supporting functions (`print_item` and `print_properties`) that print a resource group and it's properties.
With that set up, the sample lists all resource groups for your subscription, it performs these operations.

<a id="create"></a>
### 

```ruby
param = Azure::ARM::MediaServices::Models::MediaService.new
param.location = REGION
param.tags = {
    :tag1 => 'tag1'
}
storage_acc = Azure::ARM::MediaServices::Models::StorageAccount.new.tap do |acc|
    acc.id = storage_account.id
    acc.is_primary = true
end
param.storage_accounts = [storage_acc]

media_service = media_services_client.media_service_operations.create(RESOURCE_GROUP_NAME, MEDIA_SERVICE_NAME, param)
```

<a id="list"></a>
### 

```ruby
media_service_collection = media_services_client.media_service_operations.list_by_resource_group(RESOURCE_GROUP_NAME)
```

<a id="delete"></a>
### 

```ruby
media_services_client.media_service_operations.delete(RESOURCE_GROUP_NAME, MEDIA_SERVICE_NAME)
```
