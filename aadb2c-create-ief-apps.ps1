param (
    [Parameter(Mandatory=$false)][Alias('n')][string]$DisplayName = "IdentityExperienceFramework"
    )

write-host "Getting Tenant info..."
$tenant = Get-AzureADTenantDetail
$tenantName = $tenant.VerifiedDomains[0].Name
write-host "$tenantName`n$($tenant.ObjectId)"

Function CreateRequiredResourceAccess([string]$ResourceAppId,[string]$ResourceAccessId, [string]$Type) {
    #write-host "Adding RequiredResourceAccess $ResourceAppId of type $Type..."
    $req = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $req.ResourceAppId = $ResourceAppId
    $req.ResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $ResourceAccessId,$Type
    return $req
}

Function CreateApplication( [string]$DisplayName, [string]$TenantName, [bool]$NativeApp, [System.Array]$RequiredResourceAccess) {    
    if ( $false -eq $NativeApp ) {
        write-host "`nCreating WebApp $DisplayName..."
        $app = New-AzureADApplication -DisplayName $DisplayName -IdentifierUris "http://$TenantName/$DisplayName" -ReplyUrls @("https://$DisplayName") # WebApp
    } else {
        write-host "`nCreating NativeApp $DisplayName..."
        $app = New-AzureADApplication -DisplayName $DisplayName -ReplyUrls @("https://$DisplayName") -PublicClient $true # NativeApp
    }
    write-output "AppID`t`t$($app.AppId)`nObjectID:`t$($App.ObjectID)"

    # update the required permissions
    if ( $null -ne $RequiredResourceAccess ) {
        Set-AzureADApplication -ObjectId $app.ObjectId -RequiredResourceAccess $RequiredResourceAccess
    }

    write-host "Creating ServicePrincipal..."
    $sp = New-AzureADServicePrincipal -AccountEnabled $true -AppId $App.AppId -AppRoleAssignmentRequired $false -DisplayName $DisplayName 
    write-host "AppID`t`t$($sp.AppId)`nObjectID:`t$($sp.ObjectID)"
    <#
    $App = Get-AzureADApplication -SearchString $displayName
    $sp = Get-AzureADServicePrincipal -SearchString $displayName
    #>
    return $app
}

$req1 = CreateRequiredResourceAccess -ResourceAppId "00000002-0000-0000-c000-000000000000" -ResourceAccessId "311a71cc-e848-46a1-bdf8-97ff7156d8e6" -Type "Scope"

$appIEF = CreateApplication -DisplayName $DisplayName -TenantName $tenantName -RequiredResourceAccess @($req1) -NativeApp $false

$req2 = CreateRequiredResourceAccess -ResourceAppId $appIEF.AppId -ResourceAccessId "784b6254-7ada-4028-88e4-71eed5676dde" -Type "Scope"

$appPIEF = CreateApplication -DisplayName "Proxy$DisplayName" -TenantName $tenantName -RequiredResourceAccess @($req1,$req2) -NativeApp $true

$appExt = Get-AzureADApplication -SearchString "b2c-extensions-app"
if ( $null -eq $appExt ) {
    write-host "VSCode extension for B2C isn't installed"
} else {
    write-host "`nb2c-extensions-app`nAppID`t`t$($appExt.AppId)`nObjectID:`t$($AppExt.ObjectID)"
}
