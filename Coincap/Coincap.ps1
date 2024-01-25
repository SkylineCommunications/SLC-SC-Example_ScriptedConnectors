param (
    [string]$identifier = "coincap.io PS",
    [string]$type = "Crypto Assets PS"
)

$header_params = @{
    "identifier" = $identifier
    "type" = $type
}

if ($args.Count -ge 2) {
    $identifier = $args[0]
    $type = $args[1]
    $header_params = @{
        "identifier" = $identifier
        "type" = $type
    }
}

Write-Host $header_params

# Make the GET request to coincap.io
$coincapResponse = Invoke-RestMethod -Uri "https://api.coincap.io/v2/assets" -Method Get

# Set additional headers
$headers = @{
    "Content-Type" = "application/json"
    "accept" = "application/json"
}
$headers += $header_params

$body = $coincapResponse | ConvertTo-Json

# Send the PUT request with the JSON response from the GET request
$uri = "http://localhost:34567/api/data/parameters"
$response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
echo $response | ConvertTo-Json
