using namespace System.Collections.Generic;

$File = "$PSScriptRoot\inputs\main.txt"
$PreambleSize = 25

$Numbers = Get-Content $File | % { [long]$_ }
$Sums = [Dictionary[long, PSCustomObject]]::new()

$NumberWithoutSum = for($i = 0; $i -lt $Numbers.Length - 1; $i++) {
    $iNumber = $Numbers[$i]

    if($i -ge $PreambleSize) {
        $OutSum = [PSCustomObject]@{}
        if ($Sums.TryGetValue($iNumber, [ref]$OutSum)) {

            $ValidSums = $OutSum | Where-Object {
                $_.MinValidAnswerIndex -le $i -and $_.MaxValidAnswerIndex -ge $i
            }

            if($ValidSums.Length -eq 0) {
                Write-Host "Can't find sum for entry $iNumber at index $i due to invalid answer index"
                $iNumber
                break
            }
        } else {
            Write-Host "Can't find sum for entry $iNumber at index $i"
            $iNumber
            break
        }
    }

    for($j = $i + 1; $j -lt $Numbers.Length; $j++) {
        $jNumber = $Numbers[$j]
        $sum = $iNumber + $jNumber

        if(!$Sums.ContainsKey($sum)) {
            $Sums[$sum] = [List[PSCustomObject]]::new()
        }

        $Sums[$sum].Add([PSCustomObject]@{
            MinValidAnswerIndex = $j + 1
            MaxValidAnswerIndex = $i + $PreambleSize
            Operand1Index = $i
            Operand2Index = $j
            Operand1 = $iNumber
            Operand2 = $jNumber
        })
    }
}

$WeaknessRange = for($i = 0; $i -lt $Numbers.Length - 1; $i++) {
    $sum = $Numbers[$i]
    for($j = $i + 1; $j -lt $Numbers.Length; $j++) {
        $sum += $Numbers[$j]
        if($sum -gt $NumberWithoutSum) {
            Write-Verbose "Sum is over $NumberWithoutSum at range $i, $j"
            break
        }
        elseif($sum -eq $NumberWithoutSum) {
            Write-Verbose "Found weakness range $i, $j"
            @{
                Start = $i
                End = $j
            }
            break
        }
    }
}

if(!$WeaknessRange) {
    throw "Weakness range not found for number without sum $NumberWithoutSum"
}

$WeaknessMeasure = $Numbers[$WeaknessRange.Start..$WeaknessRange.End] | Measure-Object -Minimum -Maximum
$Weakness = $WeaknessMeasure.Minimum + $WeaknessMeasure.Maximum

@{
    NumberWithoutSum = $NumberWithoutSum
    Weakness = $Weakness
}