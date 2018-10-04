#!/usr/bin/python

import json

def main():
    module = AnsibleModule(
        argument_spec=dict(
        	appkey=dict(required=True),
            city=dict(default='munich,de'),
            treshold=dict(required=True, type='float')
        ),
    )

    city = module.params['city']
    treshold = module.params['treshold']
    appkey = module.params['appkey']

    url = 'http://api.openweathermap.org/data/2.5/weather?q={}&APPID={}&units=metric'.format(city, appkey)
    curl_result = module.run_command(['/usr/bin/curl', 'GET', url])
 
    if curl_result[0] != 0:
        module.fail_json(msg='Curl command returned non-0 exit {}, the output was {}'.format(curl_result[0], 
                                                                                             curl_result[1]))
    else:
        curl_result_dict = json.loads(curl_result[1])
        http_resp_code = curl_result_dict['cod']
    
    if http_resp_code not in [200]:
        module.fail_json(msg='non-200 response code {} received, the output was {}'.format(http_resp_code, 
                                                                                           curl_result[1]))
    else:
        temperature = curl_result_dict['main']['temp']
    
    if temperature > treshold:
        module.exit_json(changed=True, decision='Run, Yves, Run, it is {} in {}'.format(temperature, city))

    if temperature < treshold:
        module.exit_json(changed=False, decision='Stop, Yves, Stop, it is {} in {}'.format(temperature, city))

from ansible.module_utils.basic import *
main()