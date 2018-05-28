## Actice Choice Groovy Code

Under "Manage Jenkins / Configure System",
I configured "Mask Passwords - Parameters to automatically mask" for:
Active Choices Reactive Reference Parameter
Active Choices Reactive Parameter
Active Choices Parameter

and created one "Mask Passwords - Global name/password pairs" for:
build_password

In Jenkins job configuration,
I have an "Active Choices Reactive Parameter" using Groovy script
and tries to use that global variable ${build_password}:
```
  if ( SVN_FOLDER.endsWith("/trunk") ){
      return ["N/A"]
  } else {
      def SVN_LIST_URL = "${SVN_ROOT}/${SVN_FOLDER}"
      def SVN_CMD_ARG = "svn ls --username build --password ${build_password} --non-interactive ${SVN_LIST_URL}"
      def SVN_CMD_OUT = SVN_CMD_ARG.execute().text
      def SVN_SELECCTION_LIST = SVN_CMD_OUT.split('/\n').toList().sort().reverse()

      return SVN_SELECCTION_LIST
  }
```
The above code works only if I replace ${build_password} with actual password string.


```
  import com.michelin.cio.hudson.plugins.maskpasswords.*;

  SVN_ROOT = "https://server.com/svn/root"

  // getting global masked password...
  maskPasswordsConfig = MaskPasswordsConfig.getInstance()
  varPasswordPairs = maskPasswordsConfig.getGlobalVarPasswordPairs()

  // default to empty
  build_password = ''
  // check if we have a global pair with that password
  varPasswordPairs.each { pair ->
      if (pair.getVar().equals("build_password")) {
          // this will use Jenkins' Secret class to decrypt it...
          build_password = pair.password
      }
  }

  if ( SVN_FOLDER.endsWith("/trunk") ){
      return ["N/A"]
  } else {
      def SVN_LIST_URL = "${SVN_ROOT}/${SVN_FOLDER}"
      //def SVN_CMD_ARG = "svn ls --username build --password ${build_password} --non-interactive ${SVN_LIST_URL}"
      //def SVN_CMD_OUT = SVN_CMD_ARG.execute().text
      //def SVN_SELECTION_LIST = SVN_CMD_OUT.split('/\n').toList().sort().reverse()
      // Just for test, as it would be hard to share an example calling user+pass from a repo
      def SVN_SELECTION_LIST = [build_password]

      return SVN_SELECTION_LIST
  }
```