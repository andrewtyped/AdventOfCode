function ConvertTo-PasswordModel {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory, ValueFromPipeline)]
        $PasswordAndPolicy
    )
    Begin {
        # Match a pattern like 1-2 a: hiyakjsnjkmlkjasdjfl
        $Pattern = '^(?<Low>\d+)-(?<High>\d)+\s+(?<Char>[a-z]{1}):\s+(?<Password>[a-z]+)$'
    }
    Process {

        if ($PasswordAndPolicy -match $Pattern) {
            [PSCustomObject]@{
                Low = [int]$Matches.Low
                High = [int]$Matches.High
                Char = $Matches.Char
                Password = $Matches.Password
            }
        } else {
            throw "Input $PasswordAndPolicy is malformed, must match $Pattern"
        }

    }
}

function Import-Passwords {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if(!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    Get-Content $FilePath | ConvertTo-PasswordModel
}

function Test-Password {
    [CmdletBinding()]
    param(
        [PSCustomObject]
        [Parameter(Mandatory, ValueFromPipeline)]
        $PasswordModel
    )

    
}