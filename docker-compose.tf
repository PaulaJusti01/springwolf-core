name: "2 - DEV - Build and Deploy"

on:
  workflow_call:

jobs:
  read-config:
    name: Read Config
    uses: ./.github/workflows/2-read-config.yml
    with:
      build-environment: dev
    secrets: inherit

  download-artifacts:
    name: Download Artifacts
    uses: ./.github/workflows/2-download-artifacts.yml
    needs:
      - read-config
    with:
      environment: dev
      aws-account: ${{ needs.read-config.outputs.aws-account }}
      aws-region:  ${{ needs.read-config.outputs.aws-region }}
      experiment-id: ${{ needs.read-config.outputs.experiment-id }}
      model-name:   ${{ needs.read-config.outputs.model-name }}
      model-path:   ${{ needs.read-config.outputs.model-path }}
      s3-bucket:    ${{ needs.read-config.outputs.lotus-s3-bucket }}
      table-name:   ${{ needs.read-config.outputs.table-name }}
      destroy:      ${{ needs.read-config.outputs.destroy }}
    secrets: inherit

  build-dependencies:
    name: Build Dependencies
    uses: ./.github/workflows/2-build-dependencies.yml
    needs:
      - read-config
      - download-artifacts
    with:
      condominio: devops
      environment: dev
      build-environment: dev
      sigla:        ${{ needs.read-config.outputs.sigla }}
      model-name:   ${{ needs.read-config.outputs.model-name }}
      aws-region:   ${{ needs.read-config.outputs.aws-region }}
      s3-bucket:    ${{ needs.read-config.outputs.lotus-s3-bucket }}
      model-path:   ${{ needs.read-config.outputs.model-path }}
      project-name: ${{ needs.read-config.outputs.project-name }}
      spec-s3bucket:      ${{ needs.read-config.outputs.spec-s3bucket }}
      aws-account:        ${{ needs.read-config.outputs.aws-account }}
      spec-db-source-name:${{ needs.read-config.outputs.spec-db-source-name }}
      spec-db-corp-name:  ${{ needs.read-config.outputs.spec-db-corp-name }}
      table-name:         ${{ needs.read-config.outputs.table-name }}
      target-delay-days:        ${{ needs.download-artifacts.outputs.target_delay_days }}
      should-run-performance-drift: ${{ needs.download-artifacts.outputs.should_run_performance_drift }}
    secrets: inherit

  ci-python:
    uses: itau-corp/itau-up2-reusable-workflows-ci-python/.github/workflows/ci.yml@v2
    needs: read-config
    strategy:
      matrix:
        app: ${{ fromJson(needs.read-config.outputs.build-working-directory) }}
    with:
      build-working-directory:   ${{ matrix.app }}
      build-python-version:      ${{ needs.read-config.outputs.build-python-version }}
      build-architecture:        ${{ needs.read-config.outputs.build-architecture }}
      build-requirement-path:    ${{ needs.read-config.outputs.build-requirement-path }}
      test-working-directory:    ${{ matrix.app }}
      test-requirement-path:     ${{ needs.read-config.outputs.test-requirement-path }}
      test-disable:              ${{ needs.read-config.outputs.test-disable }}
      publish-deploy-only:       ${{ needs.read-config.outputs.publish-deploy-only }}
      publish-copy-all-dependency: ${{ needs.read-config.outputs.publish-copy-all-dependency }}
      publish-install-dependency-path: ${{ needs.read-config.outputs.publish-install-dependency-path }}
      iupipes-config-path: ".iupipes.yml"
    secrets: inherit

  upload-package:
    uses: itau-corp/itau-up2-reusable-workflows-cd-publish-artifact/.github/workflows/generic.yml@v3
    needs:
      - read-config
      - ci-python
      - build-dependencies
    strategy:
      matrix:
        app: ${{ fromJson(needs.read-config.outputs.build-working-directory) }}
    with:
      promote-environment: dev
      publish-package: true
      build-working-directory: ${{ matrix.app }}
    secrets: inherit

  publish-docker:
    uses: itau-corp/itau-up2-reusable-workflows-ci-container/.github/workflows/build.yml@v3
    needs:
      - upload-package
      - read-config
    strategy:
      matrix:
        app: ${{ fromJson(needs.read-config.outputs.build-working-directory) }}
    with:
      promote-environment: dev
      publish-package: true
      disable-download-package: false
      build-working-directory: ${{ matrix.app }}
      publish-ecr: true
      publish-artifactory: true
      andromeda-repository: ${{ needs.read-config.outputs.publish-andromeda-repository }}
      deploy-aws-dev-account: ${{ needs.read-config.outputs.aws-account }}
      deploy-aws-hom-account: ${{ needs.read-config.outputs.aws-account }}
      deploy-aws-prod-account: ${{ needs.read-config.outputs.aws-account }}
      deploy-aws-region: ${{ needs.read-config.outputs.aws-region }}
      publish-out-path: ${{ github.run_id }}-${{ github.run_attempt }}
      build-docker-platform: ${{ needs.read-config.outputs.build-docker-platform }}
    secrets: inherit

  infra-terraform:
    uses: itau-corp/itau-up2-reusable-workflows-infra-terraform/.github/workflows/build.yml@v2
    needs:
      - upload-package
      - read-config
      - publish-docker
    with:
      environment: dev
      deploy-aws-dev-account: ${{ needs.read-config.outputs.aws-account }}
      deploy-aws-dev-region:  ${{ needs.read-config.outputs.aws-region }}
      infra-terraform-working-directory: infra
      abstract-artifact: false
      infra-terraform-destroy: ${{ needs.read-config.outputs.destroy }}
      infra-terraform-custom-var-flag: "-var-file=inventories/dev/terraform.tfvars -var=sagemaker_image_tag=${{ needs.publish-docker.outputs.artifactversion }}"
      iupipes-config-path: "config.yml"
    secrets: inherit

  deploy-infra-terraform:
    uses: itau-corp/itau-up2-reusable-workflows-infra-terraform/.github/workflows/build.yml@v2
    needs:
      - infra-terraform
      - upload-package
      - read-config
    with:
      environment: dev
      execution-mode: apply
      application-publish: false
      deploy-aws-dev-account: ${{ needs.read-config.outputs.aws-account }}
      deploy-aws-dev-region:  ${{ needs.read-config.outputs.aws-region }}
      abstract-artifact: false
      infra-terraform-working-directory: infra
      infra-terraform-custom-var-flag: "-var-file=inventories/dev/terraform.tfvars -var=sagemaker_image_tag=${{ needs.publish-docker.outputs.artifactversion }}"
      iupipes-config-path: "config.yml"
    secrets: inherit

  taac-dev:
    uses: itau-corp/itau-pg8-reusable-workflows-test-taac/.github/workflows/taac-dev.yml@v1
    needs:
      - read-config
    with:
      environment: dev
    secrets: inherit

  open-pr-to-release-branch:
    needs:
      - deploy-infra-terraform
      - upload-package
    uses: itau-corp/itau-up2-reusable-workflows-common-pull-request/.github/workflows/create.yml@v2
    with:
      origin-branch: develop
      target-create-branch: true
      target-base-branch: main
      target-branch: release/${{ needs.upload-package.outputs.artifact-version }}
    secrets: inherit

  post-deploy:
    needs:
      - deploy-infra-terraform
      - read-config
    uses: ./.github/workflows/2-post-deploy.yml
    with:
      environment: "dev"
      aws-account:      ${{ needs.read-config.outputs.aws-account }}
      aws-account-name: ${{ needs.read-config.outputs.aws-account-name }}
      aws-region:       ${{ needs.read-config.outputs.aws-region }}
      destroy:          ${{ needs.read-config.outputs.destroy }}
      email:            ${{ needs.read-config.outputs.tech-team-email }}
      pipeline-type:    ${{ needs.read-config.outputs.pipeline-type }}
      pipeline-version: ${{ needs.read-config.outputs.pipeline-version }}
      project-name:     ${{ needs.read-config.outputs.project-name }}
      status:           ${{ needs.deploy-infra-terraform.result }}
      timestamp:        ${{ needs.read-config.outputs.timestamp }}
      experiment-id:    ${{ needs.read-config.outputs.experiment-id }}
      mrm-id:           ${{ needs.read-config.outputs.id-mrm }}
    secrets: inherit
