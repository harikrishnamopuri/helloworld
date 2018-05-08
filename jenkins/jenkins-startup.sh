cat startup.sh
export JENKINS_HOME=/home/hari/jenkins/workspace
ulimit -u 65536
ulimit -n 65536

nohup java -Dhudson.slaves.ChannelPinger.pingInterval=15 -Dhudson.model.ParametersAction.keepUndefinedParameters=true -Dhudson.model.DirectoryBrowserSupport.CSP="sandbox='allow-scripts'; default-src 'none'; img-src 'self'; style-src 'self';" -jar jenkins.war --prefix=/jenkins -Dorg.eclipse.jetty.server.Request.maxFormContentSize=5000000 &

