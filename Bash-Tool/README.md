Project 1: LogHunter

### ● Tool Name
LogHunter (`loghunter.sh`)

### ● Objective
Analyze text-based log files to automatically detect suspicious activities, security anomalies, and performance errors, with dedicated modules for SSH authentication and Web server (Apache/Nginx) logs.

### ● Features
- **Auto-detection**: Automatically identifies log types (`ssh`, `web`, `general`) or accepts explicit options.
- **General Analysis**: Counts total lines, extracts first and last log entry timestamps, counts error/warning occurrences, and identifies top active IP addresses.
- **Auth/SSH Module**: Tracks failed authentication attempts, targets top targeted usernames, triggers brute-force alerts (> 5 failures per IP), and flags successful logins after failures.
- **Web Module**: Reports HTTP status code distributions, top requested URLs, and flags malicious signatures (SQL injection, directory traversal, automated vulnerability scanners).
- **Dual Output**: Displays a summary report directly on screen and saves a copy to a text file.
- **Robust Error Handling**: Safely handles missing, unreadable, or empty files.

### ● Requirements
- **OS**: Linux (Ubuntu, Debian, Kali, CentOS) or WSL.
- **Shell**: Bash.
- **Core Utilities**: Standard Unix tools (`grep`, `awk`, `sed`, `sort`, `uniq`, `head`, `tail`).
- **Permissions**: Read access to target log files (may require `sudo` for `/var/log/*`).

### ● How to Run
1. Grant execution permissions:
   ```bash
   chmod +x LogHunter/loghunter.sh
2. Execute the script with a log file path as an argument:
   ./LogHunter/loghunter.sh <path_to_log_file> [ssh|web|general]

   We can also generate a live authentication log file directly from the OS journal,with running this command in our terminal:
   Bash
sudo journalctl -u ssh > auth_local.log

Then run our script on it:
Bash
./loghunter.sh auth_local.log

### ● Example Usage
    bash
  # Auto-detect log type
  ./LogHunter/loghunter.sh samples/auth.log

  # Explicitly specify web log mode
  ./LogHunter/loghunter.sh samples/access.log web

### ● Example Output
==========================================
    RAPPORT LOGHUNTER - ANALYSE LOGS
==========================================
Fichier analyse : test_ssh.log
Nombre de lignes : 8
Premiere entree : Oct 8 10:00:01 server ssh
Derniere entree : Oct 8 10:01:00 server ssh
Type de log detecte : ssh

--- TOP 5 DES ADRESSES IP ---
      7 198.51.100.45
      1 192.168.1.50

--- ERREURS ET ALERTES ---
Total anomalies : 7

=== MODULE AUTH / SSH ===
Echecs de connexion (Failed password) : 7
Comptes utilisateurs les plus cibles :
      3 root
      3 invalid
      1 user

Suspicion de Brute Force (IPs avec > 5 echecs) :
IP: 198.51.100.45 - Echecs: 6

Connexions reussies apres echecs :
Oct 8 10:00:15 server sshd[1234]: Accepted password for root from 198.51.100.45 port 45224 ssh2

Analyse terminee. Rapport enregistre dans : rapport_test_ssh.log.txt

### ● Challenges Faced
-Log Format Variability: Parsing timestamps and fields reliably across disparate log formats (syslog vs. Apache Combined vs. custom Nginx formats) using a single shell script under 100 lines.

-Performance Constraints: Ensuring efficient text parsing (awk/grep) when processing high-volume log files without high memory usage.

### ● Future Improvements
-CSV and JSON export options for automated reporting pipeline integration.

-New modules for pfSense, DNS logs, and exported Windows Event logs.

-Live real-time log monitoring mode (tail -f parsing).

-Automated alerting integration via Email, Webhooks, or Telegram.