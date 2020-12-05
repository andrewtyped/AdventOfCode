function ConvertTo-PassPort {
    [CmdletBinding()]
    param (
        [int]
        [Parameter(Mandatory)]
        $Id,

        [string]
        [Parameter(Mandatory)]
        $PassPortString
    )

    $PassPort = @{
        Id = $Id
        Raw = $PassPortString
    }

    $PassPortString -split ' ' | ForEach-Object {
        $PassportKeyValue = $_.Trim() -split ':'
        $PassPort[$PassportKeyValue[0]] = $PassportKeyValue[1]
    }
    
    $Passport
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
            $LineNumber = 1
            $AccumulatedInput = ""
        } -Process {
            $CurrentLine = $_

            if ($CurrentLine -eq "" -and $AccumulatedInput -ne "") {
                ConvertTo-PassPort -Id $LineNumber -PassportString $AccumulatedInput
                $AccumulatedInput = ""
            } else {
                $AccumulatedInput += " $CurrentLine"
            }

            $LineNumber++
        } -End {
            if($AccumulatedInput -ne "") {
                ConvertTo-PassPort -Id $LineNumber -PassportString $AccumulatedInput
            }
        }
}

function Test-PassPort {
    [CmdletBinding()]
    param(
        [PSCustomObject[]]
        [Parameter(Mandatory)]
        $PassportFields,

        [HashTable]
        [Parameter(Mandatory)]
        $Passport
    )

    foreach($PassportField in $PassportFields) {
        $Value = $Passport[$PassportField.Key]
        if(!$Value) {
            if($PassportField.Required) {
                Write-Verbose "Passport at line $($Passport.Id) is missing required field $($PassportField.Key). Raw Passport: $($Passport.Raw)"
                return $false
            }
        } else {
            $Valid = & $PassportField.Validate -Value $Value

            if(!$Valid) {
                Write-Verbose "Passport at line $($Passport.Id) has invalid field $($PassportField.Key). Value: $Value"
                return $false
            }
        }
    }

    return $true
}

function Get-ValidPassports {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath,

        [PSCustomObject[]]
        [Parameter(Mandatory)]
        $PassportFields
    )

    $ValidPassports = Import-Passports $FilePath |
        ForEach-Object {
            Test-PassPort -PassportFields $PassportFields -Passport $_
        } |
        Where-Object { $_ }

    $ValidPassports.Count
}

function Test-Range {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $Value,

        [int]
        [Parameter(Mandatory)]
        $Min,

        [int]
        [Parameter(Mandatory)]
        $Max
    )

    $Number = $Value -as [int]

    if ( $Number -ge $Min -and $Number -le $Max ) {
        return $true
    }

    return $false
}

$PassportFields = @(
    [PSCustomObject]@{
        Key = 'byr'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            Test-Range  -Value $Value -Min 1920 -Max 2002
        }
    },
    [PSCustomObject]@{
        Key = 'iyr'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            Test-Range  -Value $Value -Min 2010 -Max 2020
        }
    },
    [PSCustomObject]@{
        Key = 'eyr'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            Test-Range  -Value $Value -Min 2020 -Max 2030
        }
    },
    [PSCustomObject]@{
        Key = 'hgt'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            if ($Value -match '^(?<Number>\d+)(?<Unit>cm|in)$') {
                if ($Matches.Unit -eq 'cm') {
                    Test-Range -Value $Matches.Number -Min 150 -Max 193
                } else {
                    Test-Range -Value $Matches.Number -Min 59 -Max 76
                }
            } else {
                $false
            }
        }
    },
    [PSCustomObject]@{
        Key = 'hcl'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            $Value -match '^#[0-9a-f]{6}$'
        }
    },
    [PSCustomObject]@{
        Key = 'ecl'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            $Value -match '^amb|blu|brn|gry|grn|hzl|oth$'
        }
    },
    [PSCustomObject]@{
        Key = 'pid'
        Required = $true
        Validate = {
            param(
                [string]
                $Value
            )
            $Value -match '^\d{9}$'
        }
    },
    [PSCustomObject]@{
        Key = 'cid'
        Required = $false
        Validate = {
            $true
        }
    }
)