## Functions

Just for completeness, you can also pass parameters to the function:

### Function call

    call :myDosFunc 100 "string val"

### Function body

    :myDosFunc
    echo. Got Param#1 %~1
    echo. Got Param#2 %~2
    goto :eof