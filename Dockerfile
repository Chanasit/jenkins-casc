FROM jenkins/jenkins:2.401.2

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/init.jcasc.d/
ENV JENKINS_REF /usr/share/jenkins/ref
ENV JENKINS_INIT /usr/share/jenkins/ref/init.groovy.d

# Setup plugins to be installed
COPY --chown=jenkins:jenkins plugins.txt $JENKINS_REF/plugins.txt
RUN jenkins-plugin-cli -f $JENKINS_REF/plugins.txt

# Setup Authorize-Project Plugin
COPY --chown=jenkins:jenkins groovy/* $JENKINS_INIT

# Setup JCasc code for Jenkins server automation
# Setup Seed job for DSL
COPY casc/*.yaml $CASC_JENKINS_CONFIG

USER root

# Install the latest Docker CE binaries
RUN apt-get update && \
  apt-get -y --no-install-recommends install apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common && \
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
  add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(lsb_release -cs) \
  stable" && \
  apt-get update && \
  apt-get -y --no-install-recommends install docker-ce && \
  apt-get clean

RUN apt-get update \
  && apt-get install -y sudo \
  && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# Install gcloud
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

USER jenkins
