name: Post Deploy

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
      aws-account:
        required: true
        type: string
      aws-account-name:
        required: true
        type: string
      aws-region:
        required: true
        type: string
      destroy:
        required: true
        type: string
      email:
        required: true
        type: string
      pipeline-type:
        required: true
        type: string
      pipeline-version:
        required: true
        type: string
      project-name:
        required: true
        type: string
      status:
        required: true
        type: string
      timestamp:
        required: true
        type: string
      experiment-id:
        required: false
        type: string
        default: ""
      mrm-id:
        required: false
        type: string
        default: ""
      runs-on:
        required: false
        type: string
        default: ${{ vars.RUNNER_K8S_OD_SMALL }}

jobs:
  post-deploy:
    runs-on: ${{ inputs.runs-on }}
    environment: ${{ inputs.environment }}
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
          export REPO_ID=$(curl -H "Authorization:token ${{ secrets.GITHUB_TOKEN }}" https://api.github.com/repos/${GITHUB_REPOSITORY} | jq -r '.id')
          echo "ROLE_NAME=itau-github-repo-${REPO_ID}" >> $GITHUB_ENV

      - name: Assume Role
        uses: itau-corp/itau-up2-action-external-management/.github/actions/aws-actions/configure-aws-credentials-role@v1
        with:
          role-to-assume: arn:aws:iam::${{ inputs.aws-account }}:role/${{ env.ROLE_NAME }}
          aws-region: ${{ inputs.aws-region }}
          role-skip-session-tagging: true
          role-duration-seconds: 1800

      - name: Post Deploy
        uses: itau-corp/itau-mr7-action-lotus/.github/actions/post-deploy@v1.2.0
        with:
          environment:        ${{ inputs.environment }}
          aws-account:        ${{ inputs.aws-account }}
          aws-account-name:   ${{ inputs.aws-account-name }}
          aws-region:         ${{ inputs.aws-region }}
          destroy:            ${{ inputs.destroy }}
          email:              ${{ inputs.email }}
          pipeline-type:      ${{ inputs.pipeline-type }}
          pipeline-version:   ${{ inputs.pipeline-version }}
          project-name:       ${{ inputs.project-name }}
          status:             ${{ inputs.status }}
          timestamp:          ${{ inputs.timestamp }}
          experiment-id:      ${{ inputs.experiment-id }}
          mrm-id:             ${{ inputs.mrm-id }}
