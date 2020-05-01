param (
    [Parameter(Mandatory=$false)][Alias('n')][string]$DisplayName = "B2C-Graph-App"
    )

write-host "Getting Tenant info..."
$tenant = Get-AzureADTenantDetail
$tenantName = $tenant.VerifiedDomains[0].Name
write-host "$tenantName`n$($tenant.ObjectId)"

# 00000003 == MSGraph, 00000002 == AADGraph
$requiredResourceAccess=@"
[
    {
        "resourceAppId": "00000003-0000-0000-c000-000000000000",
        "resourceAccess": [
            {
                "id": "cefba324-1a70-4a6e-9c1d-fd670b7ae392",
                "type": "Scope"
            },
            {
                "id": "246dd0d5-5bd0-4def-940b-0421030a5b68",
                "type": "Role"
            },
            {
                "id": "79a677f7-b79d-40d0-a36a-3e6f8688dd7a",
                "type": "Role"
            },
            {
                "id": "fff194f1-7dce-4428-8301-1badb5518201",
                "type": "Role"
            },
            {
                "id": "4a771c9a-1cf2-4609-b88e-3d3e02d539cd",
                "type": "Role"
            }
        ]
    },
    {
        "resourceAppId": "00000002-0000-0000-c000-000000000000",
        "resourceAccess": [
            {
                "id": "311a71cc-e848-46a1-bdf8-97ff7156d8e6",
                "type": "Scope"
            },
            {
                "id": "5778995a-e1bf-45b8-affa-663a9f3f4d04",
                "type": "Role"
            },
            {
                "id": "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175",
                "type": "Role"
            }
                ]
    }
]
"@ | ConvertFrom-json

$reqAccess=@()
foreach( $resApp in $requiredResourceAccess ) {
    $req = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $req.ResourceAppId = $resApp.resourceAppId
    foreach( $ra in $resApp.resourceAccess ) {
        $req.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $ra.Id,$ra.type
    }
    $reqAccess += $req
}

write-host "`nCreating WebApp $DisplayName..."
$app = New-AzureADApplication -DisplayName $DisplayName -IdentifierUris "http://$TenantName/$DisplayName" -ReplyUrls @("https://$DisplayName") -RequiredResourceAccess $reqAccess
write-output "AppID`t`t$($app.AppId)`nObjectID:`t$($App.ObjectID)"

write-host "Creating ServicePrincipal..."
$sp = New-AzureADServicePrincipal -AccountEnabled $true -AppId $App.AppId -AppRoleAssignmentRequired $false -DisplayName $DisplayName 
write-host "AppID`t`t$($sp.AppId)`nObjectID:`t$($sp.ObjectID)"

write-output "Remeber to go to portal.azure.com for the app and Grant Permissions"