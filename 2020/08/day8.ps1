$Program = [PSCustomObject]@{
    Text = ""
    InstructionPointer = 0
    Acc = 0
}

function Invoke-Nop {
    $Program.InstructionPointer++
}

function Invoke-Acc {
    param(
        [int]
        $Increment
    )
    $OldAcc = $Program.Acc
    $Program.Acc += $Increment
    $Program.InstructionPointer++
    Write-Verbose "ACC: $OldAcc to $($Program.Acc) after instruction $($Program.InstructionPointer)"
}

function Invoke-Jmp {
    param(
        [int]
        $Increment
    )
    $OldInstructionPointer = $Program.InstructionPointer
    $Program.InstructionPointer += $Increment
    Write-Verbose "JMP: $OldInstructionPointer to $($Program.InstructionPointer)"
}

function Invoke-Instruction {
    param(
        [string]
        $Instruction
    )

    switch -Regex ($Instruction) {
        '^nop' {Invoke-Nop; Break}
        '^acc (?<Inc>(\+|-)\d+)$' {Invoke-Acc -Increment $Matches.Inc; Break}
        '^jmp (?<Inc>(\+|-)\d+)$' {Invoke-Jmp -Increment $Matches.Inc; Break}
        Default {
            throw "Unrecognized instruction $Instruction"
        }
    }
}

function Invoke-Program {

    $VisitedInstructions = [System.Collections.Generic.HashSet[int]]::new()
    $ProgramTerminated = $false

    while($VisitedInstructions.Add($Program.InstructionPointer)) {
        if ($Program.InstructionPointer -ge $Program.Text.Length) {
            Write-Verbose "Program terminated normally"
            $ProgramTerminated = $true
            break
        }

        Invoke-Instruction -Instruction $Program.Text[$Program.InstructionPointer]
    }

    [PSCustomObject]@{
        Terminated = $ProgramTerminated
        Acc = $Program.Acc
    }
}

function Get-SwappedInstruction {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $Instruction
    )

    switch -Regex ($Instruction) {
        '^nop (?<Inc>(\+|-)\d+)$' {"jmp $($Matches.Inc)"; Break}
        '^jmp (?<Inc>(\+|-)\d+)$' {"nop $($Matches.Inc)"; Break}
        Default {
            $Instruction
        }
    }
}

function Get-Phase1Solution {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if(!(Test-Path $FilePath)) {
        throw "Input not found at $FilePath"
    }

    $Program = [PSCustomObject]@{
        Text = ""
        InstructionPointer = 0
        Acc = 0
    }

    $Program.Text = Get-Content $FilePath

    Invoke-Program
}

function Get-Phase2Solution {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if(!(Test-Path $FilePath)) {
        throw "Input not found at $FilePath"
    }

    $Program = [PSCustomObject]@{
        Text = ""
        InstructionPointer = 0
        Acc = 0
    }

    $Program.Text = Get-Content $FilePath

    for($i = 0; $i -lt $Program.Text.Length; $i++) {
        $OriginalInstruction = $Program.Text[$i]
        $SwappedInstruction = Get-SwappedInstruction $OriginalInstruction

        if($OriginalInstruction -eq $SwappedInstruction) {
            Write-Verbose "No swap at line $i"
            continue
        }

        Write-Verbose "Line $i swapped instruction: $SwappedInstruction"
        Write-Verbose "================================================"

        $Program.Text[$i] = $SwappedInstruction
        $Program.InstructionPointer = 0
        $Program.Acc = 0

        $ProgramResults = Invoke-Program

        $Program.Text[$i] = $OriginalInstruction

        if($ProgramResults.Terminated) {
            Write-Verbose "Terminating swap found"
            break
        }
    }

    $ProgramResults.Acc
}