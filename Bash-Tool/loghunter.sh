#!/bin/bash

# 1. Recuperation des arguments et collecte automatique si aucun fichier fourni
LOG_FILE="$1"
TYPE="${2:-auto}"

if [ -z "$LOG_FILE" ]; then
    echo "[+] Aucun fichier spécifié. Collecte automatique des logs du système..."
    if [ -f "/var/log/auth.log" ]; then
        LOG_FILE="/var/log/auth.log"
    elif [ -f "/var/log/secure" ]; then
        LOG_FILE="/var/log/secure"
    elif [ -f "/var/log/syslog" ]; then
        LOG_FILE="/var/log/syslog"
    elif [ -f "/var/log/messages" ]; then
        LOG_FILE="/var/log/messages"
    else
        echo "Erreur: Aucun log système trouvé dans /var/log/."
        exit 1
    fi
fi

# 2. Verification de l'existence et de l'etat du fichier
if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then echo "Erreur: Fichier introuvable ou vide."; exit 1; fi

# 3. Preparation du fichier de rapport d'analyse
REPORT_FILE="rapport_$(basename "$LOG_FILE").txt"
exec > >(tee "$REPORT_FILE") 2>&1

echo "=========================================="
echo "    RAPPORT LOGHUNTER - ANALYSE LOGS"
echo "=========================================="
echo "Fichier analyse : $LOG_FILE"
echo "Nombre de lignes : $(wc -l < "$LOG_FILE")"
echo "Premiere entree : $(head -n 1 "$LOG_FILE" | cut -c 1-25)"
echo "Derniere entree : $(tail -n 1 "$LOG_FILE" | cut -c 1-25)"

# 4. Auto-detection du type de log si non specifie
if [ "$TYPE" = "auto" ]; then
    if grep -qi "sshd" "$LOG_FILE"; then TYPE="ssh";
    elif grep -qiE "GET|POST|HTTP" "$LOG_FILE"; then TYPE="web";
    else TYPE="general"; fi
fi
echo "Type de log detecte : $TYPE"

# 5. Extraction du Top 5 des adresses IP les plus actives
echo -e "\n--- TOP 5 DES ADRESSES IP ---"
grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5

# 6. Comptage global des erreurs et avertissements
echo -e "\n--- ERREURS ET ALERTES ---"
echo "Total anomalies : $(grep -iE "error|failed|warning|alert|critical" "$LOG_FILE" | wc -l)"

# 7. Module d'analyse specifique aux logs SSH
if [ "$TYPE" = "ssh" ]; then
    echo -e "\n=== MODULE AUTH / SSH ==="
    echo "Echecs de connexion (Failed password) : $(grep -c "Failed password" "$LOG_FILE")"
    echo "Comptes utilisateurs les plus cibles :"
    grep "Failed password" "$LOG_FILE" | awk '{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}' | sort | uniq -c | sort -nr | head -n 3
    echo "Suspicion de Brute Force (IPs avec > 5 echecs) :"
    grep "Failed password" "$LOG_FILE" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort | uniq -c | awk '$1 > 5 {print "IP: " $2 " - Echecs: " $1}'
    echo "Connexions reussies apres echecs :"
    grep -E "Accepted (password|publickey)" "$LOG_FILE" | head -n 3
fi

# 8. Module d'analyse specifique aux logs Web (Apache/Nginx)
if [ "$TYPE" = "web" ]; then
    echo -e "\n=== MODULE SERVEUR WEB ==="
    echo "Repartition des codes HTTP :"
    awk '{print $9}' "$LOG_FILE" | grep -E "^[1-5][0-9]{2}$" | sort | uniq -c | sort -nr
    echo "Top 5 des URLs demandees :"
    awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5
    echo "Requetes suspectes (SQLi, Directory Traversal, Scans) :"
    grep -iE "select|union|\.\./|etc/passwd|eval|nikto|sqlmap" "$LOG_FILE" | head -n 5
fi

echo -e "\nAnalyse terminee. Rapport enregistre dans : $REPORT_FILE"
