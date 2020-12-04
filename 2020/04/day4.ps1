function ConvertTo-PassPort {
    [CmdletBinding()]
    param (
        [string]
        [Parameter(Mandatory)]
        $PassPortString
    )

    throw "Not Implemented"
    
}

function Import-Passports {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if (!(Test-Path $FilePath)) {
        throw "Passport file not found at $FilePath"
    }

    Get-Content -Path $FilePath |
        ForEach-Object -Begin {
            $AccumulatedInput = ""
        } -Process {
            $CurrentLine = $_

            if ($CurrentLine -eq "") {
                ConvertTo-PassPort $AccumulatedInput
                $AccumulatedInput = ""
            } else {
                $AccumulatedInput += " $CurrentLine"
            }
        }
}

$PassportFields = @(
    [PSCustomObject]@{
        Key = 'byr'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'iyr'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'eyr'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'hgt'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'hcl'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'ecl'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'pid'
        Required = $true
    },
    [PSCustomObject]@{
        Key = 'cid'
        Required = $false
    }
)