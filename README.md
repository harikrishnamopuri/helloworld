# helloworld
echo "welcome to jenkins and git "
!/bin/bash -x


export ansibl-role=tts
export ansible-branch=master
export env=eng
export language_code=zhCN
export models_infos=${models_infos}
export params="s3://bixby-config-dev-usw2/ansible-configs/dev/eng/default-tts-mobile-en-US.json"
export ramp_code=mobile
export tts_wrapper=${tts_wrapper}
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=ansible-role,Value=${ansible-role},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=ansible-branch,Value=${ansible-branch},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=env,Value=${env},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=language_code,Value=${language_code},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=models_infos,Value=${models_infos},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=params,Value=${params},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=ramp_code,Value=${ramp_code},PropagateAtLaunch=true"
aws autoscaling create-or-update-tags --tags  "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=tts_wrapper,Value=${tts_wrapper},PropagateAtLaunch=true"


export APPL_NAME=eng-codedeploy
export DEP_CONFIG_NAME=CodeDeployDefault.OneAtATime
export DEP_GROUP_NAME=eng-codedeploy
export S3_BUCKET_NAME=haricm
export FILE_NAME=codedeploy-sample-app.tar.gz
export DISC_MSG={My-demo-deployment}
TAG_APPLY=$(aws autoscaling create-or-update-tags --tags "ResourceId=eng-deploy,ResourceType=auto-scaling-group,Key=environment,Value=staging,PropagateAtLaunch=true")
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
