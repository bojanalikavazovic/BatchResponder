<h1 align="center">
<p style="text-align: center;"><img src="https://github.com/bojanalikavazovic/BatchResponder/assets/43232741/b93eb0b1-91cb-4a96-ae8c-107f7fd5092a" height=250px width=250px></p>
</h1>
<p align="center"><b>Super primitive way of working | Non invasive on the CPU | Great for OT environments | Works on new and old Windows environments</b><br><br>Version 1.0 (1/2024)</p>

## What is BatchResponder?
A simple Windows .bat script that can detect the presence of IOCs on a Windows operating system.<br>       
When the BatchResponder detects an IOC, the infected computer will send:
- a specific PING to the Incident Responder's IP address <br><i>(Just open Wireshark/Tshark/tcpdump and listen to incoming traffic from infected computers)</i>,
- a specific DNS query to your authoritative DNS server on the Internet <br><i>(or DNS server in the local network)</i>,
- and detection report to your FTP server (optional). 

## When to use BatchResponder?
It's great for cyber incidents, when you don't have the ability to execute Powershell scripts, VBS, or install EDR software for detection on all workstations and servers (security restrictions/low resources/OT networks/unconsolidated versions of windows in the affected environment). 

## What are the benefits of using BatchResponder?
- **Super primitive way of working, but it works!** :)
- **Non invasive on the CPU.**  
- **Great for OT environments.**  
- **Batch script that works on new and old Windows environments equally.**  
- Very quick setup and usage on cyber incidents.  
- No additional installation required.  
- Everything is in one file.  

## Which IOCs can BatchResponder check?  
| **IOC search**            | **Used Binary** | **Explanation**                                              |             
| --------------------------| --------------- | ------------------------------------------------------------ |
| File names                | **exists**      | Checks file names on specific paths on the computer.         |
| Network connections       | **netstat**     | Checks network connections and ports on the computer.        |
| DNS cache                 | **ipconfig**    | Checks the DNS cache on the computer.                        |
| Registry values           | **reg**         | Checks the entries in the Windows registry.                  |
| Process names             | **tasklist**    | Checks active processes on the computer.                     |
| Scheduled Tasks           | **schtasks**    | Checks scheduled tasks on the computer.                      |
| Installed Applications    | **wmic**        | Checks the installed applications on the computer.           |
| Services                  | **net**         | Checks the configured services on the computer.              |


## Verified on various Windows versions
Batch responder works on different versions of Windows, even older ones. This is important in OT environments.
|                         | exists   | netstat  | ipconfig | reg      | tasklist | schtasks | wmic     | net      |
| ----------------------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| Windows XP Pro x86 SP1  |    +     |    +     |    +     |    +     |    +     |    +     |    +     |    +     |
| Windows 7 Ultimate x64  |    +     |    +     |    +     |    +     |    +     |    +     |    +     |    +     |
| Windows 10 Pro x86      |    +     |    +     |    +     |    +     |    +     |    +     |    +     |    +     |
| Windows 10 Pro x64      |    +     |    +     |    +     |    +     |    +     |    +     |    +     |    +     |
| Windows 11 Pro x64      |    +     |    +     |    +     |    +     |    +     |    +     |    +     |    +     |
      
## How does the script work?
Distribute the script to the suspect computers and execute it. Listen to infected computers that will send you a specific PING, DNS Query, and detection reports to your FTP server (optional).    
 
## Setup and usage

### Step 1 - Prepare the BeaconCollector
BeaconCollector is an incident responder's computer that must be connected to the infected Enterprise network. It will listen for incoming ICMP (with TTL 30 or lower) traffic from infected computers, and collect detection reports via FTP protocol (optional).<br><br>

Look for this part of the code in the script and carefully adjust with your parameters:
```
set BeaconCollector=192.168.10.22
set TTL=30
set DNSCollector=subdomain.yourdomain.com
set ResultsFile=%temp%\%number%.BatchResponder_results_for_%COMPUTERNAME%.txt
set FTPCollector=%BeaconCollector%
set FTPProfile=%temp%\FTPProfile.txt
set FTPUsername=ftp
set FTPPassword=ftp
```

### Step 2 - Prepare BatchResponder with IOCs
Look for this part of the code in the script and carefully fill it with the indicators you want to check on the computers:
```
set "IOC_FILE_NM=%HOMEPATH%\Desktop\virus.exe %SYSTEMROOT%\System32\suspicious.dll" 
set IOC_NETWORK=":4444 123.123.123.123"
set IOC_DNS_REC="micros0ft.com yotube.com"
set IOC_PROCESS="scvhost.exe chr0me.exe"
set IOC_SC_TASK="StartScriptMalware"
set IOC_INS_APP="SuperMalware"
set IOC_SERVICE="SuperMalware"
:: For Windows Registry IOC definition look at the code block :REGISTRY in this script.
```

### Step 3 - Distribute and run BatchResponder
Distribute and execute the script via Group Policy in a Windows environment. Or, simply copy the prepared script to the suspicious computers and activate it with a double click.<br><br>
You will see an output (on the infected computer) similar to this.<br><br>
<img width="867" alt="cmd_1" src="https://github.com/bojanalikavazovic/BatchResponder/assets/43232741/f88ef644-0751-43d2-9bce-0553dc087037">


### Step 4 - Listen for "beacons" and collect outputs
**ICMP listening**<br>
Depending on the tool used, these are suggested filters for extracting ICMP "beacons" from network traffic:  
- ```tcpdump -i ens18 icmp and "ip[8]<=30"``` (The TTL byte is the 8th byte in the IP header)
- ```tshark -i eth0 -Y "icmp && ip.ttl<=30" -T fields -e ip.src -e ip.ttl```  
- Wireshark - Display filter: "icmp && ip.ttl<=30" (Without quotes)

**DNS listening**<br>
The infected computer will also send a specific DNS query. You can collect DNS queries from infected computers on the authoritative server for your domain or on the DNS server in the affected Enterprise network.<br>

Example Query<br>
```3842.50414E54484552.subdomain.yourdomain.com```
<br><br>
- ```3842``` - The random number is there to bypass the DNS cache on the DNS server or Proxy devices, so that every DNS Query goes outside the company to the Internet - even if you run the script several times on the same computer in a short time. A simple and stupid trick. :)<br>
- ```50414E54484552``` - The hexa-coded hostname of the infected computer.<br>
- ```subdomain.yourdomain.com``` - If you are the owner of a domain for which you can set up an authoritative server, every DNS Query will reach your server from the infected computer wherever you are on the Internet.<br>

## Roadmap 2/2024
- Implement user names check.
- Implement mutex check (using Sysinternals tool).
