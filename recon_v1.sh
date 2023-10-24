#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

# Check if directory exists for the domain, if not, create it
if [ ! -d "$DOMAIN" ]; then
    mkdir "$DOMAIN"
fi

cd "$DOMAIN"

# Step 1: Subdomain enumeration using subfinder and amass
echo "[+] Enumerating subdomains for $DOMAIN using subfinder..."
subfinder -d $DOMAIN -o subfinder_subdomains.txt

echo "[+] Enumerating subdomains for $DOMAIN using amass..."
amass enum -d $DOMAIN -o amass_subdomains.txt

# Combine the results and remove duplicates
cat subfinder_subdomains.txt amass_subdomains.txt | sort -u > combined_subdomains.txt

# Step 2: Check for live subdomains using httprobe
echo "[+] Checking for live subdomains using httprobe..."
cat combined_subdomains.txt | httprobe > live_subdomains.txt

# Step 3: Scanning live subdomains with nuclei
echo "[+] Scanning live subdomains with nuclei..."
nuclei -l live_subdomains.txt -t /path/to/nuclei-templates/ -o nuclei_results.txt

# Step 4: Scanning live subdomains with KiteRunner
echo "[+] Scanning live subdomains with KiteRunner..."
kr scan -w /path/to/kite_common_paths.rz -o kite_results.txt live_subdomains.txt

# Step 5: Scanning live subdomains with Arjun to discover hidden parameters
echo "[+] Scanning live subdomains with Arjun for hidden parameters..."
if [ ! -d "arjun_results" ]; then
    mkdir arjun_results
fi
while read subdomain; do
    arjun -u $subdomain --get -o "arjun_results/$subdomain.txt"
done < live_subdomains.txt

# Step 6: Taking screenshots of live subdomains using gowitness
echo "[+] Capturing screenshots of live subdomains using gowitness..."
if [ ! -d "pics" ]; then
    mkdir pics
fi
gowitness file -f live_subdomains.txt -P pics

echo "[+] Scan completed!"
