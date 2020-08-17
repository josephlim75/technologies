#!/usr/bin/env python

from pydrill.client import PyDrill
drill = PyDrill(host='10.32.48.136', port=48047, auth="jlim:2019Jfm!", use_ssl=False, verify_certs=False)

if not drill.is_active():
  raise ImproperlyConfigured('Please run Drill first')

tenants = drill.query('''
  SELECT * FROM
  dfs.`/tsys/qa/internal/data/maprdb/tenants`
  LIMIT 5
''')

for result in tenants:
    print result