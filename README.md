# AzureAD-B2C-scripts

This github repo contains a set of powershell script that help you to quickly setup an Azure AD B2C tenant and Custom Policies. If you are to set up a B2C tenant, you need to follow the guide on how to [Create an Azure Active Directory B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant). This leaves you with a basic tenant, but in order to install the Custom Policies, described in the documentation page [Get started with custom policies in Azure Active Directory B2C](https://docs.microsoft.com/en-us/azure/active-directory-b2c/custom-policy-get-started?tabs=applications#custom-policy-starter-pack), there are quite a few steps to complete. Although it is not complicated, it takes some time and involves som copy-n-pase, flickering between documentation pages, before you can test your first login. The powershell scripts in this repo are created with the aim of minimizing the time from setting up a B2C tenant to your first login.

## Update
The scripts have been updated to support running on Mac/Linux. In order to run them on MacOS, you need to install both Azure CLI and Powershell Core, then start the powershell command prompt with the pwsh command.

Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos) on MacOS.

Install [Powershell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7) on MacOS.

## Summary

With the scripts in this repository, you can create a fully functional B2C Custom Policy environment in seconds via the commands 

Load the module
```Powershell
import-module .\AzureADB2C-Scripts.psm1
```

```Powershell
.\aadb2c-create-graph-app.ps1 -n "B2C-Graph-App"
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_TokenSigningKeyContainer" -KeyType "RSA" -KeyUse "sig"
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_TokenEncryptionKeyContainer" -KeyType "RSA" -KeyUse "enc"
New-AzureADB2CIdentityExperienceFrameworkApps
New-AzureADB2CTestApp -n "Test-WebApp"
md demo; cd demo
Get-AzureADB2CStarterPack
Set-AzureADB2CPolicyDetails -x "demo"
Push-AzureADB2CPolicyToTenant
Test-AzureADB2CPolicy -n "Test-WebApp" -p .\SignupOrSignin.xml
```

## Prerequisites

As mentioned, you need to [create your B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant) which involves creating the resource in [portal.azure.com](https://portal.azure.com)

![Create B2C Tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/media/tutorial-create-tenant/portal-02-create-tenant.png)

After creating the tenant, you need to link it to your Azure Subscription

![Linking the B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/media/tutorial-create-tenant/portal-05-link-subscription.png)

## Creating a powershell session to you B2C tenant

First, open a powershell command prompt and git clone this repo and change directory into it 
```Powershell
git clone https://github.com/cljung/AzureAD-B2C-scripts.git

cd AzureAD-B2C-scripts
```
Then, run the cmdlet ***Connect-AzureADB2CEnv***. The ***yourtenant*** does not need to include .onmicrosoft.com since the script will fix that for you. It is basically a wrapper around the Cmdlet ***Connect-AzAccount -t {guid}*** that connects you to your tenant. You need to run this using the same account as you created the B2C tenant with as it as the only user that has access to the tenant at start.

```Powershell
Connect-AzureADB2CEnv -t "yourtenant"
# or
Connect-AzureADB2CEnv -ConfigPath .\b2cAppsettings.json
```

## Create Client Credentials for scripting

Much of the scripting action done with your B2C tenant will require a quite powerfull App Registration with client_id and client_secret that you can use. The below script will register an App with the required permissions that you can use to deploy Custom Policies and Policy keys. The scripts outputs the ClientCredentials you need to copy-n-paste into your b2cAppSettings.json file. It also reminds you that you need to go into the portal and grant permission to the App.

```Powershell
.\aadb2c-create-graph-app.ps1 -n "B2C-Graph-App"
Getting Tenant info...
yourtenant.onmicrosoft.com
91b...78

Creating WebApp B2C-Graph-App...
AppID           4b7...10
ObjectID:       aa8...8e

Creating ServicePrincipal...
AppID           4b7...10
ObjectID:       9bd...fb

Creating App Key / Secret / client_secret - please remember this value and keep it safe
Copy-n-paste this to your b2cAppSettings.json file
"ClientCredentials": {
    "client_id": "aa8...8e",
    "client_secret": "ErX...nw="
}
setting ENVVAR B2CAppID=aa8..8e
setting ENVVAR B2CAppKey=ErX...nw=
Remeber to go to portal.azure.com for the app and Grant Permission
```

![Permissions to Grant](media/01-permissions-to-grant.png)

## Creating the Token Encryption and Signing Keys

The [create your B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant) then continues with that you need to create your token encryption and signing keys. This isn't the most tedious job and doing it by hand is quite fast, but if you want to automate it, the following two lines will do it for you. 

```Powershell
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_TokenSigningKeyContainer" -KeyType "RSA" -KeyUse "sig"
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_TokenEncryptionKeyContainer" -KeyType "RSA" -KeyUse "enc"
```

## Create the IdentityExperienceFramework and ProxyIdentityExperienceFramework apps

For B2C Custom Policies, there exists two special apps that helps the policy engine communicate with the tenant. The app IdentityExperienceFramework is registered as a webapp and ProxyIdentityExperienceFramework as a native client.
This is the second step after creating the keys and is explained in the docs under section [Register Identity Experience Framework applications](https://docs.microsoft.com/en-us/azure/active-directory-b2c/custom-policy-get-started?tabs=applications#register-identity-experience-framework-applications)

To automatically create the two apps, run the script [aadb2c-create-ief-apps.ps1](aadb2c-create-ief-apps.ps1). The script will automatically grant the permissions for the apps.

```Powershell
.\aadb2c-create-ief-apps.ps1
Getting Tenant info...
yourtenant.onmicrosoft.com

Creating WebApp IdentityExperienceFramework...
Creating ServicePrincipal...
AppID           0b8..95
ObjectID:       331..52

Creating NativeApp ProxyIdentityExperienceFramework...
Creating ServicePrincipal...
AppID           33c..ef
ObjectID:       5c8..c4

Granting Windows Azure Active Directory - User.Read  to IdentityExperienceFramework

@odata.context : https://graph.microsoft.com/beta/$metadata#oauth2PermissionGrants/$entity
clientId       : 331..52
consentType    : AllPrincipals
expiryTime     : 2022-05-04T09:49:29Z
id             : ytg..y0
principalId    :
resourceId     : 176..2d
scope          : User.Read
startTime      : 2020-05-04T09:49:29Z

Getting Tenant info...
Tenant:         yourtenant.onmicrosoft.com
Granting IdentityExperienceFramework - user_impersonation  to ProxyIdentityExperienceFramework
@odata.context : https://graph.microsoft.com/beta/$metadata#oauth2PermissionGrants/$entity
clientId       : 5c8..c4
consentType    : AllPrincipals
expiryTime     : 2022-05-04T09:49:31Z
id             : wiO..dk
principalId    :
resourceId     : 331..52
scope          : user_impersonation
startTime      : 2020-05-04T09:49:31Z

Granting Windows Azure Active Directory - user_impersonation User.Read  to ProxyIdentityExperienceFramework
@odata.context : https://graph.microsoft.com/beta/$metadata#oauth2PermissionGrants/$entity
clientId       : 5c8..c4
consentType    : AllPrincipals
expiryTime     : 2022-05-04T09:49:31Z
id             : wiO..y0
principalId    :
resourceId     : 176..2d
scope          : user_impersonation User.Read
startTime      : 2020-05-04T09:49:31Z
```

## Edit you b2cAppSettings.json file to configure what features you want

The config file [b2cAppSettings.json](b2cAppSettings.json) contains settings for your environment and also what features you would like in your Custom Policy. It contains the following elements

* top element - contains a few settings, like which B2C Starter Pack you want to use. The default is ***SocialAndLocalAccounts***

* ClientCredentials - the client credentials we are going to use when we do GraphAPI calls, like uploading the Custom POlicy xml files

* AzureStorageAccount - Azure Blob Storage account settings. You will need this if you opt-in to to UX customizaion as the html files will be stored in blob storage. 

* CustomAttributes - if you plan to use custom attributes, you need to specify which App Registration will handle the custom attributes in the policy. The default is the "b2c-extension-app"

* UxCustomization - If you enable this, the script will download the template html files from your B2C tenant into a subfolder called "html" and upload them to Azure Blob Storage. The policy file ***TrustFrameworkExtension.xml*** will be updated to point to your storage for the url's to the html

* ClaimsProviders - a list of claims provider you like to support. Note that for each you enable, you need to use the respective portal to configure your app and to copy-n-paste the client_id/secret into b2cAppSettings.json

If you just want to test drive the below step, enable the Facebook Claims Provider (Enable=true) and set the client_id + client_secret configuration values to something bogus, like 1234567890. Since Facebook is part of the Starter Pack to begin with, you need this to be enabled to be able to upload correctly. Later if you want to use Facebook, you can register a true app and change the key or you can remove the Facebook Claims Provider in the ***TrustFrameworkExtension.xml*** file.

## Automated deployment the of Custom Policy to your tenant

The script [aadb2c-create-new-policy-project.ps1](aadb2c-create-new-policy-project.ps1) loads the b2cAppSettings.json config file and then invokes the other scripts as needed. For instance, the first step is invoking [aadb2c-prep-starter-pack.ps1](aadb2c-prep-starter-pack.ps1) which downloads the starter pack files from github and modifies them so they reference your tenant. The policy ids are also changed so that the prefix name you use (default is the name of your folder - demo in my case) is added to your policy ids. B2C_1A_signup_signin becomes B2C_1A_demo_signup_signin, etc. This is quite handy since it stops you from overwriting each others policies during development.

When adding features to you configuration the file ***TrustFrameworkBase.xml*** is never changed, all work is done via editing ***TrustFrameworkExtensions.xml***. The script [aadb2c-add-claimsprovider.ps1](aadb2c-add-claimsprovider.ps1), which adds different Claims Providers, adds quite a lot of xml depending on how many providers you use. If you want UX Customization, the script [aadb2c-policy-ux-customize.ps1](aadb2c-policy-ux-customize.ps1) will copy the ContentDefinition elements from the Base file, modify them and insert them into the Extensions file. All is done as specified in the documentation, but the automated version means you have the policies ready in ~10 seconds rather than spending a hour editing the files. 

If you set the KeepPolicyIds switch to $True, the PolicyIds will be kept as-is, is B2C_1A_TrustFrameworkBase, B2C_1A_TrustFrameworkExtensions, etc.

```Powershell
md demo
Get-AzureADB2CStarterPack               # get the starter pack from github
Set-AzureADB2CPolicyDetails -x "demo"   # set the tenant details and give the policies the "demo" prefix
Set-AzureADB2CCustomAttributeApp        # set the custom attribute app to 'b2c-extensions'
Set-AzureADB2CCustomizeUX               # set UX version to ver 1.2 to enable javascript
Push-AzureADB2CPolicyToTenant           # upload the policies
```
The cmdlet ***Push-AzureADB2CPolicyToTenant*** , which is responsible for uploading the B2C Custom Policies, is smart enough to look through the inheritance chain between the different xml files and will upload them in the correct order, ie start with Base, continue with Extensions and then the rest.

## Test drive the Custom Policy

To test the Custom Policy you need to register a dummy webapp in the portal that you can use. This is described in the tutorial for how to register an app and can be found here under section [Register a web application](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-preview#register-a-web-application).

To automatically provision the app, run this command below. It will create a webapp that redirects to [https://jwt.ms](https://jwt.ms) so you can test the B2C policy.

```Powershell
New-AzureADB2CTestApp -n "Test-WebApp"
```

Then to test a policy using the newly created test app, run the command

```Powershell
Test-AzureADB2CPolicy -n "Test-WebApp" -p .\SignupOrSignin.xml
```

