Project 2: IOCatcher

### ● Tool Name
IOCatcher (iocatcher.py)

### ● Objective
Automatically extract, normalize, and defang Indicators of Compromise (IoCs) from raw text files, incident response reports, and log outputs.

### ● Features
-Multi-Artifact Extraction: Automatically extracts IPv4 addresses, domain names, URLs, email addresses, and hashes (MD5, SHA1, SHA256).

-Automated Deduplication: Removes duplicate indicators across all categories.

-Private IP Filtering: Automatically filters out internal/private IPv4 ranges (RFC1918, loopback, reserved) to focus strictly on public threat actors.

-Defang Mode (--defang): Sanitizes URLs and domain names (http:// -> hXXp://, . -> [.]) for safe sharing.

-Flexible Export: Supports plain text (.txt) and structured (.json) report generation.

-Zero Third-Party Dependencies: Built entirely with Python standard libraries.

### ● Requirements
-Python: Version 3.8 or higher.

-Libraries: None (uses standard modules re, sys, json, ipaddress, os).

### ● How to Run
    Bash
python3 IOCatcher/iocatcher.py <path_to_file> [options]

Available flags:

--defang: Sanitize URLs and domains before export.

--json: Save extracted IoCs in JSON format instead of plain text.

We can also generate n lines (200 here) of logs from our Os and write them in a file with the following command:

Bash
sudo journalctl -n 200 > system_local.log

Then run:
Bash
python3 iocatcher.py --defang --json 

### ● Example Usage
    Bash
# Standard extraction
python3 IOCatcher/iocatcher.py samples/ioc_test.txt

# Extract with defanged indicators saved in JSON format
python3 IOCatcher/iocatcher.py samples/ioc_test.txt --defang --json

### ● Example Output
================ SUMMARY IOC EXTRACTED ================
[IP] trouves : 2
[EMAIL] trouves : 11
[URL] trouves : 14
[DOMAIN] trouves : 36
[HASH] trouves : 29

Resultats sauvegardes dans 'iocs_extracted.txt'

### ● Challenges Faced
-Regex Fine-Tuning: Preventing false positives when distinguishing raw domain names from file extensions or IPv4 octets.

-Clean Dependency-Free Filtering: Implementing accurate RFC1918 private IP validation without relying on third-party libraries like netaddr.

### ● Future Improvements
-Threat Intelligence API integration (VirusTotal / AbuseIPDB lookup).

-Direct export support to CTI platforms (TheHive, MISP).

-Native PDF, PCAP, and email header (.eml) parsing.

-Support for IPv6 address extraction and validation.