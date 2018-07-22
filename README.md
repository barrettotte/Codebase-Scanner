# Codebase-Scanner
Scans directories/files for functions. Outputs in html and/or text file the total functions found, files scanned, lines scanned. Two sample text scans are found in **index.cfm**. The javascript one has been changed to keep company information out of it.

# To Do
* Create some javascript test files
* Finish javascript files --- nested js functions are giving me a little trouble
* Add a 'GENERAL' scan to give description of codebase by each file extension (.cfc, .cfm, .css, .txt)

# Usage
``` ColdFusion
 local.scanner = createObject('component', 'Code-Scanner').init();
 local.basePath = 'c:\source\cfmx\wwwroot\test\barrett\'; 

 local.scanOptions = {
   scanTitle: '<h2>ColdFusion Test</h2>',
   scanType: 'ColdFusion',
   outPath: local.basePath & 'Code-Scanner\resultsCF',
   scanTarget: [
       'C:\source\cfmx\wwwroot\test\barrett\'
   ],
   excludeContaining: [
       '_combined'
   ],
   showHtml: true,
   sizeUnits: 'Bytes'
 };
 local.scanResults = local.scanner.scan(local.scanOptions);
```
# Screenshots

## ColdFusion Scan In Progress
![screenshots](https://user-images.githubusercontent.com/15623775/43048614-7d4a9860-8db8-11e8-810d-1081ea4644f5.PNG)

## ColdFusion Scan Results
![screenshots02](https://user-images.githubusercontent.com/15623775/43048619-87060efc-8db8-11e8-8513-6b5079935b29.PNG)

