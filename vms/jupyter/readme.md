- [Creating  a JupyterHub on Jetstream with the Zero to JupyterHub Project](#h-D73CBC56)
  - [Kubernetes Cluster](#h-65F9358E)
    - [jupyterhub.sh](#h-B56E19AB)
    - [Create Cluster](#h-2FF65549)
  - [unidata/unidatahub Docker Container](#h-CD007D2A)
  - [Configure and Deploy the JupyterHub](#h-E5CA5D99)
    - [Letsencrypt versus Certificate from a Certificate Authority](#h-294A4A20)
    - [OAuth Authentication](#h-8A3C5434)
    - [unidata/unidatahub](#h-214D1D4C)
  - [Navigate to JupyterHub](#h-209E2FBC)
  - [Tearing Down JupyterHub](#h-1E027567)
    - [Total Destructive Tear Down](#h-A69ADD92)
    - [Tear Down While Preserving User Volumes](#h-5F2AA05F)
  - [Troubleshooting](#h-0E48EFE9)
    - [Unresponsive JupyterHub](#h-FF4348F8)
    - [Volumes Stuck in Reserved State](#h-354DE174)



<a id="h-D73CBC56"></a>

# Creating  a JupyterHub on Jetstream with the Zero to JupyterHub Project


<a id="h-65F9358E"></a>

## Kubernetes Cluster


<a id="h-B56E19AB"></a>

### jupyterhub.sh

`jupyterhub.sh` and the related `z2j.sh` are convenience scripts similar to `openstack.sh` to give you access to a pre-configured environment that will allow you to build and/or run a Zero to JupyterHub cluster. It also relies on the [same Docker container](../../openstack/readme.md) as the `openstack.sh` script. `jupyterhub.sh` takes one argument with the `-n` option, the name of the Zero to JupyterHub cluster. Invoke it from the `science-gateway/openstack` directory. `jupyterhub.sh` and the related `z2j.sh` ensure the information for this Zero to JupyterHub cluster is persisted outside the container via Docker file mounts &#x2013; otherwise all the information about this cluster would be confined in memory inside the Docker container. The vital information will be persisted in a local `jhub` directory.


<a id="h-2FF65549"></a>

### Create Cluster

[Create a Kubernetes cluster](../../openstack/readme.md) with the desired number of nodes and VM sizes. Lock down the master node of the cluster per Unidata security procedures. Work with sys admin staff to obtain a DNS name (e.g., jupyterhub.unidata.ucar.edu), and a certificate from a certificate authority for the master node.


<a id="h-CD007D2A"></a>

## unidata/unidatahub Docker Container

Build the Docker container in this directory and push it to dockerhub.

```sh
docker build -t unidata/unidatahub:`openssl rand -hex 6` . > /tmp/docker.out 2>&1 &
docker push unidata/unidatahub:<container id>
```


<a id="h-E5CA5D99"></a>

## Configure and Deploy the JupyterHub

From the client host where you created the Kubernetes cluster, follow [Andrea Zonca's instructions](https://zonca.dev/2020/06/kubernetes-jetstream-kubespray.html#install-jupyterhub).

After you have created the `secrets.yaml` as instructed, customize it with the choices below


<a id="h-294A4A20"></a>

### Letsencrypt versus Certificate from a Certificate Authority

1.  Letsencrypt

    Follow [Andrea's instructions](https://zonca.github.io/2018/09/kubernetes-jetstream-kubespray-jupyterhub.html) on setting up letsencrypt along with this yaml snippet below. Replace the hostname where appropriate.

    ```yaml
    ingress:
      enabled: true
      annotations:
        kubernetes.io/tls-acme: "true"
      hosts:
        - <jupyterhub-host>
      tls:
          - hosts:
             - <jupyterhub-host>
            secretName: certmanager-tls-jupyterhub
    ```

2.  Certificate from CA

    Work with sys admin staff to obtain a certificate from a CA.

    Follow [Andrea's instructions](https://zonca.github.io/2018/09/kubernetes-jetstream-kubespray-jupyterhub.html) on setting up HTTPS with custom certificates. Note that when adding the key with

    ```shell
    kubectl create secret tls <cert-secret> --key ssl.key --cert ssl.crt -n jhub
    ```

    supply the base and intermediate certificates and not the full chain certificate (i.e., with root certificates).

    Here is a snippet of what the ingress configuration will look like in the `secrets.yaml`.

    ```yaml
    ingress:
      enabled: true
      annotations:
        kubernetes.io/tls-acme: "true"
      hosts:
        - <jupyterhub-host>
      tls:
          - hosts:
             - <jupyterhub-host>
            secretName: <secret_name>
    ```


<a id="h-8A3C5434"></a>

### OAuth Authentication

1.  Globus

    [Globus OAuth capability](https://developers.globus.org/) is available for user authentication. The instructions [here](https://github.com/jupyterhub/oauthenticator#globus-setup) are relatively straightforward.

    ```yaml
    auth:
      type: globus
      globus:
        clientId: "xxx"
        clientSecret: "xxx"
        callbackUrl: "https://<jupyterhub-host>:443/oauth_callback"
        identityProvider: "xsede.org"
      admin:
        users:
          - adminuser1
    ```

2.  GitHub

    Setup an OAuth app on GitHub

    ```yaml
    auth:
      type: github
      github:
        clientId: "xxx"
        clientSecret: "xxx"
        callbackUrl: "https://<jupyterhub-host>:443/oauth_callback"
      admin:
        users:
          - adminuser1
    ```


<a id="h-214D1D4C"></a>

### unidata/unidatahub

Add the Unidata JupyterHub configuration (`unidata/unidatahub`) and related items (e.g., pulling of Unidata Python projects). Customize the desired CPU / RAM usage. [This spreadsheet](https://docs.google.com/spreadsheets/d/15qngBz4L5gwv_JX9HlHsD4iT25Odam09qG3JzNNbdl8/edit?usp=sharing) will help you determine the size of the cluster based on number of users, desired cpu/user, desired RAM/user. Duplicate it and adjust it for your purposes.

```yaml
singleuser:
  extraEnv:
    NBGITPULLER_DEPTH: "0"
  storage:
    capacity: 3Gi
  startTimeout: 600
  memory:
    guarantee: 4G
    limit: 4G
  cpu:
    guarantee: 1
    limit: 2
  defaultUrl: "/lab"
  image:
    name: unidata/unidatahub
    tag: 82a23cf7a286
  lifecycleHooks:
    postStart:
      exec:
          command:
            - "sh"
            - "-c"
            - >
              gitpuller https://github.com/Unidata/python-training main python-training;
              cp /README_FIRST.ipynb /home/jovyan;
```


<a id="h-209E2FBC"></a>

## Navigate to JupyterHub

In a web browser, navigate to your newly minted JupyterHub and see if it is as you expect.


<a id="h-1E027567"></a>

## Tearing Down JupyterHub


<a id="h-A69ADD92"></a>

### Total Destructive Tear Down

Tearing down the JupyterHub including user OpenStack volumes is possible. From the Helm and Kubernetes client:

```sh
helm uninstall jhub -n jhub
# Think before you type !
echo $CLUSTER; sleep 60; kubectl delete namespace jhub
```

To further tear down the Kubernetes cluster see [Tearing Down the Cluster](../../openstack/readme.md).


<a id="h-5F2AA05F"></a>

### Tear Down While Preserving User Volumes

A gentler tear down that preserves the user volumes is described in [Andrea's documentation](https://zonca.github.io/2018/09/kubernetes-jetstream-kubespray-jupyterhub.html). See the section on "persistence of user data".


<a id="h-0E48EFE9"></a>

## Troubleshooting


<a id="h-FF4348F8"></a>

### Unresponsive JupyterHub

1.  Preliminary Work

    If a JupyterHub becomes unresponsive (e.g., 504 Gateway Time-out), login in to the Kubernetes client and do preliminary backup work in case things go badly. First:

    ```shell
    kubectl get pvc -n jhub -o yaml > pvc.yaml.ro
    kubectl get pv -n jhub -o yaml > pv.yaml.ro
    chmod 400 pvc.yaml.ro pv.yaml.ro
    ```

    Make `pvc.yaml.ro` `pv.yaml.ro` read only since these files could become precious in case you have to do data recovery for users. More on this subject below.

2.  Delete jhub Pods

    Next, start investigating by issuing:

    ```shell
    kubectl get pods -n jhub
    ```

    this command will yield something like

    ```shell
    NAME                      READY   STATUS    RESTARTS   AGE
    hub-5bdccd4784-lzw87      1/1     Running   0          17h
    jupyter-joe               1/1     Running   0          4h51m
    proxy-7b986cdb75-mhl86    1/1     Running   0          29d
    ```

    Now start deleting the `jhub` pods starting with the user pods (e.g., `jupyter-joe`).

    ```
    kubectl delete pod <pod name> -n jhub
    ```

    Check to see if the JupyterHub is reachable. If it is not, keep deleting pods checking for reachability after each pod deletion.

3.  Delete jhub, But Do Not Purge Namespace

    If the JupyterHub is still not reachable, you can try deleting and recreating the JupyterHub but **do not** delete the namespace as you will wipe out user data.

    ```shell
    helm uninstall jhub -n jhub
    # But DO NOT issue this command
    # kubectl delete namespace jhub
    ```

    Then try reinstalling with

    ```
    bash install_jhub.sh
    ```

    Now, try recover user volumes as [described at the end of the section here](https://zonca.dev/2018/09/kubernetes-jetstream-kubespray-jupyterhub.html#delete-and-recreate-openstack-instances) with the `pvc.yaml.ro` `pv.yaml.ro` saved earlier (make writable copies of those `ro` files). If that still does not work, you can try destroying the entire cluster and recreating it as described in that same link.


<a id="h-354DE174"></a>

### Volumes Stuck in Reserved State

1.  Background

    Occasionally, when logging into a JupyterHub the user will encounter a volume attachment error that causes a failure in the login process. [This is an ongoing issue on Jetstream that we have never been able to get to the bottom of](https://github.com/zonca/jupyterhub-deploy-kubernetes-jetstream/issues/40). The user will see an error that looks something like:

    ```shell
    2020-03-27 17:54:51+00:00 [Warning] AttachVolume.Attach failed for volume "pvc-5ce953e4-6ad9-11ea-a62a-fa163ebb95dd" : Volume "0349603a-967b-44e2-98d1-0ba1d42c37d8" is attaching, can't finish within the alloted time
    ```

    When you then do an `openstack volume list`, you will see something like this where a volume is stuck in "reserved":

    ```shell
    |--------------------------------------+------------------------------------------+----------|
    | ID                                   | Name                                     | Status   |
    |--------------------------------------+------------------------------------------+----------|
    | 25c25c5d-75cb-48fd-a9c4-4fd680bea79b | pvc-41d76080-6ad7-11ea-a62a-fa163ebb95dd | reserved |
    |--------------------------------------+------------------------------------------+----------|
    ```

    You (or if you do not have permission, Jetstream staff) can reset the volume with:

    ```shell
    openstack volume set --state available <volume uuid>
    ```

    or with

    ```shell
    openstack volume list | grep -i reserved | awk \
        'BEGIN { FS = "|" } ; { print $2 }' | xargs -n1 openstack volume set \
    --state available
    ```

    The problem is that once a volume gets stuck like this, it tends to happen again and again. In this scenario, [you have to provide a long term solution to the user](#h-CB601D7B).

2.  Script to Mitigate Problem

    Invoking this script (e.g., call it `notify.sh`) from crontab, maybe every three minutes or so, can help mitigate the problem and give you faster notification of the issue. Note [iftt](https://ifttt.com) is a push notification service with webhooks available that can notify your smart phone triggered by a `curl` invocation as demonstrated below. You'll have to create an ifttt login and download the app on your smart phone.

    ```shell
    #!/bin/bash

    source /home/centos/.bash_profile

    VAR=$(openstack volume list -f value -c ID -c Status | grep -i reserved | wc -l)

    MSG="Subject: Volume Stuck in Reserved on Jetstream"

    if [[ $VAR -gt 0 ]]
    then
        echo $MSG | /usr/sbin/sendmail my@email.com
        openstack volume list | grep -i reserved >> /tmp/stuck.txt
        curl -X POST https://maker.ifttt.com/trigger/jetstream/with/key/xyz
        openstack volume list -f value -c ID -c Status | grep -i reserved | awk \
            '{ print $1 }' | xargs -n1 openstack volume set --state available
    fi
    ```

    you can invoke this script from crontab:

    ```shell
    */3 * * * * /home/centos/notify.bash > /dev/null 2>&1
    ```

    Note, again, this is just a temporary solution. You still have to provide a longer-term workaround described in the next section:

3.  Not a Solution but a Longer Term Workaround

    [With the volume ID obtained earlier](#h-1765D7EB), issue:

    ```shell
    cinder attachment-list  | grep -i d910c7fae38b
    ```

    which will yield something like:

    ```shell
    WARNING:cinderclient.shell:API version 3.62 requested,
    WARNING:cinderclient.shell:downgrading to 3.55 based on server support.
    | 67dbf5c3-c190-4f9e-a2c9-78da44df6c75 | cf1a7adf-7b0a-422f-8843-d910c7fae38b | reserved  | 0593faaf-8ba0-4eb5-84ad-b7282ce5aac2 |
    ```

    At this point, you may see *two* entries (even though only one is shown here). One attachment in reserved and one that is attached.

    Next, delete the reserved attachment:

    ```shell
    cinder attachment-delete 67dbf5c3-c190-4f9e-a2c9-78da44df6c75
    ```
