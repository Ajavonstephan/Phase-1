import sys, re, json, ipaddress, os

# 1. Definition des expressions regulieres pour chaque type d'IoC
REGEX_PATTERNS = {
    "ip": r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b',
    "email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
    "url": r'https?://[^\s<>"]+',
    "domain": r'\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b',
    "hash": r'\b[a-fA-F0-9]{32}\b|\b[a-fA-F0-9]{40}\b|\b[a-fA-F0-9]{64}\b'
}

# 2. Fonction de verification des IP publiques (filtre des IP privees/locales)
def is_public_ip(ip_str):
    try:
        ip = ipaddress.ip_address(ip_str)
        return not (ip.is_private or ip.is_loopback or ip.is_reserved)
    except ValueError:
        return False

# 3. Fonction de neutralisation des IoC (Defang)
def defang(text):
    return text.replace("http://", "hXXp://").replace("https://", "hXXps://").replace(".", "[.]")

# 4. Fonction principale d'extraction des IoC depuis le fichier
def extract_iocs(filepath, do_defang=False):
    if not os.path.exists(filepath):
        print(f"Erreur : Le fichier '{filepath}' est introuvable.")
        sys.exit(1)

    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    results = {}
    for key, pattern in REGEX_PATTERNS.items():
        matches = set(re.findall(pattern, content)) # Suppression auto des doublons via set()
        if key == "ip":
            matches = {ip for ip in matches if is_public_ip(ip)} # Conservation des IP publiques uniquement
        if do_defang:
            matches = {defang(m) for m in matches} # Neutralisation si l'option est activee
        results[key] = sorted(list(matches))
    
    return results

# 5. Point d'entree du programme et gestion des arguments
def main():
    if len(sys.argv) < 2 or sys.argv[1].startswith("--"):
        print("[+] Aucun fichier spécifié. Analyse automatique du fichier local 'system_local.log'...")
        filename = "system_local.log"
    else:
        filename = sys.argv[1]

    do_defang = "--defang" in sys.argv
    export_json = "--json" in sys.argv

    if not os.path.exists(filename):
        print(f"Erreur : Le fichier '{filename}' est introuvable.")
        print("Pensez à exécuter la commande : sudo journalctl -n 200 > system_local.log")
        sys.exit(1)

    # Le reste du code d'extraction reste identique...

    iocs = extract_iocs(filename, do_defang)

    # 6. Affichage du resume a l'ecran
    print("\n================ SUMMARY IOC EXTRACTED ================")
    for category, items in iocs.items():
        print(f"[{category.upper()}] trouves : {len(items)}")

    # 7. Sauvegarde des resultats (Format JSON ou TXT)
    if export_json:
        with open("iocs_extracted.json", "w") as f:
            json.dump(iocs, f, indent=4)
        print("\nResultats sauvegardes dans 'iocs_extracted.json'")
    else:
        with open("iocs_extracted.txt", "w") as f:
            for cat, items in iocs.items():
                f.write(f"=== {cat.upper()} ===\n" + "\n".join(items) + "\n\n")
        print("\nResultats sauvegardes dans 'iocs_extracted.txt'")

if __name__ == "__main__":
    main()
