Reliablility is our main goal. So what if I told you we can ensure everything running in our cluster can be predicted?

Not only predict, but protect. We can make sure whatever changes in the cluster couldn't be made without proper review.

# The problem
1. Production is not protected if you can touch it without review.
2. If your changes aren't on code, they aren't reliable.
3. We can't build businesses with vendor lock in.

# How to solve it
1. GitOps
2. IaC
3. Agnostic approach

For IaC, we can create a cluster using terraform or terragrunt, which by default are agnostic tools.
For GitOps, we are introducing ArgoCD, which is an agnostic tool to help us on the deployment.

Both tools and kubernetes can be used not only in any cloud but also locally. For learning purpose, I'm choosing this stack:
- Azure: AKS
- Terraform
- ArgoCD

I've made a POC which code you can find in this repo https://github.com/mateusclira/gitops-argocd-k8s

The project consists in 2 phases. First one is creating the environment infrastructure. Then we connect into the cluster created, and bootstrapply create the ArgoCD. After that, enjoy looking at things being created automatically :)

Normally, in production, we would create an infrastructure repository separated from the ArgoCD. Here, I've created both in the same place. Notice that ArgoCD has the power to create repo, and should have all the powers in our GitHub. Normally, it would be using a GitHub Enterprise Application, here I created a PAT.

It is also worth to clarify that using this architecture won't impact on Developers experience. They won't need to learn anything or change their processes.

# Advantages on this approach
- Everything is on code. It is possible to implement Code review on kubernetes changes
- Easier to prevent errors in production, since we are copying the exact same behavior from other environments
- Reduced costs due to more understanding on our resources
- Enhanced reliability, since manual changes won't happen
- Enhanced security, for the same reason as above
- Increased speed on deployments, because when developers make changes on git, ArgoCD will get it and update the Kubernetes
- Easier to rollback, because we can rollback the git commit

# Downsides
- The SRE team must have scripting knowledge
- Creating Helm Charts for every application can be not too straightforward
- Managing secrets is another thing we should do carefully, and the DevOps culture should be implemented to bring Devs close to Ops team
- It is better to have one cluster per environment, and this is not fit for every client

# Now let's get it done

Let's clone the repo, log into Azure and create the infrastructure
```bash
git clone https://github.com/mateusclira/gitops-argocd-k8s.git
```

```bash
az login
```

```bash
cd infrastructure
```

```bash
terraform init
```

```bash
terraform plan
```

Validate if you got a plan like this, then apply. Validate if you have both **Contributor** and **Role Based Access Control Administrator** roles

```bash
terraform apply
```

Once you have the infrastructure created, you will need to connect with the cluster. You can do it using this command:

```bash
az aks get-credentials --resource-group platform-company --name k8s-company-dev --overwrite-existing
```

Now, we are ready to move into our configuration repo.

We need to configure a file named .sops.yaml that is going to be on the root of the repo. It gets the key to encrypt/decrypt in the cluster.
(Read more about SOPS [here](https://blog.gitguardian.com/a-comprehensive-guide-to-sops/) and about declarative SOPS [here](https://getsops.io/docs/#using-sopsyaml-conf-to-select-kms-pgp-and-age-for-new-files))

```bash
creation_rules:
  - path_regex: .*/dev/.*
    azure_keyvault: https://[name-of-kv].azure.net/keys/[key-name]/[key-version]
    encrypted_regex: "^(data|stringData|global|apiKey|cfToken|privatekey|publickey)$"
```

To manually encrypt, we should have sops installed
```bash
brew install sops
```

Then we use the command
```bash
sops -e bootstrap/overlay/dev/argo-repo-creds.yaml > bootstrap/overlay/dev/argo-repo-creds.enc.yaml
```
to encrypt our credentials for the repository. Here goes the credentials that ArgoCD is going to use to automatically connect on GitHub once created. The decrypted file shouldn't ever go to git, that is why you won't find it on git, but I'm putting it here as follows:

```bash
apiVersion: v1
kind: Secret
metadata:
    name: argo-repo-creds
    namespace: argocd
    labels:
      argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
    type: git
    url: https://github.com/mateusclira/gitops-argocd-k8s
    username: mateusclira
    password: you_should_use_a_PAT_here

# For a real project, we should use under the stringData an url (github's url), create a github app, and then use:
# githubAppID (should be the app id of the github app)
# githubAppInstallationID (should be the installation id of the github app)
# githubAppPrivateKey (should be the private key of the github app)
# url (should be the github's url)
# type (should be github)
```
If you did everything correctly until this far, after running the sops command, you should generate a file like this:

```bash
apiVersion: v1
kind: Secret
metadata:
    name: argo-repo-creds
    namespace: argocd
    labels:
        argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
    type: ENC[AES256_GCM,data:gBiw,iv:4cYV4fodi/T9F99jYSI7b/9yvSOPcdTLEJ9GUlkBNeY=,tag:2XX5dPMne7TFrTsKUASf/Q==,type:str]
    url: ENC[AES256_GCM,data:bTT1AkyY2i6GMvAH5zYawpSv9ZshXQl6j+n65jDtnGInQO3Nnd4YmEEw,iv:5nj/gVofqKw+0mEGRZ6HxXhvv/3jNwSIZN/3xJzIdnE=,tag:6qolWhkYvZJJVOkW7jGnxw==,type:str]
    username: ENC[AES256_GCM,data:4YuO7uHTu7wTouU=,iv:eNnEqUKn6dNEN7dOThYRHv7xZ9R5Y8wqlym9Idgc6zY=,tag:THSub1tXK+h+sBTfMM7C/Q==,type:str]
    password: ENC[AES256_GCM,data:/C5GnG7hUGu3lgKBiqEh1SgsSKxGhMoxZ8WiXSu6GInkYArIC0n8Fw==,iv:iv+JVKqIor70lhVxjSzzFOIMPZFqAU4R3gMMZhngdKw=,tag:epjjOGj7sLLrxIDJ8pYWfw==,type:str]
# For a real project, we should use under the stringData an url (github's url), create a github app, and then use:
# githubAppID (should be the app id of the github app)
# githubAppInstallationID (should be the installation id of the github app)
# githubAppPrivateKey (should be the private key of the github app)
# url (should be the github's url)
# type (should be github)

sops:
    kms: []
    gcp_kms: []
    azure_kv:
        - vault_url: https://kv-company.vault.azure.net
          name: kms-company
          version: 68dc9b86590d40ea9265323b2dd0cd46
          created_at: "2024-10-03T21:02:46Z"
          enc: ODeusDgnhLxSpxIQwsCcPpKYwg5FsicDqQ8LEOHrwTd7snwtp1odBSXpDJV_wW_dXDYgCmV5ERS775fiz-W1vu7eYZjkBPun-u2So6tLPtrNtiYyy2QoD8URluxlJRrZ-ocMRLQecFlb00hHI-SUechtR29ABy21Y9n33e-PYLHQaojmesAIpjl-i6CHGD5QfseqsL7i6M8w9c5g8FtrTMUu1QgngazomNz884ggnn71-QIgroud9NE249gbWKBUgcDwbF3NlNhD89H5H-zdNExCJYAfdTBfHXVfbsFghP_cHFty7J_bwCWK9QOg-UnNmCDPH_wuE5F_ZuUDfpipMg
    hc_vault: []
    age: []
    lastmodified: "2024-10-03T21:02:49Z"
    mac: ENC[AES256_GCM,data:S0T4h67dF6saWA1LCAmIOGY5f0oyb+JiCLtx1FqGt0ZqzKxaiV7xjRkT1cZsAVQQoGGSqXPm7R7QHKPELZ/DrlVwffb80IXcpkjJONItqZwV/L0D3uTHF50dtVpaBMJf1z5QZ1ioCfsXO+7n8lw7HU2Bt4UGq9gBo1/7iUZpn/Q=,iv:ycDIyc+MOjY181NWA/e0wGtd+PSc6eu7P9k15yxJ0hE=,tag:ocLoSCAhUt711z8ivDjNAA==,type:str]
    pgp: []
    encrypted_regex: ^(data|stringData|global|apiKey|cfToken|privatekey|publickey)$
    version: 3.9.0
```

Now, let's look at our kustomization.yaml file inside bootstrap/overlay/dev. 
Here you are defining everything about the environment. On the other hand, in the bases, you define literally the base of all applications. 
On the bootstrap/bases/argocd/application-set.yaml, you create a generic ApplicationSet. Each application is created obeying the rules we define in this "bases", and in Overlay, we define extra changes, for each environment.

This behavior goes for all the files under bases. Look for example ingress.yaml in bases/argocd. There, we have at lines 15 and 17 "change-me" which is a placeholder. What that means is the bases creates a base and the overlay will overwrite this "change-me" with the host value.

In our kustomization.yaml file from overlay/dev, we see in line 19 a target for ingress, selecting the exact path we should replace, and the new value for the host. I'm using our azure-boostrapper DNS Zone in azure to do this demo. We have this Public DNS Zone there so you can also use it.

Now, you need to install ksops and kustomize.

```bash
brew install ksops
```
Ksops is a plugin that Kustomize uses to use Sops in Kubernetes

```bash
brew install kustomize
```
Kustomize is going to build and launch the ArgoCD into the Cluster.

*If you have problems with ksops instalation, do this: (if not, go ahead)
```bash
mkdir -p $HOME/.config/kustomize/plugin/viaduct.ai/v1/ksops
ln -s $(which ksops) $HOME/.config/kustomize/plugin/viaduct.ai/v1/ksops/ksops
chmod +x $HOME/.config/kustomize/plugin/viaduct.ai/v1/ksops/ksops
unset KUSTOMIZE_PLUGIN_HOME
export KUSTOMIZE_PLUGIN_HOME=$HOME/.config/kustomize/plugin
echo $KUSTOMIZE_PLUGIN_HOME
```
Remember to verify if your KUSTOMIZE_PLUGIN_HOME has the correct patch (kustomize/plugin)

___

# Now it is time! Let's install ArgoCD

While in the root on terminal (gitops-argocd-k8s), run this:
```bash
kustomize build bootstrap/overlay/dev --enable-alpha-plugins --enable-exec | kubectl apply -f -
```

Resources are going to start to be created. If by any chance you receive an CRD error in the end, just run it again. Sometimes during the first run, it doesn't have time to recognize the CRDs that has been installed few seconds before.

If you did everything correct, you should see instantaneously the argocd, then addons being created. 

# How it happens? 

    1. Doing the bootstrap, you are also configuring the connection between ArgoCD and GitHub.
        a. This means the moment you run the kustomize command, you don't need to do anything else

    2. After the bootstrap, ArgoCD starts looking at GitHub every 3 minutes (by default)
        a. In our application-set.yaml we set that whatever is in git, should be in k8s
        b. this is the concept of GitOps

    3. So from now on, to install a new tool into the cluster, you need a helm chart
        a. You just put a folder inside addons, or create a services folder
        b. You need to put a folder named "dev" since we are using dev.
        c. We can change it in .sops.yaml, it is looking for */dev/*

    4. If you try to remove the dev folder inside any addons
        a. example, remove dev from cert-manager
        b. you will notice k8s will uninstall it
        c. after 3 minutes, because ArgoCD will trigger it.

    5. This way, we can manage every resources using Code.
        a. no matter if infrastructure or deployments.

Now please feel free to connect on your new argocd URL https://argocd.azure-bootstrapper.internal.company.com/

But hey, you don't have the creds... :)

The first one is admin, while the second you need a command. It is in a secret on argocd. To retrieve it use this command:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
