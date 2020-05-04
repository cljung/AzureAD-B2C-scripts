param (
    [Parameter(Mandatory=$true)][Alias('n')][string]$DisplayName = "Test-WebApp"
    )

$tenant = Get-AzureADTenantDetail
$tenantName = $tenant.VerifiedDomains[0].Name

$requiredResourceAccess=@"
[
    {
        "resourceAppId": "00000003-0000-0000-c000-000000000000",
        "resourceAccess": [
            {
                "id": "37f7f235-527c-4136-accd-4a02d197296e",
                "type": "Scope"
            },
            {
                "id": "7427e0e9-2fba-42fe-b0c0-848c9e6a8182",
                "type": "Scope"
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

write-output "Creating application $DisplayName"
$app = New-AzureADApplication -DisplayName $DisplayName -IdentifierUris "http://$TenantName/$DisplayName" -ReplyUrls @("https://jwt.ms") -RequiredResourceAccess $reqAccess

write-output "Creating ServicePrincipal $DisplayName"
$sp = New-AzureADServicePrincipal -AccountEnabled $true -AppId $App.AppId -AppRoleAssignmentRequired $false -DisplayName $DisplayName 

& $PSScriptRoot\aadb2c-app-grant-permission.ps1 -n $DisplayName