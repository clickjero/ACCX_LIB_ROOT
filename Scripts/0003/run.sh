#!/bin/bash

# import libraries
source "$(dirname "$0")/../lib/init.sh"

# Main
jq -c '.remote_sites[]' "$SCRIPT_DIR/data/config.json" | while read remote_site; do
    # init all params
    remote_site_name=$(echo $remote_site | jq -r '.Name');
    remote_site_disable_protocol_security=$(echo $remote_site | jq -r '.DisableProtocolSecurity');
    remote_site_is_active=$(echo $remote_site | jq -r '.Active');
    remote_site_url=$(echo $remote_site | jq -r '.Url');
    if [[ "$remote_site_url" == "null" ]]; then
        remote_site_url="$(get_org_vf_url)";
    fi
    echo_loading "$remote_site_name"
    # compare with remote site in sf
    sf_remote_site=$(sfdx accedx:remotesite:list -u "$ACCEDX_ORG" -n "$remote_site_name" --json | jq -c '{status,name,message,result}');
    remove_last_line; # remove last line in console output
    if [[ "$(echo $sf_remote_site | jq -r '.result.url')" != "$remote_site_url" ]] ||
       [[ "$(echo $sf_remote_site | jq -r '.result.disableProtocolSecurity')" != "$remote_site_disable_protocol_security" ]] ||
       [[ "$(echo $sf_remote_site | jq -r '.result.isActive')" != "$remote_site_is_active" ]]; then
        upsert_result=$(echo $(sfdx accedx:remotesite:set -u "$ACCEDX_ORG" -n "$remote_site_name" --url "$remote_site_url" -D "$remote_site_disable_protocol_security" -A "$remote_site_is_active" --json) | tr -d '[:cntrl:]');
        log_salesforce_retreive_response "$upsert_result" "$remote_site_name set to $remote_site_url";
    else
        echo_i "no changes" "$remote_site_name";
    fi
done
