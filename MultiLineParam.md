## Jenkins MultiLine Parameter

https://www.cyotek.com/blog/using-parameters-with-jenkins-pipeline-builds

https://github.com/jenkinsci/pipeline-model-definition-plugin/wiki/Parametrized-pipelines

|Type|Name|Example Value|
|---|---|---|
|String|LIBNAME|Cyotek.Core|
|String|TESTLIBNAME|Cyotek.Core.Tests|
|String|LIBFOLDERNAME|src|
|String|TESTLIBFOLDERNAME|tests|
|Multi-line|EXTRACHECKOUTREMOTE|/source/Libraries/Cyotek.Win32|
|Multi-line|EXTRACHECKOUTLOCAL|.\source\Libraries\Cyotek.Win32|
|Boolean|SIGNONLY|false|
