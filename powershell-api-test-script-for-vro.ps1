###########################################################################################
# Create a vCenter Datacenter using REST API - Veeam Recovery Orchestrator Script Test
#
# Created by: Ricardo Conzatti (ricardo.conzatti@veeam.com)
# Created: 30/09/2025
# Version: 0.1
###########################################################################################
###########################################################################################
# Variables
Param( # vro variables
    [Parameter(Mandatory=$false)]
    [String]$vCenter,
    [string]$vCenterCredUsername,
    [string]$vCenterCredPassword
)
$vCenterDcName = "DC-VRO-TEST" # local variable
###########################################################################################
###########################################################################################

# write info
Write-Host "### VCENTER INFO ###`n - FQDN: $vCenter`n - Username: $vCenterCredUsername`n - New datacenter name: $vCenterDcName"

# set header with basic auth
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${vCenterCredUsername}:${vCenterCredPassword}"))
$headers = @{
	Authorization = "Basic $base64AuthInfo"
}

# ignore ssl errors (lab only!!!)
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# get vCenter token
$token = Invoke-RestMethod -Method Post -Uri "$vCenter/api/session" -Headers $headers

# set new headers
$headers = @{
	"vmware-api-session-id" = $token
}

# get datacenter folder
$folderDc = Invoke-RestMethod -Method Get -Uri "$vCenter/api/vcenter/folder/?type=DATACENTER" -Headers $headers

# set body
$body = @{
    name = $vCenterDcName
    folder = $folderDc.folder
} | ConvertTo-Json -Compress

# log body var
Write-host "### Logging 'body' variable... " $body

# log info
Write-Host "### Creating new datacenter: $vCenterDcName"

# create new datacenter
Invoke-RestMethod -Method Post -Uri "$vCenter/api/vcenter/datacenter" -Headers $headers -ContentType "application/json" -Body $body

# log info
Write-Host "### New datacenter successfully created"
