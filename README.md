# Nginx S3 Gateway

## Introduction

This project uses https://github.com/nginxinc/nginx-s3-gateway which proxies requests through to an AWS s3 bucket.

The Dockerfile pulls the opensource version specified, creates a non root user 1001 and provides owner permissions to the necessary Nginx config files so that these can be overwritten during deployment.

Being able run the image as a non root user was the driver for this project.

Drone is used to build and deploy the image to a private repository in AWS ECR.

## To run the image locally
1. Build the image
```
docker build -t nginx-s3-gateway .
```
2. Create a .settings.env file and add the environment variables shown below. 

```
S3_BUCKET_NAME=change-to-your-bucket-name
S3_ACCESS_KEY_ID=change-to-your-access-key
S3_SECRET_KEY=change-to-your-secret
S3_SERVER=s3.region.amazonaws.com
S3_SERVER_PORT=443
S3_SERVER_PROTO=https
S3_REGION=region
S3_STYLE=virtual
S3_DEBUG=true
AWS_SIGS_VERSION=4
ALLOW_DIRECTORY_LIST=false
PROXY_CACHE_VALID_OK=5m
PROXY_CACHE_VALID_NOTFOUND=1m
PROXY_CACHE_VALID_FORBIDDEN=30s
PROVIDE_INDEX_PAGE=true
APPEND_SLASH_FOR_POSSIBLE_DIRECTORY=false

```
> For more information on the environment variables, see the [official docs](https://github.com/nginxinc/nginx-s3-gateway/blob/master/docs/getting_started.md#configuration)

3. Change the `S3_BUCKET_NAME, S3_ACCESS_KEY_ID and S3_SECRET_KEY` values to use your s3 configuration. 

4. In `helm/config/default.conf.template` comment out `set $uri_path` and hardcode the path to your s3 bucket. The $subenv and $branch variables usually make up this path when deployed ($subenv is pulled from the URL, $branch is currently hardcoded). When running locally we're always using "localhost" and this information is not available from the URL.
```
location / {
    
    #set $uri_path       "/$subenv/$branch$uri_path";
    set $uri_path       "/my/path$uri_path";
    ...
}

```

5. Run the image with the mounted files as below: 

```
docker run -v $(PWD)/default.conf.templates:/etc/nginx/templates/default.conf.templates -v $(PWD)/nginx.conf:/etc/nginx/nginx.conf --env-file ./settings --publish 3000:3000 --name nginx-s3-gateway
```

6. Navigate to http://localhost:3000

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
The default implementation of the nginx s3 gateway reads the URI path (http://mywebsite.com/uripath/index.html) and constructs the request to the s3 bucket based on that (https://bucketname.s3.us-east.amazonaws.com/uripath/index.html). This implementation is slightly different in that it reads the path information from the URL (http://subenv.mywebsite.com) using a regular expression:
```
map $host $subenv {
    ~^[^.]+\.(?<p2>[^.]+)\.callisto.homeoffice.gov.uk$ $p2;
}
```
In the future it will also read the branch (JIRA ticket number) in the same way (http://subenv.branch.mywebsite.com)
## Useful links
- [AWS S3 configuration](https://github.com/nginxinc/nginx-s3-gateway/blob/master/common/etc/nginx/include/s3gateway.js) 
- [njs (a version of JavaScript)](https://nginx.org/en/docs/njs/) 
- [njs-examples](https://github.com/nginx/njs-examples/)
