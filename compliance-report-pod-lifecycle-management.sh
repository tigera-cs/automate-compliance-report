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

# Function to clean up old completed pods
cleanup_old_pods() {
    echo "Cleaning up old completed pods..."
    # Get the current date in the format as it appears in the pod name
    current_date=$(date +"%Y-%m-%d")  # This matches the DATE_SUFFIX format in your pod names
    
    # List all pods in the namespace, focusing on completed ones
    pods=$(kubectl get pods -n tigera-compliance --no-headers | grep 'Completed')
    echo "Reviewing completed pods..."

    # Loop through each completed pod
    echo "$pods" | while IFS= read -r line; do
        pod_name=$(echo "$line" | awk '{print $1}')
        pod_status=$(echo "$line" | awk '{print $3}')
        pod_age=$(echo "$line" | awk '{print $5}')
        
        # Extract the date part from the pod name based on expected naming convention
        pod_date=$(echo "$pod_name" | grep -oP '\d{4}-\d{2}-\d{2}')
        
        echo "Checking pod: $pod_name with date $pod_date"

        # Compare the extracted date to today's date
        if [[ "$pod_date" < "$current_date" ]]; then
            echo "Deleting old pod: $pod_name"
            kubectl delete pod -n tigera-compliance "$pod_name"
        else
            echo "Pod $pod_name is from today or a future date, skipping..."
        fi
    done
    echo "Cleanup complete."
}

# Apply updates to each report
update_and_apply_report $INVENTORY_FILE "run-reporter"
update_and_apply_report $NETWORK_ACCESS_FILE "daily-network-access-reporter"
update_and_apply_report $POLICY_AUDIT_FILE "daily-policy-audit-reporter"
update_and_apply_report $CIS_BENCHMARK_FILE "daily-cis-benchmark-reporter"

# Clean up old completed pods
cleanup_old_pods

