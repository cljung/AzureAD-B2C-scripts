# AzureAD-B2C-scripts

This github repo contains a set of powershell script that help you to quickly setup an Azure AD B2C tenant and Custom Policies. If you are to set up a B2C tenant, you need to follow the guide on how to [Create an Azure Active Directory B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant). This leaves you with a basic tenant, but in order to install the Custom Policies, described in the documentation page [Get started with custom policies in Azure Active Directory B2C](https://docs.microsoft.com/en-us/azure/active-directory-b2c/custom-policy-get-started?tabs=applications#custom-policy-starter-pack), there are quite a few steps to complete. Although it is not complicated, it takes some time and involves som copy-n-pase, flickering between documentation pages, before you can test your first login. The powershell scripts in this repo are created with the aim of minimizing the time from setting up a B2C tenant to your first login.

## Update
The scripts have been updated to support running on Mac/Linux. In order to run them on MacOS, you need to install both Azure CLI and Powershell Core, then start the powershell command prompt with the pwsh command.

Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos) on MacOS.

Install [Powershell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-7) on MacOS.

# Setting up a new B2C tenant

With the scripts in this repository, you can create a fully functional B2C Custom Policy environment in seconds via the commands 

## Prerequisites

As mentioned, you need to [create your B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant) which involves creating the resource in [portal.azure.com](https://portal.azure.com)

![Create B2C Tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/media/tutorial-create-tenant/portal-02-create-tenant.png)

After creating the tenant, you need to link it to your Azure Subscription

![Linking the B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/media/tutorial-create-tenant/portal-05-link-subscription.png)

## Starting from scratch

1. Open a powershell command prompt and git clone this repo

```Powershell
git clone https://github.com/cljung/AzureAD-B2C-scripts.git
cd AzureAD-B2C-scripts
import-module .\AzureADB2C-Scripts.psm1
```

2. Connect to you B2C tenant

```Powershell
$Tenant = "yourtenant.onmicrosoft.com"  # replace 'yourtenant' with your tenant name
$TenantID  = (Invoke-RestMethod -Uri "https://login.windows.net/$Tenant/v2.0/.well-known/openid-configuration").authorization_endpoint.Split("/")[3]

Connect-AzureAD -TenantId $TenantID
```

3. Create a App Registration that can be used for authenticating via Client Credentials

```Powershell
.\aadb2c-create-graph-app.ps1 -n "B2C-Graph-App"
```
Copy-n-paste the json output for "ClientCredentials" and update the b2cAppSettings.json file. Update the tenant name in b2cAppSettings.json too.

4. Find the ***B2C-Graph-App*** in [https://portal.azure.com/yourtenant.onmicrosoft.com](https://portal.azure.com/yourtenant.onmicrosoft.com) and grant admin consent under API permissions

![Permissions to Grant](media/01-permissions-to-grant.png)

5. Create Custom Policy Keys

In the [create your B2C tenant](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant) documentation, it describes that you need to create your token encryption and signing keys. This isn't the most tedious job and doing it by hand is quite fast, but if you want to automate it, the following two lines will do it for you. 

```Powershell
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_TokenSigningKeyContainer" -KeyType "RSA" -KeyUse "sig"
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_TokenEncryptionKeyContainer" -KeyType "RSA" -KeyUse "enc"
```

6. Create the Custom Policy apps IdentityExperienceFramework and ProxyIdentityExperienceFramework

```Powershell
New-AzureADB2CIdentityExperienceFrameworkApps
```

7. Create an App Registration for a test webapp that accepts https://jwt.ms as redirectUri

To test the Custom Policy you need to register a dummy webapp in the portal that you can use. This is described in the tutorial for how to register an app and can be found here under section [Register a web application](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-preview#register-a-web-application).

```Powershell
New-AzureADB2CTestApp -n "Test-WebApp"
```

8. Create Facebook secret

Even though you might not use social login via Facebook, quite alot in the Custom Policies from the Starter Pack requires the key to be there for the policies to upload without error, so create a dummy key for now.

```powershell
New-AzureADB2CPolicyKey -KeyContainerName "B2C_1A_FacebookSecret" -KeyType "secret" -KeyUse "sig" -Secret "abc123"
``` 

 
# Creating a new Custom Policy project

Once you have your B2C tenant setup, it is time to create some Custom Policies. Using these Powershell modules, you will have your first Custom Policies ready to test in under 5 minutes.
 
## Start a powershell session for you B2C tenant

Open a new Powershell command prompt and load the modules.

```Powershell
cd AzureAD-B2C-scripts
import-module .\AzureADB2C-Scripts.psm1
```

Then, run the cmdlet ***Connect-AzureADB2CEnv***. This cmdlet either accepts a tenant name or the path to your b2cAppSettings.json file. If you run it with the ***-t "yourtenant"*** switch, you then need to run ***Read-AzureADB2CConfig*** at some later stage to load the settings you have in your b2cAppSettings.json file.

```Powershell
Connect-AzureADB2CEnv -ConfigPath .\b2cAppsettings.json
# or
Connect-AzureADB2CEnv -t "yourtenant"
```

## Download the Custom Policy Starter Pack and modify them to your tenant

```Powershell
md demo; cd demo
Get-AzureADB2CStarterPack               # get the starter pack from github
Set-AzureADB2CPolicyDetails -x "demo"   # set the tenant details and give the policies the "demo" prefix
Set-AzureADB2CCustomAttributeApp        # set the custom attribute app to 'b2c-extensions'
Set-AzureADB2CCustomizeUX               # set UX version to ver 1.2 to enable javascript
```

The output will look something like this

```powershell
PS C:\Users\cljung\src\b2c\scripts\demo> Get-AzureADB2CStarterPack                                                   Downloading https://raw.githubusercontent.com/Azure-Samples/active-directory-b2c-custom-policy-starterpack/master/SocialAndLocalAccounts/TrustFrameworkBase.xml to C:\Users\cljung\src\b2c\scripts\demo/TrustFrameworkBase.xml
Downloading https://raw.githubusercontent.com/Azure-Samples/active-directory-b2c-custom-policy-starterpack/master/SocialAndLocalAccounts/TrustFrameworkExtensions.xml to C:\Users\cljung\src\b2c\scripts\demo/TrustFrameworkExtensions.xml
Downloading https://raw.githubusercontent.com/Azure-Samples/active-directory-b2c-custom-policy-starterpack/master/SocialAndLocalAccounts/SignUpOrSignin.xml to C:\Users\cljung\src\b2c\scripts\demo/SignUpOrSignin.xml
Downloading https://raw.githubusercontent.com/Azure-Samples/active-directory-b2c-custom-policy-starterpack/master/SocialAndLocalAccounts/PasswordReset.xml to C:\Users\cljung\src\b2c\scripts\demo/PasswordReset.xml
Downloading https://raw.githubusercontent.com/Azure-Samples/active-directory-b2c-custom-policy-starterpack/master/SocialAndLocalAccounts/ProfileEdit.xml to C:\Users\cljung\src\b2c\scripts\demo/ProfileEdit.xml
PS C:\Users\cljung\src\b2c\scripts\scratch> Set-AzureADB2CPolicyDetails -x "demo"                                       Tenant:         cljungscratchb2c.onmicrosoft.com
TenantID:       a81...48a
Getting AppID's for IdentityExperienceFramework / ProxyIdentityExperienceFramework
Getting AppID's for b2c-extensions-app
dff...a58
Modifying Policy file PasswordReset.xml...
Modifying Policy file ProfileEdit.xml...
Modifying Policy file SignUpOrSignin.xml...
Modifying Policy file TrustFrameworkBase.xml...
Modifying Policy file TrustFrameworkExtensions.xml...
Facebook
Local Account SignIn
PS C:\Users\cljung\src\b2c\scripts\demo> Set-AzureADB2CCustomAttributeApp                                            Using b2c-extensions-app
Adding TechnicalProfileId AAD-Common
PS C:\Users\cljung\src\b2c\scripts\demo> Set-AzureADB2CCustomizeUX
```

## Upload the Custom Policies to your tenant

```Powershell
Push-AzureADB2CPolicyToTenant           # upload the policies
```

The output will look something like this

```Powershell
PS C:\Users\cljung\src\b2c\scripts\demo> Push-AzureADB2CPolicyToTenant                                               Tenant:         cljungscratchb2c.onmicrosoft.com
TenantID:       a81...48a
Authenticating as App B2C-Graph-App, AppID 63f...71f
Uploading policy B2C_1A_demo_TrustFrameworkBase...
http://cljungscratchb2c.onmicrosoft.com/B2C_1A_demo_TrustFrameworkBase
Uploading policy B2C_1A_demo_TrustFrameworkExtensions...
http://cljungscratchb2c.onmicrosoft.com/B2C_1A_demo_TrustFrameworkExtensions
Uploading policy B2C_1A_demo_PasswordReset...
http://cljungscratchb2c.onmicrosoft.com/B2C_1A_demo_PasswordReset
Uploading policy B2C_1A_demo_ProfileEdit...
http://cljungscratchb2c.onmicrosoft.com/B2C_1A_demo_ProfileEdit
Uploading policy B2C_1A_demo_signup_signin...
http://cljungscratchb2c.onmicrosoft.com/B2C_1A_demo_signup_signin
```

## Testing the Custom Policies 

The cmdlet ***Test-AzureADB2CPolicy*** will read the Relying Party xml file, query the tenant for the App Registration and assemble a url to the authorization endpoint and then launch the browser to test the policy.
 
```Powershell
Test-AzureADB2CPolicy -n "Test-WebApp" -p .\SignUpOrSignin.xml
```

# b2cAppSettings.json file 

The config file [b2cAppSettings.json](b2cAppSettings.json) contains settings for your environment and also what features you would like in your Custom Policy. It contains the following elements

* top element - contains a few settings, like which B2C Starter Pack you want to use. The default is ***SocialAndLocalAccounts***

* ClientCredentials - the client credentials we are going to use when we do GraphAPI calls, like uploading the Custom POlicy xml files

* AzureStorageAccount - Azure Blob Storage account settings. You will need this if you opt-in to to UX customizaion as the html files will be stored in blob storage. 

* CustomAttributes - if you plan to use custom attributes, you need to specify which App Registration will handle the custom attributes in the policy. The default is the "b2c-extension-app"

* UxCustomization - If you enable this, the script will download the template html files from your B2C tenant into a subfolder called "html" and upload them to Azure Blob Storage. The policy file ***TrustFrameworkExtension.xml*** will be updated to point to your storage for the url's to the html

* ClaimsProviders - a list of claims provider you like to support. Note that for each you enable, you need to use the respective portal to configure your app and to copy-n-paste the client_id/secret into b2cAppSettings.json

If you just want to test drive the below step, enable the Facebook Claims Provider (Enable=true) and set the client_id + client_secret configuration values to something bogus, like 1234567890. Since Facebook is part of the Starter Pack to begin with, you need this to be enabled to be able to upload correctly. Later if you want to use Facebook, you can register a true app and change the key or you can remove the Facebook Claims Provider in the ***TrustFrameworkExtension.xml*** file.
