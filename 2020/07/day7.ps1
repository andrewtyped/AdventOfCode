using namespace System.Collections.Generic;

$BaseRegex = '^(\w+ \w+) bags contain (((\d+) (\w+ \w+) bag(s?)(, |\.))+|no other bags\.)$'
$InnerBagRegex = '(?<BagCount>\d+) (?<Color>\w+ \w+)'

$BagGraph = [Dictionary[string,List[PSCustomObject]]]::new()

function Import-ReverseBagRule {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $BagInput
    )

    $ParentChildSplit = $BagInput.Trim('.') -split " bags contain "
    $OuterBag = $ParentChildSplit[0]
    $Children = $ParentChildSplit[1] -split ", "

    foreach($ChildBag in $Children) {
        if($ChildBag -match $InnerBagRegex) {
            $InnerBag = [PSCustomObject]@{
                Count = [int]$Matches.BagCount
                Color = $Matches.Color
                OuterBag = $OuterBag
            }

            $OuterBagEdges = [List[PSCustomObject]]::new()

            if($BagGraph.TryGetValue($InnerBag.Color, [ref]$OuterBagEdges )) {
                Write-Verbose "Adding new outer bag $OuterBag for existing inner bag $($InnerBag.Color)"
                $OuterBagEdges.Add($InnerBag)
            } else {
                Write-Verbose "Adding new outer bag $OuterBag for new inner bag $($InnerBag.Color)"
                $OuterBagEdges = [List[PSCustomObject]]::new()
                $OuterBagEdges.Add($InnerBag)
                $BagGraph[$InnerBag.Color] = $OuterBagEdges
            }
        }
    }
}

function Get-ShinyGoldBagContainerCount {
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
            Import-ReverseBagRule -BagInput $_
        }

    $VisitedRules = [HashSet[string]]::new()
    $RulesToVisit = [Queue[string]]::new()
    $RulesToVisit.Enqueue('shiny gold')
    $Current = 'shiny gold'

    do {
        $Current = $RulesToVisit.Dequeue()

        if ($VisitedRules.Add($Current)) {
            Write-Verbose "Visting bag $Current..."
            $OuterBags = [List[PSCustomObject]]::new()
            if ($BagGraph.TryGetValue($Current, [ref] $OuterBags)) {
                foreach($OuterBag in $OuterBags) {
                    Write-Verbose "Queueing bag $($OuterBag.OuterBag) for visit..."
                    $RulesToVisit.Enqueue($OuterBag.OuterBag)
                }
            }
        }
    } while ($RulesToVisit.Count -gt 0)

    #subtract entry for shiny gold since it isn't its own container
    $VisitedRules.Count - 1
}