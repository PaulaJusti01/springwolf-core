name: Download Artifacts

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
      build-environment:
        required: true
        type: string
      aws-account:
        required: true
        type: string
      aws-region:
        required: false
        type: string
        default: sa-east-1
      environment:
        required: true
        type: string
      experiment-id:
        required: true
        type: string
      model-name:
        required: true
        type: string
      model-path:
        required: true
        type: string
      s3-bucket:
        required: true
        type: string
      destroy:
        required: false
        type: string
        default: "false"
      table-name:
        required: false
        type: string
      runs-on:
        required: false
        type: string
        default: ${{ vars.RUNNER_K8S_OD_SMALL }}
    outputs:
      target_delay_days:
        value: ${{ jobs.download-artifacts.outputs.target_delay_days }}
      should_run_performance_drift:
        value: ${{ jobs.download-artifacts.outputs.should_run_performance_drift }}

jobs:
  download-artifacts:
    runs-on: ${{ inputs.runs-on }}
    environment: ${{ inputs.environment }}
    name: Download Artifacts
    outputs:
      target_delay_days: ${{ steps.download.outputs.target_delay_days }}
      should_run_performance_drift: ${{ steps.download.outputs.should_run_performance_drift }}
    steps:
      - name: Get secrets from AWS Secrets Manager
        id: get-secrets
        uses: itau-corp/itau-up2-action-external-management/.github/actions/aws-actions/up2-secretsmanager-get-secrets@v1
        with:
          secret-ids: |
            ,GH/UP2/ARTIFACTORY
            ,GH/UP2/APP/IUPIPES-APP-CI
          parse-json-secrets: true

      - name: Get Token
        id: get_workflow_token
        uses: itau-corp/itau-up2-action-external-management/.github/actions/peter-murray/workflow-application-token-action@v1
        with:
          application_id: ${{ env.APP_ID }}
          application_private_key: ${{ env.PRIVATE_KEY }}

      - name: Role Info
        run: |
          export REPO_ID=$(curl -H "Authorization:token ${{ secrets.GITHUB_TOKEN }}" https://api.github.com/repos/${{ github.repository }} | jq -r .id)
          echo "ROLE_NAME=itau-github-repo-${REPO_ID}" >> $GITHUB_ENV

      - name: Checkout user repository
        uses: itau-corp/itau-up2-action-external-management/.github/actions/actions/checkout@v1

      - name: Assume Role
        uses: itau-corp/itau-up2-action-external-management/.github/actions/aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: arn:aws:iam::${{ inputs.aws-account }}:role/${{ env.ROLE_NAME }}
          aws-region: ${{ inputs.aws-region }}
          role-skip-session-tagging: true
          role-duration-seconds: 1800

      - name: Download and Upload Artifacts
        id: download
        if: ${{ inputs.destroy == 'false' || inputs.destroy == false }}
        uses: itau-corp/itau-mr7-action-lotus/.github/actions/download-artifacts@v1.2.0
        with:
          experiment-id: ${{ inputs.experiment-id }}
          s3-bucket: ${{ inputs.s3-bucket }}
          model-path: ${{ inputs.model-path }}
          model-name: ${{ inputs.model-name }}
          environment: ${{ inputs.environment }}
          build-environment: ${{ inputs.build-environment }}
          table-name: ${{ inputs.table-name }}
