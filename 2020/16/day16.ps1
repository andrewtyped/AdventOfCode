using namespace System.Collections.Generic;


function Import-Rule {
    param(
        [string]
        $RawInput
    )

    $Pattern = "^(?<Rule>[a-z ]+): (?<N1>\d+)-(?<N2>\d+) or (?<N3>\d+)-(?<N4>\d+)$"

    if($RawInput -match $Pattern) {
        [PSCustomObject]@{
            RuleName = $Matches.Rule
            Numbers = [PSCustomObject]@{
                N1 = $Matches.N1
                N2 = $Matches.N2
                N3 = $Matches.N3
                N4 = $Matches.N4
            }
        }
    } else {
        throw "$RawInput does not match expected pattern"
    }
}

function Import-Ticket {
    param(
        [string]
        $RawInput
    )

    $Pattern = "^[0-9,]+$"

    $Numbers = [List[int]]::new()

    if($RawInput -match $Pattern) {
        $RawInput -split ',' | % {
            $Numbers.Add($_)
        }

        return $Numbers
    } else {
        return $null
    }
}

function Import-Data {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    $Sections = @(
        'Rules',
        'MyTicket',
        'OtherTicket'
    )

    $SectionIndex = 0

    $Rules = [Dictionary[string,[PSCustomObject]]]::new()
    $ValidNumbers = [HashSet[int]]::new()
    $MyTicket = [List[int]]::new()
    $OtherTickets = [List[List[int]]]::new()

    Get-Content $FilePath | % {

        if($_ -eq '') {
            $SectionIndex++
            return
        }

        $CurrentSection = $Sections[$SectionIndex]

        if($CurrentSection -eq 'Rules') {
            $Rule = Import-Rule $_
            $Rules[$Rule.RuleName] = $Rule.Numbers

            $Rule.Numbers.N1..$Rule.Numbers.N2 | % {
                $null = $ValidNumbers.Add($_)
            }

            $Rule.Numbers.N3..$Rule.Numbers.N4 | % {
                $null = $ValidNumbers.Add($_)
            }

        } elseif ($CurrentSection -eq 'MyTicket') {
            $TicketNumbers = Import-Ticket $_

            if($TicketNumbers) {
                $MyTicket = $TicketNumbers
            }
        } elseif ($CurrentSection -eq 'OtherTicket') {
            $TicketNumbers = Import-Ticket $_

            if($TicketNumbers) {
                $OtherTickets.Add($TicketNumbers)
            }
        }
    }

    [PSCustomObject]@{
        Rules = $Rules
        MyTicket = $MyTicket
        OtherTickets = $OtherTickets
        ValidNumbers = $ValidNumbers
    }
}

function Get-TicketErrorRate {
    [CmdletBinding()]
    param(
        [PSCustomObject]
        [Parameter(Mandatory)]
        $InputData
    )

    $TicketErrorRate = 0

    $InputData.OtherTickets | %{
        $_ | % {
            if(!$InputData.ValidNumbers.Contains($_)) {
                $TicketErrorRate += $_
            }
        }
    }

    $TicketErrorRate
}

function Remove-InvalidTickets {
    param(
        [PSCustomObject]
        [Parameter(Mandatory)]
        $InputData
    )

    $OtherTicketsToKeep = [List[List[int]]]::new()

    for($i = 0; $i -lt $InputData.OtherTickets.Count; $i++) {
        $Skip = foreach($Item in $InputData.OtherTickets[$i]) {
            if(!$InputData.ValidNumbers.Contains($Item)) {
                $true
                break
            }
        }

        if(!$Skip) {
            $OtherTicketsToKeep.Add($InputData.OtherTickets[$i])
        }
    }

    $InputData.OtherTickets = $OtherTicketsToKeep
}



function Get-ApplicableRules {
    param(
        [PSCustomObject]
        $InputData
    )

    $TicketPositionRules = [Dictionary[int,HashSet[string]]]::new()
    $TicketPosition = 0

    while($TicketPosition -lt $InputData.OtherTickets[0].Count) {
        $TicketPositionRulesList = [HashSet[string]]::new()
        $TicketPositionRules[$TicketPosition] = $TicketPositionRulesList

        $InputData.Rules.Keys | % {
            $null = $TicketPositionRulesList.Add($_)
        }

        foreach($Ticket in $InputData.OtherTickets) {
            $InputData.Rules.Keys | % {
                $RuleNumbers = $InputData.Rules[$_]

                $TicketNumber = $Ticket[$TicketPosition]

                $InRange1 = $TicketNumber -ge $RuleNumbers.N1 -and $TicketNumber -le $RuleNumbers.N2
                $InRange2 = $TicketNumber -ge $RuleNumbers.N3 -and $TicketNumber -le $RuleNumbers.N4

                if(!($InRange1 -or $InRange2)) {
                    $null = $TicketPositionRulesList.Remove($_)
                }
            }
        }

        $TicketPosition++
    }

    $TicketPositionRules
}

function Get-FinalRules {
    param(
        [Dictionary[int, HashSet[string]]]
        $ApplicableRules
    )

    $FinalRules = [Dictionary[int,string]]::new()
    $RequiredRuleCount = $ApplicableRules.Keys.Count

    while($FinalRules.Count -lt $RequiredRuleCount) {
        $ApplicableRules.Keys | % {
            $ApplicableRulesList = $ApplicableRules[$_]

            if($ApplicableRulesList.Count -eq 1) {
                $RuleToRemove = ($ApplicableRulesList | Select-Object -First 1)
                $KeyToRemove = $_
                Write-Verbose "Rule to remove is $RuleToRemove. Key to remove is $KeyToRemove."
                $FinalRules[$_] = $RuleToRemove
            }

        }

        Write-Verbose "Removing key $KeyToRemove"
        $null = $ApplicableRules.Remove($KeyToRemove)

        $ApplicableRules.Keys | % {
            Write-Verbose "Removing $RuletoRemove from $_"
            $null = $ApplicableRules[$_].Remove($RuleToRemove)
        }
    }

    return $FinalRules
}

function Get-DepartureFieldsProduct {
    param(
        [List[int]]
        $Ticket,

        [Dictionary[int, string]]
        $Rules
    )

    $Product = 1

    for($i = 0; $i -lt $Ticket.Count; $i++) {
        $Rule = $Rules[$i]

        if($Rule -match "^departure") {
            $Product *= $Ticket[$i]
        }
    }

    $Product
}

$FilePath = "$PSScriptRoot\inputs\main.txt"
$InputData = Import-Data $FilePath
$ErrorRate = Get-TicketErrorRate $InputData
Remove-InvalidTickets $InputData
$TicketPositionRules = Get-ApplicableRules $InputData
$FinalRules = Get-FinalRules $TicketPositionRules
$Product = Get-DepartureFieldsProduct $InputData.MyTicket $FinalRules

[PSCustomObject]@{
    InputData = $InputData
    ErrorRate = $ErrorRate
    TicketPositionRules = $TicketPositionRules
    FinalRules = $FinalRules
    Product = $Product
}