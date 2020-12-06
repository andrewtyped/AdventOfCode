#Require -Version 5.0

using namespace System.Collections.Generic;

function Add-Range {
    [CmdletBinding()]
    param(
        [HashSet[char]]
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        $Collection,

        [string]
        [Parameter(Mandatory)]
        $Answers
    )

    for($i = 0; $i -lt $Answers.Length; $i++) {
        $null = $Collection.Add($Answers[$i])
    }
}

function Remove-NonIntersectingAnswers {
    [CmdletBinding()]
    param(
        [HashSet[char]]
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        $Collection,

        [string]
        [Parameter(Mandatory)]
        $Answers
    )

    $IntersectedCollection = [HashSet[char]]::new()

    Write-Verbose "Removing non-intersecting items given new answers $Answers..."
    foreach($Item in $Collection) {
        if ($Answers.Contains($Item)) {
            Write-Verbose "Adding $Item to intersected collection..."
            $null = $IntersectedCollection.Add($Item)
        }
    }

    # PowerShell gotcha! If this function results in an empty collection, we must use the unary ',' 
    # operator to force Powershell to return an empty collection. Otherwise it will return null.
    ,$IntersectedCollection
}

function Get-TotalYesAnswerSum {
    [CmdletBinding()]
    param (
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if(!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    Get-Content $FilePath |
        ForEach-Object -Begin {
            $YesAnswers = [HashSet[char]]::new()
            $LineNumber = 1
            $TotalCount = 0
        } -Process {
            $CurrentLine = $_

            if ($CurrentLine -eq "") {
                Write-Verbose "Yes answers for group before line ${LineNumber}: $($YesAnswers.Count)"
                $TotalCount += $YesAnswers.Count
                $YesAnswers.Clear()
            } else {
                Add-Range -Collection $YesAnswers -Answers $CurrentLine
            }

            $LineNumber++
        } -End {
            if($AccumulatedInput -ne "") {
                Write-Verbose "Yes answers for group before line ${LineNumber}: $($YesAnswers.Count)"
                Add-Range -Collection $YesAnswers -Answers $CurrentLine
                $TotalCount += $YesAnswers.Count
            }

            $TotalCount
        }
}

function Get-TotalGroupUnanimousYesAnswerSum {
    [CmdletBinding()]
    param (
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if(!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    Get-Content $FilePath |
        ForEach-Object -Begin {
            $UnanimousYesAnswers = [HashSet[char]]::new()
            $LineNumber = 1
            $TotalCount = 0
            $NewGroupStarted = $true
        } -Process {
            $CurrentLine = $_

            if ($CurrentLine -eq "") {
                Write-Verbose "Yes answers for group before line ${LineNumber}: $($UnanimousYesAnswers.Count)"
                $TotalCount += $UnanimousYesAnswers.Count
                $UnanimousYesAnswers.Clear()
                $NewGroupStarted = $true
            } elseif ($NewGroupStarted) {
                # The first group member's answers contain the only possibilities for the group's unanimous yes answers.
                Write-Verbose "New group started. Possible unanimous yes answers: $CurrentLine"
                $NewGroupStarted = $false
                Add-Range -Collection $UnanimousYesAnswers -Answers $CurrentLine
            } else {
                # Strip answers from the first group member that don't appear in this group member's answers.
                Write-Verbose "Stripping non-unanimous answers..."
                $UnanimousYesAnswers = Remove-NonIntersectingAnswers -Collection $UnanimousYesAnswers -Answers $CurrentLine
            }

            $LineNumber++
        } -End {
            if($UnanimousYesAnswers.Count -gt 0) {
                Write-Verbose "Yes answers for group before line ${LineNumber}: $($UnanimousYesAnswers.Count)"
                $TotalCount += $UnanimousYesAnswers.Count
            }

            $TotalCount
        }
}