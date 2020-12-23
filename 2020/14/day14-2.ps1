using namespace System.Collections.Generic;

$FilePath = "$PSScriptRoot\inputs\main.txt"

function ConvertTo-Int64 {
    param(
        [bool[]]
        $BitArray
    )

    [long]$IntValue = [long]0

    for($i = $BitArray.Length - 1; $i -ge 0; $i--) {
        if($BitArray[$i]) {   
            $IntValue += [Math]::Pow(2, $BitArray.Length - 1 - $i)
            #Write-Verbose "true at $i, int is $IntValue"
        }
    }

    $IntValue
}

function Get-MaskedValue {
    param(
        [List[bool]]
        $Mask,

        [string]
        $RawMask,

        [int]
        $Value
    )

    $MaskedValue = [bool[]]::new($Mask.Count)
    $TotalValue = [long]0

    Write-Verbose "Mask count is $($Mask.Count)"

    for($i = 0; $i -lt $Mask.Count; $i++) {
        $BitValue = [Math]::Pow(2, $Mask.Count - 1 - $i)

        if ($TotalValue + $BitValue -le $Value) {
            $TotalValue += $BitValue
            $MaskedValue[$i] = $true
            Write-Verbose "true at $i"
        } else {
            $MaskedValue[$i] = $false
        }

        if ($RawMask[$i] -eq 'X' -or $Mask[$i]) {
            Write-Verbose "Replacing bit at $i with $($Mask[$i])"
            
            $MaskedValue[$i] = $Mask[$i]
        }
    }

    $ConvertedValue = ConvertTo-Int64 $MaskedValue
    Write-Verbose "ConvertedValue is $ConvertedValue"
    $ConvertedValue
}

function Get-Mask {
    param(
        [string]
        $RawInput
    )

    $Masks = [List[List[bool]]]::new()

    $Masks.Add([List[bool]]::new())

    for($i = 0; $i -lt $RawInput.Length; $i++) {
        $Character = $RawInput[$i]

        if($Character -eq '0') {
            $Masks | %{
                $_.Add($false)
            }
        } elseif ($Character -eq '1') {
            $Masks | %{
                $_.Add($true)
            }
        } else {

            $MasksCount = $Masks.Count

            for($maskIdx = 0; $maskIdx -lt $MasksCount; $maskIdx++) {
                $CurrentMask = $Masks[$maskIdx]
                $CopiedMask = [List[bool]]::new()

                for($j = 0; $j -lt $CurrentMask.Count; $j++) {
                    $CopiedMask.Add($CurrentMask[$j])
                }

                $Masks.Add($CopiedMask)
            }

            for($maskIdx = 0; $maskIdx -lt $Masks.Count; $maskIdx++) {
                $Masks[$maskIdx].Add($maskIdx -lt $MasksCount)
            }
        }
    }

    $Masks
}

function Set-Mask {
    param(
        [string]
        $RawMask,

        [PSCustomObject]
        $ProgramState
    )

    Write-Verbose "New mask is $RawMask"
    $Masks = Get-Mask $RawMask

    $ConvertedMasks = [List[long]]::new()

    $Masks | % {    
        $ConvertedMask = ConvertTo-Int64 $_
        $ConvertedMasks.Add($ConvertedMask)
    }

    $ProgramState.RawMask = $RawMask
    $ProgramState.Masks = $Masks
    $ProgramState.ConvertedMasks = $ConvertedMasks
    
}


function Set-Memory {
    param(
        [long]
        $Address,

        [long]
        $Value,

        [PSCustomObject]
        $ProgramState
    )

    Write-Verbose "Masking address $Address"
    $ProgramState.Masks | %{
        $MaskedAddress = Get-MaskedValue $_  $ProgramState.RawMask $Address
        Write-Verbose "Setting address $MaskedAddress (unmasked $Address) to $Value"
        $ProgramState.Memory[$MaskedAddress] = $Value
    }
}

function Interpret {
    param(
        [string]
        $Instruction,

        [PSCustomObject]
        $ProgramState
    )

    Write-Verbose "Instruction is $Instruction"

    switch -Regex ($Instruction) {
        '^mask = (?<Mask>[X10]+)$' {Set-Mask $Matches.Mask $ProgramState; Break}
        '^mem\[(?<Address>\d+)\] = (?<Value>\d+)$' {Set-Memory $Matches.Address $Matches.Value $ProgramState; Break}
        Default {
            throw ("Unrecognized instruction $Instruction")
        }
    }
}

function Invoke-Program {
    param (
        [string]
        $FilePath
    )

    $ProgramState = [PSCustomObject]@{
        Masks = [List[List[bool]]]::new()
        RawMask = ""
        ConvertedMasks = [List[long]]::new()
        Memory = [Dictionary[long,long]]::new()
    }

    Get-Content $FilePath | Foreach-Object {
        Interpret $_ $ProgramState
    }

    [long]$Sum = 0
    $ProgramState.Memory.Keys | ForEach-Object {
        $Sum += $ProgramState.Memory[$_]
    }
    
    @{
        ProgramState = $ProgramState
        Sum = $Sum
    }
}

Invoke-Program $FilePath -Verbose