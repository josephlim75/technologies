#!/usr/bin/env python
from lxml import etree as ET
#import sys, xml.etree.ElementTree as ET
#ET.register_namespace('','http://karaf.apache.org/xmlns/features/v1.4.0')
tree = ET.parse('/tmp/item.xml')
root = tree.getroot()

#print(root.tag)
#print(root.attrib)

for child in root:
  if child.get('name') == "nexus-core-feature":
    element = ET.fromstring('<feature version="3.14.0.04" prerequisite="false" dependency="false">nexus-helm-repository</feature>')
    element.tail = '\n\t'
    child.insert(1, element)




str = "    <feature>\n \
      <details></details>\n \
      <feature></feature>\n \
    </feature>\n"
r = ET.fromstring(str)
r.tail = '\n'
root.append(r)

tree.write("/tmp/newitem.xml", pretty_print=True, standalone='yes', xml_declaration=True, encoding='UTF-8', method="xml")

'''
main function, so this program can be called by python program.py
'''
if __name__ == "__main__":
  buildTree()
  
  
  Insert before
  sed -e '0,/<features>/{/features>/e cat items.xml' -e '}' newitem.xml
  
  Insert After
  sed -e '0,/<\/details>/{/details>/r items.xml' -e '}' newitem.xml