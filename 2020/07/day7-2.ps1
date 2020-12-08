using namespace System.Collections.Generic;

$BaseRegex = '^(\w+ \w+) bags contain (((\d+) (\w+ \w+) bag(s?)(, |\.))+|no other bags\.)$'
$InnerBagRegex = '(?<BagCount>\d+) (?<Color>\w+ \w+)'

$BagGraph = [Dictionary[string,List[PSCustomObject]]]::new()

function Import-BagRule {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $BagInput
    )

    $ParentChildSplit = $BagInput.Trim('.') -split " bags contain "
    $OuterBag = $ParentChildSplit[0]
    $Children = $ParentChildSplit[1] -split ", "

    Write-Verbose "Adding new outer bag $OuterBag"
    $InnerBagEdges = [List[PSCustomObject]]::new()
    $BagGraph[$OuterBag] = $InnerBagEdges

    foreach($ChildBag in $Children) {
        if($ChildBag -match $InnerBagRegex) {
            $InnerBag = [PSCustomObject]@{
                Count = [int]$Matches.BagCount
                Color = $Matches.Color
                OuterBag = $OuterBag
            }

            Write-Verbose "Outer bag $OuterBag requires inner bag with color $($InnerBag.Color)"
            $InnerBagEdges.Add($InnerBag)
        }
    }
}

function Get-ShinyGoldBagChildBagCount {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if (!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    Get-Content -Path $FilePath | 
        ForEach-Object {
            Import-BagRule -BagInput $_
        }

    #$VisitedRules = [HashSet[string]]::new()
    $RulesToVisit = [Queue[PSCustomObject]]::new()
    $RulesToVisit.Enqueue([PSCustomObject]@{
        Color = 'shiny gold'
        Multiplier = 1
    })
    $Current = 'shiny gold'
    $Sum = 0

    do {
        $Current = $RulesToVisit.Dequeue()
        $Sum += $Current.Multiplier

        Write-Verbose "Visting bag $Current..."
        $InnerBags = [List[PSCustomObject]]::new()
        if ($BagGraph.TryGetValue($Current.Color, [ref] $InnerBags)) {
            foreach($InnerBag in $InnerBags) {
                Write-Verbose "Queueing bag $($InnerBag.Color) for visit..."
                $RulesToVisit.Enqueue([PSCustomObject]@{
                    Color = $InnerBag.Color
                    Multiplier = $Current.Multiplier * $InnerBag.Count
                })
            }
        }
    } while ($RulesToVisit.Count -gt 0)

    $Sum - 1
}