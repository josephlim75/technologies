Install site-package into specific Python version
==================================================
This will force to use python3 pip.  Package will be install into /usr/lib/<python version>/site-packages
  python3 -m pip install <SomePackage>



Find where package module is located
===================================

pip show <modulename>
  pip show hvac
  
which pip 
cat /usr/bin/pip

PIP Conflicts
================

Pip install in /usr/bin or /usr/local/bin.  

Make sure use only one of the path, otherwise, there will be conflict, Eg

  /usr/bin/pip3   /usr/local/bin/pip3, depending on the PATH, it will always use /usr/local/bin first


Find python path
==================

python -c "import sys; print(sys.path)"

python -c "import sys; print(':'.join(x for x in sys.path if x))"

PYTHONPATH

-----------------------------

head -1 clicks | python -m json.tool

There are two types of site-packages directories, global and per user.

Global site-packages ("dist-packages") directories are listed in sys.path when you run:

python -m site
For a more concise list run getsitepackages from the site module in Python code:

python -c "import site; print(site.getsitepackages())"
Note: With virtualenvs getsitepackages is not available, sys.path from above will list the virtualenv's site-packages directory correctly, though.
The per user site-packages directory (PEP 370) is where Python installs your local packages:

python -m site --user-site
If this points to a non-existing directory check the exit status of Python and see python -m site --help for explanations.


-----------------------------------------------------
Get list of version of pip packages

  pip install docker-compose== 2>&1 | grep -oE '(\(.*\))' | awk -F:\  '{print$NF}' | sed -E 's/( |\))//g' | tr ',' '\n'
  
Get latest

  pip install docker-compose== 2>&1 | grep -oE '(\(.*\))' | awk -F:\  '{print$NF}' | sed -E 's/( |\))//g' | tr ',' '\n' | gsort -r -V | head -1
  
-----------------------------------------------------
  
>>> import requests
>>> from pkg_resources import parse_version
>>> 
>>> def versions(name):
...     url = "https://pypi.python.org/pypi/{}/json".format(name)
...     return sorted(requests.get(url).json()["releases"], key=parse_version)
... 
>>> print(*reversed(versions("Django")), sep="\n")
1.10.3
1.10.2
1.10.1
1.10
1.10rc1
1.10b1
1.10a1  

-----------------------------------------------------
  pip list | grep 'beautifulsoup4'