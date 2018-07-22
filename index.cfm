<html>
    <body>
        <h2>Code Scanner Testing</h2>
        <br /> <br />
        <cfscript>
            local.scanner = createObject('component', 'Code-Scanner').init();
            local.basePath = 'c:\source\cfmx\wwwroot\test\barrett\'; 

            local.scanOptions = {
                scanTitle: '<h2>ColdFusion Test</h2>',
                scanType: 'ColdFusion',
                outPath: local.basePath & 'Code-Scanner\resultsCF',
                scanTarget: [
                    'C:\source\cfmx\wwwroot\test\barrett\'
                ],
                excludeContaining: [],
                showHtml: true,
                sizeUnits: 'Bytes'
            };
            local.scanResults = local.scanner.scan(local.scanOptions);

            local.scanOptions = {
                scanTitle: '<h2>Javascript Test</h2>',
                scanType: 'js',
                outPath: local.basePath & 'Code-Scanner\resultsJS',
                scanTarget: [
                    'C:\source\cfmx\wwwroot\test\barrett\'
                ],
                excludeContaining: [
                    '_combined',
                    '.min'
                ],
                showHtml: true,
                sizeUnits: 'KB'
            };
            local.scanResults = local.scanner.scan(local.scanOptions);
        </cfscript>
    </body>
</html>