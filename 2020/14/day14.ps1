using namespace System.Collections.Generic;

$FilePath = "$PSScriptRoot\inputs\main.txt"

function ConvertTo-Int32 {
    param(
        [bool[]]
        $BitArray
    )

    $IntValue = 0

    for($i = $BitArray.Length - 1; $i -ge 0; $i--) {
        if($BitArray[$i]) {   
            $IntValue += [Math]::Pow(2, $BitArray.Length - 1 - $i)
            Write-Verbose "true at $i, int is $IntValue"
        }
    }

    $IntValue
}

function Get-Mask {
    param(
        [string]
        $RawInput
    )

    $MaskBits = [nullable[bool][]]::new($RawInput.Length)

    for($i = 0; $i -lt $RawInput.Length; $i++) {
        $Character = $RawInput[$i]

        if($Character -eq '0') {
            $MaskBits[$i] = $false
        } elseif ($Character -eq '1') {
            $MaskBits[$i] = $true
        } else {
            $MaskBits[$i] = $null
        }
    }

    $MaskBits
}

function Set-Mask {
    param(
        [string]
        $RawMask,

        [PSCustomObject]
        $ProgramState
    )

    Write-Verbose "New mask is $RawMask"
    $Mask = Get-Mask $RawMask
    $ProgramState.Mask = $Mask
    
}

function Get-MaskedValue {
    param(
        [nullable[bool][]]
        $Mask,

        [int]
        $Value
    )

    $MaskedValue = [bool[]]::new($Mask.Length)
    $TotalValue = [long]0

    for($i = 0; $i -lt $Mask.Length; $i++) {
        $BitValue = [Math]::Pow(2, $Mask.Length - 1 - $i)

        if ($TotalValue + $BitValue -le $Value) {
            $TotalValue += $BitValue
            $MaskedValue[$i] = $true
            Write-Verbose "true at $i"
        } else {
            $MaskedValue[$i] = $false
        }

        if ($null -ne $Mask[$i]) {
            Write-Verbose "Replacing bit at $i with $($Mask[$i])"
            $MaskedValue[$i] = $Mask[$i]
        }
    }

    $MaskedValue
}

function Set-Memory {
    param(
        [int]
        $Address,

        [int]
        $Value,

        [PSCustomObject]
        $ProgramState
    )

    Write-Verbose "Setting address $Address to $Value"
    $MaskedValue = Get-MaskedValue $ProgramState.Mask $Value
    $ProgramState.Memory[$Address] = $MaskedValue
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
        Mask = [nullable[bool][]]::new(36)
        Memory = [Dictionary[int,[bool[]]]]::new()
    }

    Get-Content $FilePath | Foreach-Object {
        Interpret $_ $ProgramState
    }

    $Sum = 0
    $ProgramState.Memory.Keys | ForEach-Object {
        $Sum += ConvertTo-Int32 $ProgramState.Memory[$_]
    }
    
    $ProgramState
    $Sum
}

Invoke-Program $FilePath -Verbose