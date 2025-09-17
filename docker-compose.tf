perfeito 🚀 segue o 2-read-config.yml limpinho, sem nenhum comentário:

name: Read Config

permissions:
  id-token: write
  contents: write
  issues: write
  checks: write
  actions: write
  packages: read
  pull-requests: write

on:
  workflow_call:
    inputs:
      build-environment:
        required: true
        type: string
      branch:
        required: false
        type: string
        default: ""
    outputs:
      build-working-directory:
        value: ${{ jobs.read-config-data.outputs.build-working-directory }}
      build-python-version:
        value: ${{ jobs.read-config-data.outputs.build-python-version }}
      build-architecture:
        value: ${{ jobs.read-config-data.outputs.build-architecture }}
      build-requirement-path:
        value: ${{ jobs.read-config-data.outputs.build-requirement-path }}
      build-docker-platform:
        value: ${{ jobs.read-config-data.outputs.build-docker-platform }}
      test-requirement-path:
        value: ${{ jobs.read-config-data.outputs.test-requirement-path }}
      test-disable:
        value: ${{ jobs.read-config-data.outputs.test-disable }}
      publish-deploy-only:
        value: ${{ jobs.read-config-data.outputs.publish-deploy-only }}
      publish-copy-all-dependency:
        value: ${{ jobs.read-config-data.outputs.publish-copy-all-dependency }}
      publish-install-dependency-path:
        value: ${{ jobs.read-config-data.outputs.publish-install-dependency-path }}
      publish-andromeda-repository:
        value: ${{ jobs.read-config-data.outputs.publish-andromeda-repository }}
      aws-account:
        value: ${{ jobs.read-config-data.outputs.aws-account }}
      aws-account-name:
        value: ${{ jobs.read-config-data.outputs.aws-account-name }}
      aws-region:
        value: ${{ jobs.read-config-data.outputs.aws-region }}
      sigla:
        value: ${{ jobs.read-config-data.outputs.sigla }}
      project-name:
        value: ${{ jobs.read-config-data.outputs.project-name }}
      pipeline-type:
        value: ${{ jobs.read-config-data.outputs.pipeline-type }}
      pipeline-version:
        value: ${{ jobs.read-config-data.outputs.pipeline-version }}
      destroy:
        value: ${{ jobs.read-config-data.outputs.destroy }}
      timestamp:
        value: ${{ jobs.read-config-data.outputs.timestamp }}
      model-name:
        value: ${{ jobs.read-config-data.outputs.model-name }}
      model-path:
        value: ${{ jobs.read-config-data.outputs.model-path }}
      lotus-s3-bucket:
        value: ${{ jobs.read-config-data.outputs.lotus-s3-bucket }}
      table-name:
        value: ${{ jobs.read-config-data.outputs.table-name }}
      spec-s3bucket:
        value: ${{ jobs.read-config-data.outputs.spec-s3bucket }}
      spec-db-source-name:
        value: ${{ jobs.read-config-data.outputs.spec-db-source-name }}
      spec-db-corp-name:
        value: ${{ jobs.read-config-data.outputs.spec-db-corp-name }}
      experiment-id:
        value: ${{ jobs.read-config-data.outputs.experiment-id }}
      id-mrm:
        value: ${{ jobs.read-config-data.outputs.id-mrm }}
      tech-team-email:
        value: ${{ jobs.read-config-data.outputs.tech-team-email }}

jobs:
  read-config-data:
    name: Read Config Data
    runs-on: ${{ vars.RUNNER_K8S_OD_SMALL }}

    outputs:
      build-working-directory: ${{ steps.compute-working-dirs.outputs.build_working_directory }}
      build-python-version:    ${{ steps.parse-iupipes.outputs.build-python-version }}
      build-architecture:      ${{ steps.parse-iupipes.outputs.build-architecture }}
      build-requirement-path:  ${{ steps.parse-iupipes.outputs.build-requirement-path }}
      build-docker-platform:   ${{ steps.parse-iupipes.outputs.build-docker-platform }}
      test-requirement-path:   ${{ steps.parse-iupipes.outputs.test-requirement-path }}
      test-disable:            ${{ steps.parse-iupipes.outputs.test-disable }}
      publish-deploy-only:     ${{ steps.parse-iupipes.outputs.publish-deploy-only }}
      publish-copy-all-dependency:     ${{ steps.parse-iupipes.outputs.publish-copy-all-dependency }}
      publish-install-dependency-path: ${{ steps.parse-iupipes.outputs.publish-install-dependency-path }}
      publish-andromeda-repository:    ${{ steps.parse-iupipes.outputs.publish-andromeda-repository }}
      aws-account:       ${{ steps.parse-config.outputs.info-aws_account_number-${{ inputs.build-environment }} }}
      aws-account-name:  ${{ steps.parse-config.outputs.info-aws_account-name }}
      aws-region:        ${{ steps.parse-config.outputs.info-aws_region }}
      sigla:             ${{ steps.parse-config.outputs.itau-sigla }}
      project-name:      ${{ steps.repo-info.outputs.application_name }}
      pipeline-type:     ${{ steps.parse-config.outputs.pipeline_type }}
      pipeline-version:  ${{ steps.repo-info.outputs.version }}
      destroy:           ${{ steps.parse-config.outputs.infra-terraform-destroy }}
      timestamp:         ${{ steps.get-timestamp.outputs.timestamp }}
      model-name:        model.tar.gz
      model-path:        ${{ steps.parse-config.outputs.model-path }}
      lotus-s3-bucket:   ${{ steps.set-lotus-s3-bucket.outputs.lotus-s3-bucket }}
      table-name:        ${{ steps.repo-info.outputs.table_name }}
      spec-s3bucket:     ${{ steps.set-lotus-s3-bucket.outputs.spec-s3bucket }}
      spec-db-source-name: ${{ steps.set-lotus-s3-bucket.outputs.spec-db-source-name }}
      spec-db-corp-name:   ${{ steps.set-lotus-s3-bucket.outputs.spec-db-corp-name }}
      experiment-id:     ${{ steps.parse-config.outputs.parameters-experiment_id }}
      id-mrm:            ${{ steps.parse-config.outputs.parameters-id_mrm }}
      tech-team-email:   ${{ steps.parse-config.outputs.info-tech_team_email }}

    steps:
      - name: Get timestamp
        id: get-timestamp
        shell: bash
        run: |
          echo "timestamp=$(date '+%Y-%m-%d %H:%M:%S')" >> "$GITHUB_OUTPUT"

      - name: Get secrets from AWS Secrets Manager
        id: get-secrets
        uses: itau-corp/itau-up2-action-external-management/.github/actions/aws-actions/up2-secretsmanager-get-secrets@v1
        with:
          secret-ids: |
            ,GH/UP2/ARTIFACTORY
            ,GH/UP2/APP/IUPIPES-APP-CI
          parse-json-secrets: true

      - name: Get Token
        id: get-workflow-token
        uses: itau-corp/itau-up2-action-external-management/.github/actions/peter-murray/workflow-application-token-action@v1
        with:
          application_id:     ${{ env.APP_ID }}
          application_private_key: ${{ env.PRIVATE_KEY }}

      - name: Checkout User Repo
        uses: itau-corp/itau-up2-action-external-management/.github/actions/actions/checkout@v1
        with:
          path: ./repo_user
          ref: ${{ inputs.branch != '' && inputs.branch || github.ref_name }}

      - name: Config parser
        id: parse-config
        uses: itau-corp/itau-up2-action-config-parse@v1
        with:
          configPath: repo_user/config.yml
          reusableInputs: ${{ toJSON(inputs) }}

      - name: Parse .iupipes.yml
        id: parse-iupipes
        uses: itau-corp/itau-mr7-action-lotus/.github/actions/parse-yaml-to-json@v1.2.0
        with:
          path: repo_user/.iupipes.yml
          key: ""

      - name: Compute Working Dirs
        id: compute-working-dirs
        shell: bash
        run: |
          JSON_APPS='${{ steps.parse-iupipes.outputs.build-working-directory }}'
          if [ -z "$JSON_APPS" ] || [ "$JSON_APPS" = "null" ]; then
            JSON_APPS='["app"]'
          fi
          echo "build_working_directory=$JSON_APPS" >> "$GITHUB_OUTPUT"

      - name: Get Repo Info
        id: repo-info
        shell: bash
        run: |
          sigla='${{ steps.parse-config.outputs.itau-sigla }}'
          echo "sigla=$sigla" >> "$GITHUB_OUTPUT"

          application_name='${{ steps.parse-config.outputs.application_name }}'
          application_name=$(echo "$application_name" | sed -E 's/\.infra|-\.app//g' | tr '[:upper:]' '[:lower:]')
          echo "application_name=$application_name" >> "$GITHUB_OUTPUT"

          table_name="tblotus_${application_name}"
          echo "table_name=$table_name" >> "$GITHUB_OUTPUT"

          echo "version=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"

      - name: Set lotus-s3-bucket
        id: set-lotus-s3-bucket
        shell: bash
        run: |
          env="${{ inputs.build-environment }}"

          if [ "$env" = "analytics" ]; then
            echo "lotus-s3-bucket=itau-sel-wkp-sa-east-1-${{ steps.parse-config.outputs.info-aws_account-number-analytics }}" >> "$GITHUB_OUTPUT"
            echo "aws-account=${{ steps.parse-config.outputs.info-aws_account-number-analytics }}" >> "$GITHUB_OUTPUT"
          elif [ "$env" = "dev" ]; then
            echo "lotus-s3-bucket=itau-sel-wkp-sa-east-1-${{ steps.parse-config.outputs.info-aws_account-number-dev }}" >> "$GITHUB_OUTPUT"
            echo "aws-account=${{ steps.parse-config.outputs.info-aws_account-number-dev }}" >> "$GITHUB_OUTPUT"
          elif [ "$env" = "hom" ]; then
            echo "lotus-s3-bucket=itau-sel-wkp-sa-east-1-${{ steps.parse-config.outputs.info-aws_account-number-hom }}" >> "$GITHUB_OUTPUT"
            echo "aws-account=${{ steps.parse-config.outputs.info-aws_account-number-hom }}" >> "$GITHUB_OUTPUT"
          else
            echo "lotus-s3-bucket=itau-sel-wkp-sa-east-1-${{ steps.parse-config.outputs.info-aws_account-number-prod }}" >> "$GITHUB_OUTPUT"
            echo "aws-account=${{ steps.parse-config.outputs.info-aws_account-number-prod }}" >> "$GITHUB_OUTPUT"
          fi

          echo "spec-s3bucket=${{ steps.parse-config.outputs.spec-s3bucket }}" >> "$GITHUB_OUTPUT"
          echo "spec-db-source-name=${{ steps.parse-config.outputs.spec-db-source-name }}" >> "$GITHUB_OUTPUT"
          echo "spec-db-corp-name=${{ steps.parse-config.outputs.spec-db-corp-name }}" >> "$GITHUB_OUTPUT"

quer que eu faça a mesma limpeza (sem comentários, identação uniforme) também no post-deploy e mrm-validation?

