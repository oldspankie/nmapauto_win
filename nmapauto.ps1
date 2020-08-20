#.\nmapauto.ps1 <target-ip> <type>
#Based (heavily) on 21y4d's
#https://github.com/21y4d/nmapAutomator.git

param (
    [string]$IP,
    [string]$scanType
)

$global:nmapcmd = "nmap";
$global:scanQuiet = $false;
$global:pingttl = "0";
$global:basicPorts = "";
$global:allPorts = "";

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
        $osType = checkOS;
        write-host "Host is likely running" -ForegroundColor Green
        write-host $osType -ForegroundColor Magenta #placeholder
    }
    write-host "`n`n";
}

function checkPing
{
    $pingTest = Test-Connection -ComputerName $IP -count 3 -quiet;
    if (!$pingTest)
    {
        $global:nmapcmd = "nmap -Pn";
        return $true;
    }
    else
    {
        $global:pingttl = test-connection -ComputerName $IP -count 1 -Quiet | select responsetimetolive;
        $global:nmapcmd = "nmap";
        return $false
    }
}

function checkOS()
{
    if ($pingttl -eq "256" -or $pingttl -eq "255" -or $pingttl -eq "254")
    {
        return "OpenBSD/Cisco/Oracle";
    }
    elseif ($pingttl -eq "128" -or $pingttl -eq "127")
    {
        return "Windows";
    }
    elseif ($pingttl -eq "64" -or $pingttl -eq "63")
    {
        return "Linux";
    }
    else
    {
        return "Unknown OS!"
    }
}

function assignPorts()
{
    #basicPorts
    if (test-path -path "nmap/quick_$IP.nmap")
    {
        $global:basicPorts = ""; #re-init ports var
        #basicPorts=$(cat nmap/Quick_"$1".nmap | grep open | cut -d " " -f 1 | cut -d "/" -f 1 | tr "\n" "," | cut -c3- | head -c-2)
        #$basicPorts = (get-content "nmap/quick_$IP.nmap") | select-string "open" | $_.split(" ")[1] | $_.split("/")[1] | $_ -replace "\n" "," | select -first 1
        $basicPorts = (get-content "nmap/quick_$IP.nmap") | select-string "open";
        $global:basicPorts = cleanPorts($basicPorts);
    }
    else
    {
        #scan all ports
        $global:basicPorts = "-";
    }

    #allPorts
    if (test-path -path "nmap/full_$IP.nmap")
    {
        if (test-path -path "nmap/quick_$IP.nmap")
        {
            $allPorts = (get-content "nmap/quick_$IP.nmap") | select-string "open";
            $allPorts += (get-content "nmap/full_$IP.nmap") | select-string "open"; #need to clean/remove dupes
            $global:allPorts = cleanPorts($allPorts);
        }
        else
        {
            $allPorts = (get-content "nmap/full_$IP.nmap") | select-string "open";
            $global:allPorts = cleanPorts($allPorts);
        }
    }
}

function cleanPorts($_input)
{
    $_output = "";
    #only pull the ports, skipping the first line
    for ($i=0; $i -le $_input.Length; $i++)
    {
        if ($i -ne 0)
        {
            $ba = $_input[$i] -split ("/");
            $_output += $ba[0] + ",";
        }
    }
    while ($_output -match '\,$')
    {
        $_output = $_output -replace ".$" #clean trailing ,'s
    }
    return $_output;
}

function quickScan()
{
    write-host "----------Starting Nmap Quick Scan----------" -ForegroundColor Green;
    $scancmd = $nmapcmd + " -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit --open -v -oN nmap/Quick_"+$IP+".nmap "+$IP;
    #$scan = " -T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit --open -v -oN nmap/Quick_"+$IP+".nmap "+$IP;
    
    & cmd /c $scancmd
    #Start-Process $nmaptype "-T4 --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit --open -oN nmap/Quick_$IP.nmap $IP"
    #Start-Process -filepath $nmaptype -argumentlist $scan -wait
    write-host "`n`n`n";
}

function basicScan()
{
    write-host "----------Starting Nmap Basic Scan----------" -ForegroundColor Green;

    #Check for QuickScan is handled under 'assignPorts'
    assignPorts($IP);
    
    $scancmd = $nmapcmd + " -sCV -p" + $global:basicPorts + " -oN nmap/Basic_" + $IP + ".nmap " + $IP;
    & cmd /c $scancmd;

    #osType/serviceOS modification goes here

    write-host "`n`n`n";
}

function fullScan()
{
    write-host "----------Starting Nmap Basic Scan----------" -ForegroundColor Green;

    $scancmd = $nmapcmd + " -p- --max-retries 1 --max-rate 500 --max-scan-delay 20 -T4 -v -oN nmap/Full_" + $IP + ".nmap " + $IP;
    & cmd /c $scancmd;
    #assignPorts($IP);

    #check and scan for extra ports
}

function vulnsScan()
{
    $portType = 'basic';
    $ports = "";
    assignPorts($IP);
    if ($global:allPorts -eq "")
    {
        $portType = 'basic';
        $ports = $global:basicPorts;
    }
    else
    {
        $portType = 'all';
        $ports = $global:allPorts;
    }

    #test path to check for vulners.nse
    #C:\Program Files (x86)\Nmap\scripts\vulners.nse
    $ErrorActionPreference = 'SilentlyContinue';
    if (test-path -path "nmap/quick_$IP.nmap")
    {
        write-host "Running CVE scan on $portType ports`n" -ForegroundColor Yellow;
        $scancmd = $nmapcmd + " -sV --script vulners --script-args mincvss=7.0 -p" + $ports + " -oN nmap/CVEs_" + $IP + ".nmap " + $IP;
        & cmd /c $scancmd;
        
    }
    else
    {
        write-host "Please install 'vulners.nse' nmap script." -ForegroundColor Red;
        write-host "ttps://github.com/vulnersCom/nmap-vulners" -ForegroundColor Red;
        write-host "" -ForegroundColor Red;
        write-host "Skipping CVE scan!`n" -ForegroundColor Red;
    }
    write-host "Running Vuln scan on $portType ports`n" -ForegroundColor Yellow;
    $scancmd = $nmapcmd + " -sV --script vuln -p" + $ports + " -oN nmap/Vulns_" + $IP + ".nmap " + $IP;
    & cmd /c $scancmd;
    write-host "`n`n`n" -ForegroundColor Yellow;
}


function footer()
{
    write-host "----------Finished all Nmap scans----------" -ForegroundColor Green;

    set-location -path .. #need to double check what this is about, if not just to reset path

    #time tracking portion here


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
    Set-Location -path $IP;
    new-item -path "nmap" -itemtype directory -force | out-null;

    #assignPorts($IP);

    header;

    switch ($scanType)
    {
        "quick" { quickScan; }
        "basic" { basicScan; }
        "full" { fullScan; }
        "vulns" { vulnsScan; }
    }

    footer;
}
else
{
    usage;
}
