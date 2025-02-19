# action-kubectl

GitHub Action for interacting with kubectl ([k8s](https://kubernetes.io))

## Usage

To use kubectl put this step into your workflow:

### Authentication Methods

This action allows authentication using different methods. Note that all input arguments can also be specified by environment variables. See the\*\* Available Inputs\*\* section below for more info.

#### 1. Using a Kubeconfig File

First, you can authenticate using a kubeconfig file.

```yaml
- uses: jakecabrera/action-kubectl@main
  with:
    kube_config: ${{ secrets.KUBE_CONFIG }}
    args: get pods
```

Alternatively, if you are storing the kubeconfig content in an environment variable:

```yaml
- uses: jakecabrera/action-kubectl@main
  env:
    KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
  with:
    args: get pods
```

The `kube_config` input takes precedence over the `KUBE_CONFIG` environment variable if both are set.

The value of this variable should be a base64 encoded kube config file.

An example of getting the kube config file as base64: `cat $HOME/.kube/config | base64`.



#### 2. Using Credentials (Username & Password)

```yaml
- uses: jakecabrera/action-kubectl@main
  with:
    kube_host: ${{ secrets.KUBE_HOST }}
    kube_certificate: ${{ secrets.KUBE_CERTIFICATE }}
    kube_username: ${{ secrets.KUBE_USERNAME }}
    kube_password: ${{ secrets.KUBE_PASSWORD }}
    args: get pods
```

#### 3. Using a Bearer Token

```yaml
- uses: jakecabrera/action-kubectl@main
  with:
    kube_host: ${{ secrets.KUBE_HOST }}
    kube_certificate: ${{ secrets.KUBE_CERTIFICATE }}
    kube_token: ${{ secrets.KUBE_TOKEN }}
    args: get pods
```

### Displaying and Redirecting Output

By default, the action displays the command output in the logs. However, in some cases, you may want to suppress the output, such as when handling sensitive data like secrets, internal resource names, or other confidential information.

Additionally, you can choose to display the fully built command before execution. This is useful for debugging but may expose sensitive arguments or environment variables in the logs.

If security is a concern, consider setting `display_results` or `display_command` to `false`.

```yaml
- uses: jakecabrera/action-kubectl@main
  with:
    args: get deployments -o jsonpath={.items[0].metadata.name}
    output_variable: DEPLOYMENT_NAME
    display_results: "false"
```

## Handling Environment Variables in Arguments

When passing arguments to `kubectl` via the `args` input, note that environment variables **will be expanded** within the argument string. This means that referencing an environment variable directly within `args` will work as expected.

### Correct Usage

Use GitHub Actions' context syntax to properly pass environment variables:

```yaml
- name: Restart deployment
  uses: jakecabrera/action-kubectl@main
  with:
    args: rollout restart $NON_PRODUCTION_DEPLOYMENT
```

## Available Inputs

| Input             | Description                                                                                          | Default |
| ----------------- | ---------------------------------------------------------------------------------------------------- | ------- |
| args              | Arguments for the CLI command                                                                        | None    |
| output\_variable  | Environment variable name to save output to (optional)                                               | None    |
| display\_results  | Whether or not to show output of command                                                             | "true"  |
| display\_command  | Whether or not to show the fully built command before execution                                      | "true"  |
| kube\_config      | Base64-encoded kubeconfig file content (defaults to KUBE\_CONFIG environment variable)               | None    |
| kube\_host        | Kubernetes API server host (defaults to KUBE\_HOST environment variable)                             | None    |
| kube\_certificate | Base64-encoded Kubernetes certificate authority (defaults to KUBE\_CERTIFICATE environment variable) | None    |
| kube\_username    | Kubernetes username (defaults to KUBE\_USERNAME environment variable)                                | None    |
| kube\_password    | Kubernetes password (defaults to KUBE\_PASSWORD environment variable)                                | None    |
| kube\_token       | Kubernetes API token (defaults to KUBE\_TOKEN environment variable)                                  | None    |

## Example Workflows

### Basic pod listing

```yaml
name: Get pods
on: [push]

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest

    steps:
      - uses: jakecabrera/action-kubectl@main
        with:
          kube_config: ${{ secrets.KUBE_CONFIG }}
          args: get pods
```

### Running kubectl with output redirection

```yaml
name: Get deployment name
on: [push]

jobs:
  get-deployment:
    name: Retrieve deployment name
    runs-on: ubuntu-latest

    steps:
      - uses: jakecabrera/action-kubectl@main
        with:
          args: get deployments -o jsonpath={.items[0].metadata.name}
          output_variable: DEPLOYMENT_NAME
          display_results: "false"

      - run: echo "Deployment name is $DEPLOYMENT_NAME"
```

## Versioning

To use a specific version of this action, reference the tag in your workflow:

```yaml
- uses: jakecabrera/action-kubectl@v2
  with:
    kube_config: ${{ secrets.KUBE_CONFIG }}
    args: get pods
```

## License

[MIT License](https://github.com/jakecabrera/action-kubectl/blob/main/LICENSE)


## Attribution

This project is based on and incorporates code from [actions-hub/kubectl](https://github.com/actions-hub/kubectl), which is also licensed under the MIT License.
