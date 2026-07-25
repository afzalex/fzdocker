#!/bin/bash
# Post-init: enable vchord.so in shared_preload_libraries
conf=/var/lib/postgresql/data/postgresql.conf

# Step 1: Uncomment shared_preload_libraries if commented
sed -i 's/^#[[:space:]]*shared_preload_libraries/shared_preload_libraries/' "$conf"

# Step 2: Append vchord.so to the existing comma-separated values
#   - If empty (''): replace with 'vchord.so'
#   - If non-empty ('x,y'): append to get 'x,y,vchord.so'
sed -i "/^shared_preload_libraries/ {
    s/= ''/= 'vchord.so'/
    t
    s/'\([^']*\)'/'\1,vchord.so'/
}" "$conf"

echo "vchord.so enabled in shared_preload_libraries"