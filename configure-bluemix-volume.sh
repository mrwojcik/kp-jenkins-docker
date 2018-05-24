#!/bin/bash
set -e

export JENKINS_USER=${user:-"jenkins"}
export BLUEMIX_VOLUME_PATH=${BLUEMIX_VOLUME_PATH:-"/var"}

create_jenkins_config_dir() {
  # Temporarily add user "jenkins" to group "root" 	
  usermod -aG root $JENKINS_USER

  # Change Bluemix volume permissions to rwx for group "root"
  chmod 775 $BLUEMIX_VOLUME_PATH

  # Create subdirectory which is owned by user "jenkins"  
  su -c "mkdir -p $BLUEMIX_VOLUME_PATH/jenkins_home" $JENKINS_USER
  su -c "chmod 700 $BLUEMIX_VOLUME_PATH/jenkins_home" $JENKINS_USER
  ls -al $BLUEMIX_VOLUME_PATH

  # Since work is done, remove user "jenkins" from group "root"
  deluser $JENKINS_USER root

  # And also restore the Bluemix volume's original permissions
  chmod 755 $BLUEMIX_VOLUME_PATH
}


create_jenkins_config_dir

su -c "/usr/local/bin/jenkins.sh" $JENKINS_USER


