# Disable the Jenkins CLI.
#
# It's generally a security risk and for Janky, we'll do it all over the API anyways
#
# Original code from: https://support.cloudbees.com/hc/en-us/articles/234709648-Disable-Jenkins-CLI

import jenkins.AgentProtocol
import jenkins.model.Jenkins
import hudson.model.RootAction
import java.util.logging.Logger

Logger logger = Logger.getLogger("disable-cli.groovy")
logger.info("Disabling the Jenkins CLI...")

// disabled CLI access over TCP listener (separate port)
def protocols = AgentProtocol.all()
protocols.each { protocol ->
    if (protocol.name?.contains("CLI")) {
        logger.info("Removing protocol ${protocol.name}")
        protocols.remove(protocol)
    }
}

// disable CLI access over /cli URL
def removal = { extensions ->
    extensions.each { extension ->
        if (extension.getClass().name.contains("CLIAction")) {
            logger.info("Removing extension ${extension.getClass().name}")
            extensions.remove(extension)
        }
    }
}
def jenkins = Jenkins.instance
removal(jenkins.getExtensionList(RootAction.class))
removal(jenkins.actions)
logger.info("CLI disabled")
