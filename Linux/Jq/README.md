## Sample 1

You can make a much simpler version of the jq program:

### Data

    {
      "SITE_DATA": {
        "URL": "example.com",
        "AUTHOR": "John Doe",
        "CREATED": "10/22/2017"
      }
    }
    
### Command

    jq -r '.SITE_DATA | to_entries | .[] | .key + "=\"" + .value + "\""'

### Output

    URL="example.com"
    AUTHOR="John Doe"
    CREATED="10/22/2017"
    
## Sample 2

### Data

    {  
       "result":{  
          "property_history":[  
             {  
                "date":"01/27/2016",
                "price_changed":0,
                "price":899750,
                "event_name":"Listed",
                "sqft":0
             },
             {  
                "date":"12/15/2015",
                "price_changed":0,
                "price":899750,
                "event_name":"Listed",
                "sqft":2357
             },
             {  
                "date":"08/30/2004",
                "price_changed":0,
                "price":739000,
                "event_name":"Sold",
                "sqft":2357
             }
          ]
       }
    }
    
### Command

    jq '.result | select(.property_history != null) | .property_history | map(select(.event_name == "Sold"))[0].date'

    jq '.result | .property_history? | .[] | select(.event_name == "Sold") | .date'

### Output

    "08/30/2004"
    
    
## Sample 3

### Data

    {
        "apps": {
            "firefox": "1.0.0",
            "ie": "1.0.1",
            "chrome": "2.0.0"
        }
    }
    
Basically want to sort the following output

    foreach app:
       echo "$key $val"
    done
    
### Command 1
    
    $ jq -r '...' input.json | xargs some_program    
    $ jq -r '.apps | to_entries[] | "\(.key)\t\(.value)"' input.json
    

### Command 2    
    #!/bin/bash
    json='
    {
        "apps": {
            "firefox": "1.0.0",
            "ie": "1.0.1",
            "chrome": "2.0.0"
        }
    }'

    jq -M -r '
        .apps | keys[] as $k | $k, .[$k]
    ' <<< "$json" | \
    while read -r key; read -r val; do
       echo "$key $val"
    done
    
### Output

    chrome 2.0.0
    firefox 1.0.0
    ie 1.0.1    
    
    
## Sample 4

### Data

How do I get jq to take json like this:

    {
      "host1": { "ip": "10.1.2.3" },
      "host2": { "ip": "10.1.2.2" },
      "host3": { "ip": "10.1.18.1" }
    }

and generate this output:

    host1, 10.1.2.3
    host2, 10.1.2.2
    host3, 10.1.18.1    
    
### Command

To get the top-level keys as a stream, you can use keys[]. So one solution to your particular problem would be:

    jq -r 'keys[] as $k | "\($k), \(.[$k] | .ip)"' 
    
`keys` produces the key names in sorted order; 
if you want them in the original order, use `keys_unsorted`

Another alternative, which produces keys in the original order, is:

    jq -r 'to_entries[] | "\(.key), \(.value | .ip)"'

CSV and TSV output

The @csv and @tsv filters might also be worth considering here, e.g.

    jq -r 'to_entries[] | [.key, .value.ip] | @tsv'

produces:

    host1   10.1.2.3
    host2   10.1.2.2
    host3   10.1.18.1    