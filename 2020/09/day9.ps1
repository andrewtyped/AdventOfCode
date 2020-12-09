$File = "$PSScriptRoot\inputs\test.txt"
$PreambleSize = 25

$Numbers = Get-Content $File

for($i = 0; $i -lt $PreambleSize - 1; $i++) {
    for($j = $i + 1; $j -lt $PreambleSize; $j++) {
        
    }
}

for($i = $PreambleSize; $i -lt $Numbers.Length; $i++) {
    $PreambleStart = $i - $PreambleSize
    $PreambleEnd = $i - 1
}