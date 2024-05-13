#!/bin/bash

# Base directory for compliance reports
BASE_DIR="/home/azureuser/compliance/mulligan/reports/automate-script"

# Files for each report type
INVENTORY_FILE="$BASE_DIR/compliance-reporter-pod-inventory.yaml"
NETWORK_ACCESS_FILE="$BASE_DIR/compliance-reporter-pod-network-access.yaml"
POLICY_AUDIT_FILE="$BASE_DIR/compliance-reporter-pod-policy-audit.yaml"
CIS_BENCHMARK_FILE="$BASE_DIR/compliance-reporter-pod-cis-benchmark.yaml"

# Generate the date and time formats for the pod names with more granularity
DATE_SUFFIX=$(date +"%Y-%m-%d-%H%M%S")  # Includes hours, minutes, and seconds

# Calculate the start and end times
START_TIME=$(date -d '+2 minutes' +"%Y-%m-%dT%H:%M:%SZ")
END_TIME=$(date -d '+10 minutes' +"%Y-%m-%dT%H:%M:%SZ")

# Function to update and apply a report YAML file
update_and_apply_report() {
    local yaml_file=$1
    local report_prefix=$2

    # Update the YAML file with the new values
    sed -i "s/name: $report_prefix.*/name: $report_prefix-$DATE_SUFFIX/" $yaml_file
    sed -i "/TIGERA_COMPLIANCE_REPORT_START_TIME/c\        - name: TIGERA_COMPLIANCE_REPORT_START_TIME\n          value: $START_TIME" $yaml_file
    sed -i "/TIGERA_COMPLIANCE_REPORT_END_TIME/c\        - name: TIGERA_COMPLIANCE_REPORT_END_TIME\n          value: $END_TIME" $yaml_file

    # Apply the manifest with kubectl
    kubectl apply -f $yaml_file
    echo "$yaml_file deployed with updated times."
}

# Apply updates to each report
update_and_apply_report $INVENTORY_FILE "run-reporter"
update_and_apply_report $NETWORK_ACCESS_FILE "daily-network-access-reporter"
update_and_apply_report $POLICY_AUDIT_FILE "daily-policy-audit-reporter"
update_and_apply_report $CIS_BENCHMARK_FILE "daily-cis-benchmark-reporter"

