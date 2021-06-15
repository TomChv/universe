setup() {
    load 'helpers'

    common_setup
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: go" {
    "$DAGGER" compute "$TESTDIR"/stdlib/go --input-dir TestData="$TESTDIR"/stdlib/go/testdata
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: kubernetes" {
    skip_unless_local_kube

    "$DAGGER" init
    dagger_new_with_plan kubernetes "$TESTDIR"/stdlib/kubernetes/

    run "$DAGGER" input -e "kubernetes" secret kubeconfig -f ~/.kube/config
    assert_success

    run "$DAGGER" up -e "kubernetes"
    assert_success
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: kustomize" {
    "$DAGGER" compute "$TESTDIR"/stdlib/kubernetes/kustomize --input-dir TestKustomize.kustom.source="$TESTDIR"/stdlib/kubernetes/kustomize/testdata
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: helm" {
    skip "helm is broken"
    skip_unless_local_kube

    "$DAGGER" init
    dagger_new_with_plan helm "$TESTDIR"/stdlib/kubernetes/helm

    run "$DAGGER" input -e "helm" secret kubeconfig -f ~/.kube/config
    assert_success

    cp -R "$TESTDIR"/stdlib/kubernetes/helm/testdata/mychart "$DAGGER_WORKSPACE"/testdata
    run "$DAGGER" input -e "helm" dir TestHelmSimpleChart.deploy.chartSource "$DAGGER_WORKSPACE"/testdata
    assert_success

    run "$DAGGER" up -e "helm"
    assert_success
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: docker: build" {
    "$DAGGER" compute "$TESTDIR"/stdlib/docker/build/ --input-dir source="$TESTDIR"/stdlib/docker/build
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: docker: dockerfile" {
    "$DAGGER" compute "$TESTDIR"/stdlib/docker/dockerfile/ --input-dir source="$TESTDIR"/stdlib/docker/dockerfile/testdata
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: docker: push-and-pull" {
    skip_unless_secrets_available "$TESTDIR"/stdlib/docker/push-pull/inputs.yaml

    # check that they succeed with the credentials
    run "$DAGGER" compute --input-yaml "$TESTDIR"/stdlib/docker/push-pull/inputs.yaml --input-dir source="$TESTDIR"/stdlib/docker/push-pull/testdata "$TESTDIR"/stdlib/docker/push-pull/
    assert_success
}

# FIXME: move to universe/universe.bats
# Assigned to: <ADD YOUR NAME HERE>
@test "stdlib: terraform" {
    skip_unless_secrets_available "$TESTDIR"/stdlib/terraform/s3/inputs.yaml

    "$DAGGER" init
    dagger_new_with_plan terraform "$TESTDIR"/stdlib/terraform/s3

    cp -R "$TESTDIR"/stdlib/terraform/s3/testdata "$DAGGER_WORKSPACE"/testdata
    "$DAGGER" -e terraform input dir TestData "$DAGGER_WORKSPACE"/testdata
    sops -d "$TESTDIR"/stdlib/terraform/s3/inputs.yaml | "$DAGGER" -e "terraform" input yaml "" -f -

    # it must fail because of a missing var
    run "$DAGGER" up -e terraform
    assert_failure

    # add the var and try again
    "$DAGGER" -e terraform input text TestTerraform.apply.tfvars.input "42"
    run "$DAGGER" up -e terraform
    assert_success

    # ensure the tfvar was passed correctly
    run "$DAGGER" query -e terraform \
        TestTerraform.apply.output.input.value  -f text
    assert_success
    assert_output "42"

    # ensure the random value is always the same
    # this proves we're effectively using the s3 backend
    run "$DAGGER" query -e terraform \
        TestTerraform.apply.output.random.value  -f json
    assert_success
    assert_output "36"
}
