#!/usr/bin/env ruby

require 'dotenv'
require 'azure_mgmt_media_services'
require 'azure_mgmt_resources'
require 'azure_mgmt_storage'

Dotenv.load(File.join(__dir__, './.env'))

REGION = 'East US'
RESOURCE_GROUP_NAME = 'MediaServicesSample'
STORAGE_ACC_NAME = 'storageaccount987'
MEDIA_SERVICE_NAME = 'mediaservice987'

# This script expects that the following environment vars are set:
#
# AZURE_TENANT_ID: with your Azure Active Directory tenant id or domain
# AZURE_CLIENT_ID: with your Azure Active Directory Application Client ID
# AZURE_CLIENT_SECRET: with your Azure Active Directory Application Secret
# AZURE_SUBSCRIPTION_ID: with your Azure Subscription Id
#
def run_example
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

  #
  # Register subscription for 'Microsoft.Media' namespace
  #
  provider = resource_client.providers.register('Microsoft.Media')
  puts "#{provider.namespace} #{provider.registration_state}"

  #
  # Create a resource group
  #
  create_resource_group(resource_client)

  #
  # Create a storage account
  #
  puts 'Create a Storage Account'
  param = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new.tap do |acc|
    acc.sku = Azure::ARM::Storage::Models::Sku.new.tap do |sku|
      sku.name = Azure::ARM::Storage::Models::SkuName::StandardLRS
      sku.tier = Azure::ARM::Storage::Models::SkuTier::Standard
    end
    acc.kind = Azure::ARM::Storage::Models::Kind::Storage
    acc.location = REGION
  end
  storage_account = storage_client.storage_accounts.create(RESOURCE_GROUP_NAME, STORAGE_ACC_NAME, param)
  print_item(storage_account)

  #
  # Create a Media Service
  #
  puts 'Create a Media Service'
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
  print_item(media_service)

  #
  # list media services by resource group
  #
  puts 'List Media Services by resource group'
  media_service_collection = media_services_client.media_service_operations.list_by_resource_group(RESOURCE_GROUP_NAME)
  media_service_collection.value.each do |media_service|
    print_item(media_service)
  end

  #
  # delete a media service
  #
  puts 'Delete a Media service'
  puts 'Press any key to continue...'
  gets
  media_services_client.media_service_operations.delete(RESOURCE_GROUP_NAME, MEDIA_SERVICE_NAME)

  #
  # delete resource group
  #
  puts 'Media service has been deleted. Now delete resource group'
  puts 'Press any key to continue...'
  gets
  delete_resource_group(resource_client)
end

def create_resource_group(resource_client)
  puts 'Create a resource group'
  resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = REGION
  end

  resource_group = resource_client.resource_groups.create_or_update(RESOURCE_GROUP_NAME, resource_group_params)
  print_item resource_group
end

def delete_resource_group(resource_client)
  puts 'Delete a resource group'
  resource_client.resource_groups.delete(RESOURCE_GROUP_NAME)
end

def print_item(item)
  puts "\tName: #{item.name}"
  puts "\tId: #{item.id}"
  puts "\tLocation: #{item.location}"
  puts "\tTags: #{item.tags}"
  print_properties(item.properties) if item.respond_to?(:properties)
end

def print_properties(props)
  if props.respond_to? :provisioning_state
    puts "\tProperties:"
    puts "\t\tProvisioning State: #{props.provisioning_state}"
  end
end

if $0 == __FILE__
  run_example
end
