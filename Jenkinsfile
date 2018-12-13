def utils = new com.consilio.Utils()
utils.consilioSettings() 

// pull request tasks
// only run when the base is master
if (env.CHANGE_TARGET == 'master' && env.BRANCH_NAME =~ /PR-/) {
  powershellPR {
    notify_channel = 'CID'
  }
} else {
  // always fallback to a basic CI job
  powershellCI {
    notify_channel = 'CID'
  }
}
