Install Codedeploy agent on ec2 instance]
centos :
#!/bin/bash
sudo yum update
sudo yum install ruby
sudo yum install wget
REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone/ | sed 's/[a-z]$//')
wget https://aws-codedeploy-${REGION}-name.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent status
sudo service codedeploy-agent start
sudo service codedeploy-agent status


ubuntu:
#!/bin/bash
sudo apt-get update
sudo apt-get install ruby2.0 : On Ubuntu Server 14.04
sudo apt-get install ruby : On Ubuntu Server 16.04
cd /home/ubuntu
REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone/ | sed 's/[a-z]$//')
wget https://aws-codedeploy-${REGION}-name.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent status
sudo service codedeploy-agent start
sudo service codedeploy-agent status



Create IAM roles:
Create foloowing IAM roles and attach the policies
1. IAM role for instance profile
2. IAM role for service profile

Role 1: 
instance Role : CodeDeployInstanceRole

Attach the following policies
a. AmazonEC2RoleforAWSCodeDeploy
b. AutoScalingNotificationAccessRole

Roles 2:
Service Role: CodeDeployServiceRole

Attach the following policies
a. 		AWSCodeDeployRole
Note : Edit Trust Relationship to ensure  "service":"codedeploy.amazonaws.com"


#1.Create a launch configuration by copying any existing spinnaker eng lanuch configuration (test-deploy-lanuch-config)
Launch configuration details:
  a.Modify iam role as "CodeDeployInstanceRole"
  b.Add in userdata "codedeploy agent installation steps"
  c.add depoy=true option in ansible command  env variables in userdata 
   
2.Create a autoscaling group as like  existing spinnaker  eng autoscaling group  using newly created lanuch configuration
Edit below as per our infra
  a. Groupname : Eng-deploy 
  b. Group size : 
  c. Network :
  d. subnet   :
  
 Advanced Details : 
 1. Classic Load Balancers or Target Groups
 2. Health Check Type
 3. Service-Linked Role 
 
 Configure scaling policies: 
 1.Keep this group at its initial size
 Configure Tags:
        "Name": "ttsMobileEnUS-engDefault",
        "Owner": "HQ",
        "ansible-role": "tts",
        "datadog_enabled": "true",
        "env": "eng",
        "spinnaker-managed": "true",
        "state-env": "default",

		
		
Create codedeploy application:

  Application name : 
  Compute Platform :
  Deployment group name :
  Deployment type : Blue/green deployment
  Environment configuration :  Auto Scaling group
  Load balancer*
  Rollbacks : 
  Service role : CodeDeployServiceRole
  
  

create s3 bucket or git hub

make a tar.gz file upload  to s3 or push below format code into the github 
appspec.yml  codedeploylab    index.html  lab  LICENSE.txt  linux.zip  README.md  SampleApp_Linux.zip  scripts  test.txt
root@instance-1:/home/hkrishna294/codedeploy-sample-app# cat appspec.yml 
version: 0.0
os: linux
files:
  - source: /index.html
    destination: /var/www/html/
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies
      timeout: 300
      runas: root
    - location: scripts/start_server
      timeout: 300
      runas: root
 	  



#jenkins script


#!/bin/bash -x
ansible-role=tts
ansible-branch=master
env=eng
language_code=en-US
models_infos=${models_infos}
params="s3://bixby-config-dev-usw2/ansible-configs/dev/eng/default-tts-mobile-en-US.json"
ramp_code=mobile
tts_wrapper=${tts_wrapper}
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=ansible-role,Value=${ansible-role},PropagateAtLaunch=true") 
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=ansible-branch,Value=${ansible-branch},PropagateAtLaunch=true")
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=env,Value=${env},PropagateAtLaunch=true")
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=language_code,Value=${language_code},PropagateAtLaunch=true")
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=models_infos,Value=${models_infos},PropagateAtLaunch=true")
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=params,Value=${params},PropagateAtLaunch=true")
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=ramp_code,Value=${ramp_code},PropagateAtLaunch=true")
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=tts_wrapper,Value=${tts_wrapper},PropagateAtLaunch=true")


export APPL_NAME=eng-codedeploy
export DEP_CONFIG_NAME=CodeDeployDefault.OneAtATime
export DEP_GROUP_NAME=eng-codedeploy
export S3_BUCKET_NAME=haricm
export FILE_NAME=codedeploy-sample-app.tar.gz
export DISC_MSG={My-demo-deployment}

DEP_ID=$(aws deploy create-deployment --application-name ${APPL_NAME}  --deployment-config-name ${DEP_CONFIG_NAME} --deployment-group-name ${DEP_GROUP_NAME} --description ${DISC_MSG} --s3-location bucket=${S3_BUCKET_NAME},bundleType=tgz,key=${FILE_NAME} --output text)
echo ${DEP_ID}
x=1
while [ $x -le 100 ];
do
  echo "Waiting to complete deployment"
  x=$(( $x + 1 ))
    DEP_STATUS=$(aws deploy get-deployment --deployment-id ${DEP_ID} --query "deploymentInfo.[status]" --output text)
       echo ${DEP_STATUS}.x
      if [ "${DEP_STATUS}.x" == "Succeeded.x" ]; then
      echo ${DEP_STATUS}.x
      break
      set i 1 
      else
      echo ${DEP_STATUS}.x
      sleep 10
      fi
done
INSTANCESLIST=($(aws deploy list-deployment-instances --deployment-id   ${DEP_ID} --output text))
echo ${INSTANCESLIST[1]}
for INSTANCE in "${INSTANCESLIST[@]:1}"
do
  PULIC_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE} --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
  PVT_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE} --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
  echo "${INSTANCE}: ${PVT_IP} "
done




 
        
Editing tags on autoscaling group  
1.aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name eng-deploy
2.aws autoscaling create-or-update-tags --tags "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=environment,Value=staging,PropagateAtLaunch=true"
3.

  
   

  
  
  




aws ec2 create-tags --resources i-09dd9a51dce439375 --tags Key=Name,Value=testInstance Key=Region,Value=West Key=Environment,Value=Beta
