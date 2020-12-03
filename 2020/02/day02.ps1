function ConvertTo-PasswordModel {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory, ValueFromPipeline)]
        $PasswordAndPolicy
    )
    Begin {
        # Match a pattern like 1-2 a: hiyakjsnjkmlkjasdjfl
        $Pattern = '^(?<Low>\d+)-(?<High>\d+)\s+(?<Char>[a-z]{1}):\s+(?<Password>[a-z]+)$'
    }
    Process {

        if ($PasswordAndPolicy -match $Pattern) {
            [PSCustomObject]@{
                Low = [int]$Matches.Low
                High = [int]$Matches.High
                Char = $Matches.Char.Trim()
                Password = $Matches.Password.Trim()
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

    $Password = $PasswordModel.Password
    $Low = $PasswordModel.Low
    $High = $PasswordModel.High
    $Char = $PasswordModel.Char

    if ($Low -gt  $Password.Length) {
        Write-Verbose "Password too short: $Password, Low: $Low"
        return $false
    }

    $Counter = 0

    foreach ($PasswordChar in [char[]]$PasswordModel.Password) {
        if ($PasswordChar -eq $Char) {
            $Counter++
        }

        if ($Counter -gt $PasswordModel.High) {
            Write-Verbose "Password exceeds length requirement: $Password, High: $High"
            return $false
        }
    }

    if ($Counter -ge $PasswordModel.Low) {
        Write-Verbose "Password is valid"
        return $true
    }

    Write-Verbose "Password doesn't meet length requirements: $Password, Counter: $Counter, Low: $Low, Char: [$Char]"
    return $false
}

function Test-PasswordPhase2 {
    [CmdletBinding()]
    param(
        [PSCustomObject]
        [Parameter(Mandatory, ValueFromPipeline)]
        $PasswordModel
    )

    $Password = $PasswordModel.Password
    $Low = $PasswordModel.Low
    $High = $PasswordModel.High
    $Char = $PasswordModel.Char

    $LowMatch = $Password.Length -ge $Low -and $Password[$Low - 1] -eq $Char
    $HighMatch = $Password.Length -ge $High -and $Password[$High -1] -eq $Char

    $Result = $LowMatch -xor $HighMatch

    Write-Verbose "Password: $Password, Low: $Low, High: $High, Char: $Char, LowChar: $($Password[$Low - 1]), HighChar: $($Password[$High -1]), Result: $Result"
    $Result
}

function Get-ValidPasswordCount {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    $Measurement = Import-Passwords -FilePath $FilePath | 
        ForEach-Object {
            Test-Password -PasswordModel $_
        } | 
        Where-Object -FilterScript { $_ } |
        Measure-Object

    $Measurement.Count

    $Measurement = Import-Passwords -FilePath $FilePath | 
        ForEach-Object {
            Test-PasswordPhase2 -PasswordModel $_
        } | 
        Where-Object -FilterScript { $_ } |
        Measure-Object

    $Measurement.Count
}