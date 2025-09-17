name: Build Dependencies

permissions:
  id-token: write
  contents: write
  issues: write
  checks: write
  actions: write
  pull-requests: write
  packages: read

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      build-environment:
        required: true
        type: string
      condominio:
        required: true
        type: string
      runs-on:
        required: false
        type: string
        default: ${{ vars.RUNNER_K8S_OD_SMALL }}
      aws-account:
        required: true
        type: string
      aws-region:
        required: true
        type: string
      s3-bucket:
        required: true
        type: string
      model-path:
        required: true
        type: string
      model-name:
        required: true
        type: string
      project-name:
        required: true
        type: string
      spec-s3bucket:
        required: false
        type: string
      table-name:
        required: false
        type: string
      spec-db-source-name:
        required: false
        type: string
      spec-db-corp-name:
        required: false
        type: string
      sigla:
        required: false
        type: string
      target-delay-days:
        required: false
        type: string
      should-run-performance-drift:
        required: false
        type: string

jobs:
  build-dependencies:
    runs-on: ${{ inputs.runs-on }}
    environment: ${{ inputs.environment }}
    steps:
      - name: Get secrets from AWS Secrets Manager
        id: get-secrets
        uses: itau-corp/itau-up2-action-external-management/.github/actions/aws-actions/up2-secretsmanager-get-secrets@v1
        with:
          secret-ids: |
            ,GH/UP2/ARTIFACTORY
            ,GH/UP2/APP/IUIPES-APP-CI
          parse-json-secrets: true

      - name: Get Token
        id: get_workflow_token
        uses: itau-corp/itau-up2-action-external-management/.github/actions/peter-murray/workflow-application-token-action@v1
        with:
          application_id: ${{ env.APP_ID }}
          application_private_key: ${{ env.PRIVATE_KEY }}

      - name: Checkout User Repository
        uses: itau-corp/itau-up2-action-external-management/.github/actions/actions/checkout@v1

      - name: Role Info
        run: |
          export REPO_ID=$(curl -H "Authorization:token ${{ secrets.GITHUB_TOKEN }}" https://api.github.com/repos/${GITHUB_REPOSITORY} | jq -r '.id')
          echo "ROLE_NAME=itau-github-repo-${REPO_ID}" >> $GITHUB_ENV

      - name: Assume Role
        uses: itau-corp/itau-up2-action-external-management/.github/actions/aws-actions/configure-aws-credentials-role@v1
        with:
          role-to-assume: arn:aws:iam::${{ inputs.aws-account }}:role/${{ env.ROLE_NAME }}
          aws-region: ${{ inputs.aws-region }}
          role-skip-session-tagging: true
          role-duration-seconds: 1800

      - name: Config parser
        id: action-parse
        uses: itau-corp/itau-up2-action-config-parse@v1
        with:
          configPath: config.yml
          reusableInputs: ${{ toJSON(inputs) }}

      - name: Get Database
        id: get-database
        if: ${{ inputs.spec-db-source-name == '' }}
        uses: itau-corp/itau-mr7-action-lotus/.github/actions/get-databases@v1.2.0
        with:
          build-environment: ${{ inputs.build-environment }}

      - name: Prepare Dependencies
        id: prepare-dependencies
        uses: itau-corp/itau-mr7-action-lotus/.github/actions/build-dependencies@v1.2.0
        with:
          s3-bucket: ${{ inputs.s3-bucket }}
          sigla: ${{ inputs.sigla }}
          condominio: ${{ inputs.condominio }}
          user-aws-region: ${{ inputs.aws-region }}
          model-name: ${{ inputs.model-name }}
          environment: ${{ inputs.environment }}
          table-name: ${{ inputs.table-name }}
          project-name: ${{ inputs.project-name }}
          spec-s3bucket: ${{ inputs.spec-s3bucket }}
          user-aws-account: ${{ inputs.aws-account }}
          build-environment: ${{ inputs.build-environment }}
          network-params: ${{ steps.action-parse.outputs.json }}
          schedule-expression: ${{ steps.action-parse.outputs.trigger }}
          pipeline-type: ${{ steps.action-parse.outputs.pipeline_type }}
          inference-type: ${{ steps.action-parse.outputs.inference_type }}
          sdk-version: ${{ steps.action-parse.outputs.lotus_sdk_version }}
          owner-contact-email: ${{ steps.action-parse.outputs.info_owner_contact_email }}
          tech-team-email: ${{ steps.action-parse.outputs.info_tech_team_email }}
          model-path: ${{ inputs.model-path }}
          experiment-id: ${{ steps.action-parse.outputs.parameters_experiment_id }}
          id-mrm: ${{ steps.action-parse.outputs.parameters_id_mrm }}
          spec-db-source-name: ${{ steps.get-database.outputs.db_source || inputs.spec-db-source-name }}
          spec-db-corp-name: ${{ steps.get-database.outputs.db_corp || inputs.spec-db-corp-name }}
          should-run-performance-drift: ${{ inputs.should-run-performance-drift }}
          target-delay-days: ${{ inputs.target-delay-days }}

      - name: Configure Artifacts Path
        run: |
          export artifacts_name=$(echo ${GITHUB_REPOSITORY}-infra-${GITHUB_SHA} | tr '/' '-')
          export artifacts_infra_name=$(echo ${GITHUB_REPOSITORY}-infra-${GITHUB_SHA} | tr '/' '-')
          export artifacts_test_name=$(echo test-${GITHUB_REPOSITORY}-infra-${GITHUB_SHA} | tr '/' '-')
          echo "artifacts_name=${artifacts_name}" >> $GITHUB_ENV
          echo "artifacts_infra_name=${artifacts_infra_name}" >> $GITHUB_ENV
          echo "artifacts_test_name=${artifacts_test_name}" >> $GITHUB_ENV

      - name: Download Artifacts
        uses: itau-corp/itau-up2-action-external-management/.github/actions/actions/download-artifact@v1
        with:
          merge-multiple: true
          path: ${{ github.workspace }}/artifact_files

      - name: Move Files and Create Artifacts
        env:
          artifacts_name: ${{ env.artifacts_name }}
          artifacts_infra_name: ${{ env.artifacts_infra_name }}
          artifacts_test_name: ${{ env.artifacts_test_name }}
        run: |
          mkdir -p ${{ github.workspace }}/prepare_files/infra
          mkdir -p ${{ github.workspace }}/upload_files/
          cp -r ${{ github.workspace }}/build_files/infra/* ${{ github.workspace }}/prepare_files/
          zip -r ${{ github.workspace }}/upload_files/${{ env.artifacts_name }}.zip *

      - name: Upload App Artifact
        uses: itau-corp/itau-up2-action-external-management/.github/actions/actions/upload-artifact@v1
        with:
          name: ${{ env.artifacts_name }}
          path: ${{ github.workspace }}/upload_files/${{ env.artifacts_name }}.zip
          retention-days: 1
          overwrite: true
