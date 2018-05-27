## Kill Yarn Apps


- version <2.3.0
```
    hadoop job -kill $jobId
    hadoop job -list
```

- version >=2.3.0

```
  yarn application -kill $ApplicationId
  yarn application -list
```