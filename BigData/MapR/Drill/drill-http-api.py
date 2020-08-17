#!/usr/bin/python

import requests 
import json 
import sys 
import os 

drill_base_url = "http://10.32.48.134:8047" 
drill_user = "jlim" 
drill_pass = "2019Jfm!"

print "Drill Rest Endpoint: %s" % (drill_base_url) 

def main(): 
  s = requests.Session() # Create a session object 
  s = authDrill(s) # Authenticate to Drill 
  r = runQuery(s, "ALTER SESSION set `store.json.all_text_mode` = true") 
  result = runQuery(s, "show files") 
  print r.text 
  
  if result.status_code == 200: 
    print result.text 
  else: 
    print "Error encountered: %s" % result.status_code
    
def runQuery(s, drill): 
  url = drill_base_url + "/query.json" 
  payload = {"queryType":"SQL", "query":drill} 
  headers = {"Content-type": "application/json"} 
  r = s.post(url, data=json.dumps(payload), headers=headers, verify=False) 
  return r

def authDrill(s): 
  url = drill_base_url + "/j_security_check" 
  login = {'j_username': drill_user, 'j_password': drill_pass} 
  r = s.post(url, data=login, verify=False) 
  if r.status_code == 200: 
    if r.text.find("Invalid username/password credentials") >= 0: 
      print "Authentication Failed - Please check Secrets - Exiting" 
      sys.exit(1) 
    elif r.text.find("Number of Drill Bits") >= 0: 
      print "Authentication successful" 
    else: 
      print "Unknown Response Code 200 - Exiting" 
      print r.text 
      sys.exit(1) 
  else: 
    print "Non HTTP-200 returned - Unknown Error - Exiting" 
    print "HTTP Code: %s" % r.status_code 
    print r.text 
    sys.exit(1) 
  
  return s

if __name__ == '__main__': 
  main()