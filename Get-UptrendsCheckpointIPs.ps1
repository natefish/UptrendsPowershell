#TODO Email Alert on Change
#TODO Detect changes in Checkpoints available

$fPath = "./NrthAmer_IPv4_Addresses.txt"
$bPath = "./NrthAmer_IPv4_Addresses.bak"

# URI to the API method you want to execute
$uri = "https://api.uptrends.com/v4/checkpoint" 

$userInfo = Get-Content -Path "./credentials.json" | ConvertFrom-Json

$nrthAmerChecks = @(
  "YLW","MTR","YOW","TOR","VAN","GDL","MEX","ALB","AMW","ASH","ATL","AUC","AUW","BND","BOS",
  "BUF","CLT","CHI","CLF","CMH","DAL","DTW","FAY","GRR","HNL","HOU","KAN","VEG","LAX","MNZ",
  "MIA","MSP","MKS","NYC","EWR","OKG","OMA","ORL","PHI","PHO","POR","RDD","SAC","SLC","SAT",
  "SAN","SFR","SAJ","SEA","STL","TAM","WAS"
)

# Compile the login info into credentials containing basic authentication
$secPass = ConvertTo-SecureString $userInfo.Password -AsPlainText -Force 
$cred = New-Object System.Management.Automation.PSCredential ($userInfo.UserName, $secPass) 
$head = @{
    Accept = "application/json"
}

# Execute the request
$resp = Invoke-RestMethod -Uri $uri -Method Get -Credential $cred -Headers $head -Verbose

$IPv4Ads = @()
foreach($r in $resp.data){
    if($r.Attributes.Code -iin $nrthAmerChecks){
        $IPv4Ads += $r.Attributes.Ipv4Addresses
    }
}

if(Test-Path $fPath){
    $tPath = "$fPath.tmp"
    $IPv4Ads | Out-File $tPath
    $hA = Get-FileHash $tPath
    $hB = Get-FileHash $fPath

    if($hA.Hash -eq $hB.Hash){
        Write-Host "No changes detected"
    }else{
        Write-Host "Something changed"
        
        $chngs = Compare-Object -ReferenceObject (Get-Content $fPath) -DifferenceObject (Get-Content $tPath) 

        foreach($c in $chngs){
            if($c.SideIndicator -eq "=>"){
                Write-Host "Added $($c.InputObject)"
            }else{
                Write-Host "Removed $($c.InputObject)"
            }
        }

        Move-Item $fPath $bPath -Force
        $IPv4Ads | Out-File $fPath
    }

    Remove-Item $tPath
}else{
    $IPv4Ads | Out-File $fPath
}
