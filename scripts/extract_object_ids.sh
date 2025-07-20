#!/bin/bash

# Script to extract object IDs from publish output
# Usage: ./extract_object_ids.sh [environment]

environment=$1

sui client switch --env $environment
rm -f scripts/publish_output_$environment.txt
sui client publish > scripts/publish_output_$environment.txt

echo "Extracting object IDs from: scripts/publish_output_$environment.txt"
echo "=========================================="

# Helper function to clean up extracted IDs
clean_id() {
    echo "$1" | sed 's/│.*//' | tr -d ' ' | tr -d '\n'
}

# Extract AdminCap object ID
echo "AdminCap Object ID:"
RAW_ADMIN_CAP_ID=$(grep -B 5 "AdminCap" "scripts/publish_output_$environment.txt" | grep "ObjectID:" | head -1 | sed 's/.*ObjectID: //')
ADMIN_CAP_ID=$(clean_id "$RAW_ADMIN_CAP_ID")
if [ -n "$ADMIN_CAP_ID" ]; then
    echo "  $ADMIN_CAP_ID"
else
    echo "  Not found"
fi

echo ""

# Extract Registry object ID
echo "Registry Object ID:"
RAW_REGISTRY_ID=$(grep -B 5 "Registry" "scripts/publish_output_$environment.txt" | grep "ObjectID:" | head -1 | sed 's/.*ObjectID: //')
REGISTRY_ID=$(clean_id "$RAW_REGISTRY_ID")
if [ -n "$REGISTRY_ID" ]; then
    echo "  $REGISTRY_ID"
else
    echo "  Not found"
fi

echo ""

# Extract Config object ID
echo "Config Object ID:"
RAW_CONFIG_ID=$(grep -B 5 "Config" "scripts/publish_output_$environment.txt" | grep "ObjectID:" | head -1 | sed 's/.*ObjectID: //')
CONFIG_ID=$(clean_id "$RAW_CONFIG_ID")
if [ -n "$CONFIG_ID" ]; then
    echo "  $CONFIG_ID"
else
    echo "  Not found"
fi

echo ""

# Extract Publisher object ID
echo "Publisher Object ID:"
RAW_PUBLISHER_ID=$(grep -B 5 "Publisher" "scripts/publish_output_$environment.txt" | grep "ObjectID:" | head -1 | sed 's/.*ObjectID: //')
PUBLISHER_ID=$(clean_id "$RAW_PUBLISHER_ID")
if [ -n "$PUBLISHER_ID" ]; then
    echo "  $PUBLISHER_ID"
else
    echo "  Not found"
fi

echo ""

# Extract Package ID
echo "Package ID:"
RAW_PACKAGE_ID=$(grep "PackageID:" "scripts/publish_output_$environment.txt" | head -1 | sed 's/.*PackageID: //')
echo "RAW_PACKAGE_ID: $RAW_PACKAGE_ID"
PACKAGE_ID=$(clean_id "$RAW_PACKAGE_ID")
if [ -n "$PACKAGE_ID" ]; then
    echo "  $PACKAGE_ID"
else
    echo "  Not found"
fi

echo ""
echo "=========================================="
echo "Summary:"
echo "AdminCap: $ADMIN_CAP_ID"
echo "Registry: $REGISTRY_ID"
echo "Config:   $CONFIG_ID"
echo "Publisher: $PUBLISHER_ID"
echo "Package:  $PACKAGE_ID"

echo ""
echo "=========================================="
echo "Updating social-layer-sdk/src/constants/index.ts"

CONSTANTS_FILE="../social-layer-sdk/src/constants/index.ts"

# Check if constants file exists
if [ ! -f "$CONSTANTS_FILE" ]; then
    echo "Error: Constants file not found at $CONSTANTS_FILE"
    exit 1
fi

# Need to handle both 'darwin' (macOS) and 'linux' sed
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i "" "$@"
    else
        sed -i "$@"
    fi
}

# Update for the given environment
if [ "$environment" == "testnet" ] || [ "$environment" == "mainnet" ]; then
    # Get the line number of the environment block start
    start_line=$(grep -n "${environment}:" "$CONSTANTS_FILE" | head -1 | cut -d: -f1)

    # Find the closing brace for the environment block to define the search range
    end_line=$(awk "NR > $start_line && /}/ {print NR; exit}" "$CONSTANTS_FILE")

    # Get the line number of each ID within the environment block
    contract_id_line=$(awk "NR > $start_line && NR < $end_line && /contractId:/ {print NR; exit}" "$CONSTANTS_FILE")
    config_id_line=$(awk "NR > $start_line && NR < $end_line && /configId:/ {print NR; exit}" "$CONSTANTS_FILE")
    registry_id_line=$(awk "NR > $start_line && NR < $end_line && /registryId:/ {print NR; exit}" "$CONSTANTS_FILE")
    publisher_id_line=$(awk "NR > $start_line && NR < $end_line && /publisherId:/ {print NR; exit}" "$CONSTANTS_FILE")

    # The actual values are on the next line
    contract_id_value_line=$((contract_id_line + 1))
    config_id_value_line=$((config_id_line + 1))
    registry_id_value_line=$((registry_id_line + 1))
    publisher_id_value_line=$((publisher_id_line + 1))

    # Update the file
    sedi "${contract_id_value_line}s|'.*'|      '$PACKAGE_ID'|" "$CONSTANTS_FILE"
    echo "Updated ${environment} contractId to $PACKAGE_ID"

    sedi "${config_id_value_line}s|'.*'|      '$CONFIG_ID'|" "$CONSTANTS_FILE"
    echo "Updated ${environment} configId to $CONFIG_ID"

    sedi "${registry_id_value_line}s|'.*'|      '$REGISTRY_ID'|" "$CONSTANTS_FILE"
    echo "Updated ${environment} registryId to $REGISTRY_ID"

    sedi "${publisher_id_value_line}s|'.*'|      '$PUBLISHER_ID'|" "$CONSTANTS_FILE"
    echo "Updated ${environment} publisherId to $PUBLISHER_ID"
else
    echo "Skipping constants update: environment '$environment' is not 'testnet' or 'mainnet'."
fi

echo "Done."