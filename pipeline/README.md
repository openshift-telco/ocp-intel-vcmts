# OpenShift Pipeline

## Authentication to git repository
In order for the pipeline to authenticate to the Github repository, you must provide have a key-pair with the public key in your Github account, and load the private key into the OpenShift project.

See the `github-auth-secret_EXAMPLE.yaml` and replace `YOUR_BASE64_ENCODED_PRIVATE_KEY` with your encoded private key.

## Authentication to internal image registry

~~~
oc policy add-role-to-user registry-editor -z pipeline -n vcmts-build
~~~

## Pipeline parameters
The pipeline supports the following parameters, with their according default value.
Cuztomize as needed.

    - default: 'http-server.vcmts-build:8080'
      name: HTTP_SERVER
      type: string
    - default: 21.10.0
      description: Intel VCMTS package version
      name: VCMTS_VERSION
      type: string
    - default: 'image-registry.openshift-image-registry.svc:5000'
      name: REGISTRY_URL
      type: string
