# Import JSON Config
$config = Get-Content -Path .config.json  ConvertFrom-Json

# Function to get all certificates from LocalMachine
function Get-LocalMachineCertificates {
    param(
        [string]$ComputerName
    )
    try {
        # Query all certificates from the LocalMachine store
        $certs = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-ChildItem -Path CertLocalMachine -Recurse  ForEach-Object {
                [PSCustomObject]@{
                    Thumbprint   = $_.Thumbprint
                    Subject      = $_.Subject
                    Issuer       = $_.Issuer
                    ExpiryDate   = $_.NotAfter
                    StartDate    = $_.NotBefore
                    FriendlyName = $_.FriendlyName
                }
            }
        }
        return $certs
    }
    catch {
        Write-Warning Failed to retrieve certificates from $ComputerName $_
        return $null
    }
}

# Function to check if the certificate exists and get properties
function Check-ServerCertificate {
    param(
        [string]$ComputerName,
        [array]$Thumbprints
    )

    # Get the certificates from the server
    $certs = Get-LocalMachineCertificates -ComputerName $ComputerName
    if ($null -eq $certs) {
        Write-Warning No certificates found on $ComputerName.
        return
    }

    # Loop through each thumbprint in the config
    foreach ($thumbprint in $Thumbprints) {
        $foundCert = $certs  Where-Object { $_.Thumbprint -eq $thumbprint }
        if ($foundCert) {
            Write-Host Certificate with Thumbprint $thumbprint found on $ComputerName
            Write-Host Subject $($foundCert.Subject)
            Write-Host Issuer $($foundCert.Issuer)
            Write-Host Start Date $($foundCert.StartDate)
            Write-Host Expiry Date $($foundCert.ExpiryDate)
            Write-Host Friendly Name $($foundCert.FriendlyName)
        } else {
            Write-Warning Certificate with Thumbprint $thumbprint not found on $ComputerName.
        }
    }
}

# Main script execution
foreach ($server in $config.Servers) {
    $computerName = $server.ComputerName
    $thumbprints = $server.Thumbprints

    Write-Host Checking certificates for $computerName...
    Check-ServerCertificate -ComputerName $computerName -Thumbprints $thumbprints
}