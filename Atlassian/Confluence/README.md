## Confluence rest api examples

https://developer.atlassian.com/confdev/confluence-rest-api/confluence-rest-api-examples?_ga=2.253455369.1249515681.1539355317-1046961898.1507926952

curl -v -S -u admin:admin -X POST \
  -H "X-Atlassian-Token: no-check" \
  -F "file=@myfile.txt" \
  -F "comment=this is my file" \
  "http://localhost:8080/confluence/rest/api/content/3604482/child/attachment" | python -mjson.tool