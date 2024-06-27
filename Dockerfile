FROM alpine:3.20.1
RUN apk update && apk upgrade && apk add build-base curl openjdk21-jdk openjdk21-jre
RUN curl -L https://get.jenkins.io/war-stable/2.452.2/jenkins.war -o /root/jenkins.war
RUN apk add fontconfig ttf-dejavu msttcorefonts-installer
WORKDIR /var/lib/jenkins
ENV JENKINS_HOME=/var/lib/jenkins
ENV JENKINS_JAVA=/usr/bin/java
# ENV JENKINS_IP=0.0.0.0
# ENV JENKINS_PORT=8090
ENV JENKINS_JAVA_OPTIONS="-Duser.timezone=America/Lima"
CMD [ "/usr/bin/java", "-Djenkins.install.runSetupWizard=false", "-jar", "/root/jenkins.war", "-Duser.timezone=America/Lima", "--httpListenAddress=0.0.0.0", "--httpPort=8090" ]