FROM jenkins/jenkins:lts

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY disable-cli.groovy /usr/share/jenkins/ref/init.groovy.d/disable-cli.groovy

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# disable the first start wizard and the additional plugin warning
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
RUN echo "2.0" > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
