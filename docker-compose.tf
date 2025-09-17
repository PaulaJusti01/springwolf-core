- name: Get working Directory
  id: get-working-directory
  shell: bash
  run: |
    JSON_APPS='${{ steps.action-parse-iupipes.outputs.build-working-directory }}'

    build_working_directory=$(printf '%s' "$JSON_APPS" \
      | jq -r 'if type=="array" then map(select(. != "")) else [] end | tostring')

    if [ -z "$build_working_directory" ] || [ "$build_working_directory" = "null" ]; then
      build_working_directory='[]'
    fi

    # upload usa a mesma lista; se quiser manter fallback pra "infra", ajuste aqui
    upload_working_directory=$build_working_directory

    echo "UploadWorkingDirectory_output=$upload_working_directory" >> "$GITHUB_OUTPUT"
    echo "WorkingDirectory_output=$build_working_directory" >> "$GITHUB_OUTPUT"
