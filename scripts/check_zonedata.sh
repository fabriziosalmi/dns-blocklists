#!/usr/bin/env bash

set -euo pipefail # More robust error handling

# Check if named-checkzone is installed
if ! command -v named-checkzone &> /dev/null; then
  echo "Error: named-checkzone is not installed."
  echo "This tool is required to validate DNS zone files and is typically part of the bind-utils package."
  exit 1
fi

echo "[#] Checking hostlists..."

# Process each hostlist file
for hostlist in ../output/{doh,relay}/*.txt; do
  if [[ -f "$hostlist" ]]; then # Check if the file exists
    echo "[#] $hostlist"
    temp_filename=$(basename "$hostlist").zone # Append .zone for clarity

    # Generate the zone file header
    cat <<EOF > "$temp_filename"
\$TTL 604800
@ IN SOA ns.example.com. root.example.com. (
  1337 ; Serial
  604800 ; Refresh
  86400 ; Retry
  2419200 ; Expire
  604800 ; Negative Cache TTL
)
@ IN NS ns.example.com.
EOF

    # Process each hostname in the hostlist
    while IFS= read -r hostname; do
      if [[ -n "$hostname" ]]; then # Check if hostname is not empty
        echo "$hostname IN CNAME ." >> "$temp_filename"
      fi
    done < "$hostlist"

    # Validate the generated zone file
    if named-checkzone "$(basename --suffix=.txt "$hostlist")" "$temp_filename"; then
      echo "[#] $temp_filename validated successfully."
    else
      echo "Error: $temp_filename validation failed."
    fi

    # Remove the temporary zone file
    rm "$temp_filename"
  else
    echo "Warning: $hostlist does not exist."
  fi
done

echo ""
echo "[#] Checking zonefiles..."

# Process each zone file
for zonefile in ../output/{doh,relay}/*.zone; do
  if [[ -f "$zonefile" ]]; then # Check if the file exists
    echo "[#] $zonefile"
    if named-checkzone "$(basename --suffix=.zone "$zonefile")" "$zonefile"; then
      echo "[#] $zonefile validated successfully."
    else
      echo "Error: $zonefile validation failed."
    fi
  else
    echo "Warning: $zonefile does not exist."
  fi
done

echo "Validation complete."
