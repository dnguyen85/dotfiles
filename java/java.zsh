export JAVA_HOME=$(dirname $(dirname $(realpath /usr/bin/java)))
export PATH=$JAVA_HOME/bin:$PATH
alias print-java-version='printf "\n☕️ Java\n\n" && which java && java -version'
alias switch-java-version='sudo alternatives --config java && source ~/.zshrc'
