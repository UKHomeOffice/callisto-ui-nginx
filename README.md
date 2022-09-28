# Nginx S3 Gateway

## Introduction

This project uses https://github.com/nginxinc/nginx-s3-gateway which proxies requests through to an AWS S3 bucket

The Dockerfile pulls the opensource version specified, creates a non root user 1001 and provides owner permissions to the necessary Nginx config files so that these can be overwritten during deployment.

Being able run the image as a non root user was the driver for this project.

Drone is used to build and deploy the image to a private repository in AWS ECR.

## To build the image
```
docker build -t nginx-s3-gateway .
```
## To run the image
1. Create a .settings file and add the environment variables show below with your AWS S3 settings and preferred proxy configuration.
For more information on the environment variables, see the [official docs](https://github.com/nginxinc/nginx-s3-gateway/blob/master/docs/getting_started.md#configuration)
```
S3_BUCKET_NAME=my-bucket-name
S3_ACCESS_KEY_ID=AWS123POIUYTREWQ
S3_SECRET_KEY=lkjHgfdsA/mNbvcxz
S3_SERVER=s3.region.amazonaws.com
S3_SERVER_PORT=443
S3_SERVER_PROTO=https
S3_REGION=region
S3_STYLE=virtual
S3_DEBUG=true
AWS_SIGS_VERSION=4
ALLOW_DIRECTORY_LIST=false
PROXY_CACHE_VALID_OK=60m
PROXY_CACHE_VALID_NOTFOUND=1m
PROXY_CACHE_VALID_FORBIDDEN=30s
PROVIDE_INDEX_PAGE=true
APPEND_SLASH_FOR_POSSIBLE_DIRECTORY=false

```



2. In order to run the image the default port (80) needs to be overridden in default.conf to a higher port number such as 8080. This can be done by changing [default.conf.template](https://github.com/nginxinc/nginx-s3-gateway/blob/master/common/etc/nginx/templates/default.conf.template) and mounting the new file. 
```
server {
    
    listen 8080;        
    ...
}

```
3. In addition the default user nginx in [nginx.conf](https://github.com/nginxinc/nginx-s3-gateway/blob/master/common/etc/nginx/nginx.conf) (line 1) can be removed and this file also mounted. 

4. The image can then be run with the mounted files as below or using [volume mounts](https://kubernetes.io/docs/concepts/storage/volumes/) in something like Kubernetes 

```
docker run -v $(PWD)/default.conf.templates:/etc/nginx/templates/default.conf.templates -v $(PWD)/nginx.conf:/etc/nginx/nginx.conf --env-file ./settings --publish 8080:8080 --name nginx-s3-gateway
```

## To update the image version
1. Change the nginx-oss-s3-gateway version in the Dockfile
```
FROM ghcr.io/nginxinc/nginx-s3-gateway/nginx-oss-s3-gateway:latest-20220623
```
2. Add the same version to the Drone.yml environment variable
```
# Drone.yml

environment:
    VERSION: latest-20220623
```
3. Git tag & push using the same version
```
# Git commands

git tag latest-20220623 

git push origin latest-20220623
```

When pushing to the Git repository the image will be built by Drone, and when tagging & pushing the image will be deployed to the private AWS ECR repository: callisto/nginx-s3-gateway

## Additional customisation
Since you can override the default.conf.template you can make many adjustments to how your application handles the proxying of requests to AWS S3. For example, rather than using the default implementation which reads the URI path in order to construct the AWS S3 bucket URL, this could be read from the host sub-domain using a regular expression. 
```
map $host $subdomain {
    ~^(?<p1>.+)\.[^\.]+\.[^\.]+$ $p1;    
}
--
set $uri_path       "$subdomain/$request_uri";
```
Also, since the majority of the [AWS S3 configuration](https://github.com/nginxinc/nginx-s3-gateway/blob/master/common/etc/nginx/include/s3gateway.js) is written in [njs (a version of JavaScript)](https://nginx.org/en/docs/njs/) it too is easily customisable.
