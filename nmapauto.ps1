#.\nmapauto.ps1 <target-ip> <type>


param (
    [string]$IP,
    [string]$scanType
)

$nmapcmd = "";
$scanQuiet = $false;

function usage()
{
    write-host "";
    write-host "Usage: .\nmapauto.ps1 <target-ip> <type>" -ForegroundColor Red;
    write-host "`tScan Type Defaults to All" -ForegroundColor Red;
    write-host "";
    write-host "Scan Types:" -ForegroundColor Yellow;
    write-host "`tQuick:`t Shows all open ports quickly (~15 seconds)" -ForegroundColor Yellow;
    write-host "`tBasic:`t Runs Quick Scan, then runs a more thorough scan on found ports (~5 minutes)" -ForegroundColor Yellow;
    write-host "`tUDP:`t Runs `"Basic`" on UDP ports (~5 minutes)" -ForegroundColor Yellow;
    write-host "`tFull:`t Runs a full range port scan, then runs a thorough scan on new ports (~5-10 minutes)" -ForegroundColor Yellow;
    write-host "`tVulns:`t Runs CVE scan and nmap Vulns scan on all found ports (~5-15 minutes)" -ForegroundColor Yellow;
    write-host "`tAll:`t Runs all the scans (~20-30 minutes)" -ForegroundColor Yellow;
    write-host ""
    break;
}


function header()
{
    if ($scanType -eq "All")
    {
        write-host "Running all scans on $IP" -ForegroundColor Yellow;
    }
    else
    {
        write-host "Running a $scanType scan on $IP" -ForegroundColor Yellow;
    }

    #Add Subnet

    $scanQuiet = checkPing;
    if ($scanQuiet -eq $true)
    {
        write-host "No ping detected... running with -Pn option" -ForegroundColor Yellow;
    }
    else
    {
        write-host "Host is likely running" -ForegroundColor Green
        write-host "Your Mother" -ForegroundColor Magenta #placeholder
    }
}

function checkPing
{
    $pingTest = Test-Connection -ComputerName $IP -count 3 -quiet;
    if (!$pingTest)
    {
        return $true;
    }
    else
    {
        return $false
    }
}

function checkOS()
{

}

function assignPort()
{
    if (test-path -path "nmap/quick_$IP.nmap")
    {
        #basicPorts=$(cat nmap/Quick_"$1".nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | cut -c3- | head -c-2)
        #$basicPorts = (get-content "nmap/quick_$IP.nmap" | select-string "open" | $_.split(" ")[1] | $_.split("/")[1] | $_ -replace "\n" "," | select -first 1
        #write-host $basicPorts;
    }
}


#usage;
#checkPing;
#header;
#write-host "EOF"; #testing break

if (!$IP -or !$scanType)
{
    usage;
}

if ($scanType)
{
    #make dirs
    new-item -path $IP -itemtype directory -force | out-null; #hide output
    cd /d $IP;
    new-item -path "nmap" -itemtype directory -force | out-null;

    #assignPorts($IP);

    header;

    switch ($scanType)
    {
        "quick" { write-host "Quickie"; }
        "basic" { write-host "Basic"; }
        "full" { write-host "Full"; }
        "vulns" { write-host "Vulns"; }
    }

    #footer;
}
else
{
    usage;
}
