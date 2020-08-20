# nmapautomator - Windows
A PowerShell-take on nmapAutomator


# Summary
Based heavily on (or, I guess, translated from) 21y4d's nmapAutomator script
  - https://github.com/21y4d/nmapAutomator
While initially a skeleton of some of the functions, the goal is to at least have this as complete as what it is based from.
Somethings, understandably, have had to be rewritten.
While this may likely take on a life of it's own in the future, I cannot deny the inspiration.


# Features
1. *Quick:* Quickly shows all open ports
2. *Basic:* Runs a thorough scan on ports based on a Quick output, or runs thoroughly on all ports
3. *Full:* Scans all ports, thoroughly
4. *Vulns:* Runs CVE and nmap Vulns scan on found ports based on Quick or Full output


# Requirements:
nmap installed on the Windows PC.  The package with ZenMap should include the 'nmap Vulners' script.  Currently only checks for x86.

There will be more, once the script becomes more complete.


#Examples:
    .\nmapauto.ps1 <target> <scan>
    .\nmapauto.ps1 google.com quick
    .\nmapauto.ps1 8.8.8.8 vulns

Scan results will get dropped from the directory you run the script from.


#TODO
* Finish functions for all scans and data gathering
* Support subnet/range scan
* Implement recon scanning
