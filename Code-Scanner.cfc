component 
    displayName="Code-Scanner" 
    hint="Scan directories/files for functions and display html and/or write to text file"{

    public function init(){
        variables.newLine = Chr(13) & Chr(10);
        variables.divider = repeatString("-", 75);
        return this;
    }

    public any function scan(required struct options){
        if(!inspectOptions(arguments.options)){
            writeDump('Error found in options struct.', 'console');
            return structNew();
        }
        var scanResults = arrayNew(1);
        var dirList = arrayNew(1);
        var extensions = getExtensions(arguments.options.scanType);
        var countStruct = { 'fileCount': 0, 'totalFuncs': 0, 'totalLines': 0, 'totalChars': 0, 'totalSize': 0};
        var output = arguments.options.scanTitle;
        var result = structNew();
        
        if(!arguments.options.outPath.find('.txt')){
            arguments.options.outPath = arguments.options.outPath & '.txt';
        }
        for(var x = 1; x <= ArrayLen(arguments.options.scanTarget); x++){
            var fileInfo = getFileInfo(arguments.options.scanTarget[x]);
            if(fileInfo.type EQ 'directory'){
                dirList = directoryList(arguments.options.scanTarget[x], 
                    true, "path", extensions);
            } else if(fileInfo.type EQ 'file'){
                dirList.append(arguments.options.scanTarget[x]);
            }
            for(var i = 1; i <= arrayLen(dirList); i++){
                if(arrayLen(arguments.options.excludeContaining) > 0){
                    for(var j = 1; j <= arrayLen(arguments.options.excludeContaining); j++){
                        if(find(arguments.options.excludeContaining[j], dirList[i])){
                            continue;
                        }
                    }
                }
                result = scanFile(dirList[i], arguments.options.showHtml);
                output = output & result.output;

                if(!structKeyExists(countStruct, result.fileExt)){
                    structInsert(countStruct, result.fileExt, 0, false);
                }
                countStruct[result.fileExt]++;
                countStruct.totalFuncs += result.funcCount;
                countStruct.totalLines += result.lineCount;
                countStruct.totalChars += result.charCount;
                countStruct.totalSize += result.fileSize;
            }
            countStruct.fileCount += arrayLen(dirList);
            scanResults.append(result);
        }
        countStruct.totalSize = convertFileSize(countStruct.totalSize, arguments.options.sizeUnits);
        output = output & buildTotalsOutput(countStruct) & variables.divider;
        var outFile = fileOpen(options.outPath, 'write');
        fileWriteLine(outFile, output);
        fileClose(outFile);
        if(arguments.options.showHtml){
            displayHtml(output);
        }
        return scanResults;
    }

    private boolean function inspectOptions(required struct options){
        return (arguments.options.scanType != '') && (arguments.options.outPath != '')
        && (arrayLen(arguments.options.scanTarget) > 0) && (arguments.options.sizeUnits != '') 
        && (arguments.options.scanTitle != '');
    }

    private string function convertFileSize(required string fileSize, required string sizeUnits){
        switch(uCase(arguments.sizeUnits)){
            case 'BITS':    return (arguments.fileSize * 8) & ' Bits';
            case 'BYTES':   return arguments.fileSize & ' Bytes';
            case 'KILOBYTES':
            case 'KB':      return numberFormat(arguments.fileSize / 1024, '9.999') & ' KB';
            case 'MEGABYTES':
            case 'MB':      return numberFormat(arguments.fileSize / (1024 * 1024), '9.999') & ' MB';
            case 'GIGABYTES':
            case 'GB':      return numberFormat(arguments.fileSize / (1024 * 1024 * 1024), '9.999') & ' GB';
            default:        return arguments.fileSize & ' Bytes';
        }
    }

    private string function getExtensions(required string scanType){
        switch(uCase(arguments.scanType)){
            case 'CF':  case 'COLDFUSION':  return "*.cfm|*.cfc";
            case 'JS':  case 'JAVASCRIPT':  return "*.js";
            case 'GENERAL':                 return "*";
        }
        return "";
    }

    private any function scanFile(required string scanTarget, required boolean showHtml){
        var file = fileOpen(arguments.scanTarget, 'read');
        var resultsStruct = { 
            lineCount: 1, charCount: 0, funcCount: 0, target: arguments.scanTarget, functionArr: arrayNew(1), 
            output: "Scanning {#arguments.scanTarget#} #variables.newLine#", fileSize: getFileInfo(arguments.scanTarget).Size,
            fileExt: '.' & listLast(getFileInfo((arguments.scanTarget)).Name, '.')
        };
        while(NOT fileIsEOF(file)){
            var line = trim(fileReadLine(file));
            var func = findFunction(line);
            if(len(func) > 0){
                resultsStruct.functionArr.append(func);
                resultsStruct.funcCount++;
                resultsStruct.output = resultsStruct.output &
                    "         #numberFormat(resultsStruct.funcCount, '000')#). " &
                    "         Line: #numberFormat(resultsStruct.lineCount, '0000')#         " &
                    resultsStruct.functionArr[resultsStruct.funcCount] & variables.newLine;
            }
            resultsStruct.charCount += len(line);
            resultsStruct.lineCount++;
        }
        resultsStruct.output = resultsStruct.output &
            "Scanned {#resultsStruct.lineCount#} line(s), " &
            "{#resultsStruct.charCount#} character(s), and found " &
            "{#resultsStruct.funcCount#}"&" function(s)."&"#variables.newLine#" &
            "#variables.newLine##variables.divider##variables.newLine#";
        fileClose(file);
        resultsStruct.functionArr = arrayToList(resultsStruct.functionArr);
        return resultsStruct;
    }

    private string function buildTotalsOutput(required struct countStruct){
        var output = '<h2>Results:</h2>';
        for(var countType in arguments.countStruct){
            output = output & '        ' & '{' & arguments.countStruct[countType] & '} ';
            if(find('.', countType)){
                output = output & lCase(countType) & ' files' & variables.newLine;
            } else {
                var label = '';
                switch(countType){
                    case 'totalFuncs':  label = 'function(s) total';          break;
                    case 'totalLines':  label = 'line(s) total ';             break;
                    case 'totalChars':  label = 'character(s) total ';        break;
                    case 'totalSize':   label = 'scanned';                   break;
                    case 'fileCount':   label = ' total file(s) scanned';     break;
                }
                output = output & label & variables.newLine;
            }
        }
        return output;
    }

    private string function findFunction(required string line){
        var funcLabels = ['function', 'cffunction'];
        var accessTypes = ['public', 'private', 'remote'];
        arguments.line = trim(arguments.line);
        if(preSplitCheck(arguments.line)){
            var lineSplit = listToArray(arguments.line, " (){}<>");
            for(var i = 1; i <= arrayLen(funcLabels); i++){
                var findFunc = lineSplit.find(funcLabels[i]);
                if(findFunc > 0){
                    for(var j = 1; j <= arrayLen(accessTypes); j++){
                        if(finalCheck(arguments.line)){
                            if(funcLabels[i] == 'cffunction'){
                                return arrayToList(lineSplit, " ");
                            } else{
                                func = mid(arguments.line, 1, findOneOf('(', arguments.line));
                                return (len(func) > 0) ? (func & ')') : '';
                            }
                        }
                    }
                }
            }
        }
        return '';
    }

    private boolean function preSplitCheck(required string line){
        var badPieces = [
            '.forEach', '.each(', '.then(', 'jQuery', '(function(', '.all',
            '.race', '.resolve','.reject', 'return function', 'console.'
        ];
        if(arguments.line == 'function(){'){
            return false;
        }
        local.hasFwdSlash = find('/', arguments.line);
        local.hasFunction = find('function', arguments.line);
        local.hasEqual = find('=', arguments.line);
        local.hasLeftParen = find('(', arguments.line);

        if(find(':', arguments.line)){
            local.tempSplit = listToArray(arguments.line, ':');
            if(arrayLen(local.tempSplit) < 3){
                return false;
            }
        }
        if(mid(arguments.line, 1, local.hasLeftParen) == 'function('){
            return false;
        }
        if(local.hasFwdSlash == 1){
            return false; //get rid of complete comments
        }
        if(local.hasFunction && local.hasFwdSlash && local.hasFwdSlash > local.hasFunction){
            return false; //get rid of comments
        }
        for(var i = 1; i <= arrayLen(badPieces); i++){
            if(find(badPieces[i], arguments.line)){
                return false;
            }
        }
        return true;
    }

    private boolean function finalCheck(required string line){
        var badChars = ['$', "'", '&', '!', '['];
        if(find('.', arguments.line) == 1){
            return false;   //get rid of JS .function() and ()
        }
        local.hasComma = find(',', arguments.line);
        local.hasQuote = find('"', arguments.line);
        local.hasColon = find(':', arguments.line);
        local.hasEqual = find('=', arguments.line);

        if(local.hasComma && local.hasColon < find('function', arguments.line)){
            return false;   //functions in structs
        }
        if(local.hasColon && local.hasQuote){
            return false;   //functions in structs
        }
        for(var i = 1; i <= arrayLen(badChars); i++){
            if(find(badChars[i], arguments.line)){
                return false;
            }
        }
        return true;
    }

    private void function displayHtml(required string output){
        var htmlOut = output.split(variables.newLine);
        for(var piece in htmlOut){
            piece = replace(piece, ' ', '&nbsp;', 'all');
            piece = replace(piece, '{', '<b>', 'all');
            piece = replace(piece, '}', '</b>', 'all');
            piece = replace(piece, variables.divider, '<hr />', 'all');
            writeOutput("#piece#<br />");   
        }
    }
}