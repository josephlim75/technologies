## When Conditional

### Data
    - shell: git config --global --list
      register: git_config_list  
      
    [
    "user.name=Foo Bar",
    "user.email=foo@example.com"
    ]

### Search

    git_config_list.stdout_lines | join("|") | match("user.name=[^|]+")

    
## Check if String in Array
```
  - "'<string>' in group_names"
  - "'<string>' in labels"
```  