using namespace System.Collections.Generic

$FilePath = "$PSScriptRoot\inputs\test.txt"

$RawContent = Get-Content $FilePath

$Rows = $RawContent.Length
$Columns = $RawContent[0].Length

$SeatingArea = [char[][]]::new($Rows)

$RawContent | % -Begin {
    $LineIndex = 0
} -Process { 
    $CurrentLine = $_
    
    $SeatingArea[$LineIndex] = [char[]]::new($Columns)

    for($i = 0; $i -lt $Columns; $i++) {
        $CurrentChar = $CurrentLine[$i]
        $SeatingArea[$LineIndex][$i] = $CurrentChar
    }

    $LineIndex++
}

$SeatingArea