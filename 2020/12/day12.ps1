
$FilePath = "$PSScriptRoot\inputs\main.txt"

$NavigationState = [PSCustomObject]@{
    Heading = 'E'
    EastPosition = 0
    NorthPosition = 0
    HeadingOrder = "ESWN"
    HeadingIndex = 0
}

$Instructions = Get-Content $FilePath | % {

    $Command = $_[0]
    
    # R is already a powershell alias
    if($Command -eq 'R') {
        $Command = 'Right'
    }

    [PSCustomObject]@{
        Command = $Command
        Parameter = [int]$_.Substring(1)
    }
}

function N {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    $NavigationState.NorthPosition += $Parameter
}

function S {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    N $NavigationState (-1 * $Parameter)
}

function E {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    $NavigationState.EastPosition += $Parameter
}

function W {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    E $NavigationState (-1 * $Parameter)
}

function Right {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    $HeadingChanges = $Parameter / 90
    $NewHeadingIndex = ($NavigationState.HeadingIndex + $HeadingChanges) % $NavigationState.HeadingOrder.Length

    if($NewHeadingIndex -lt 0) {
        $NewHeadingIndex += $NavigationState.HeadingOrder.Length
    }

    Write-Verbose "New heading index: $NewHeadingIndex"

    $NavigationState.Heading = $NavigationState.HeadingOrder[$NewHeadingIndex]
    $NavigationState.HeadingIndex = $NewHeadingIndex
}

function L {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    Right $NavigationState (-1 * $Parameter)
}

function F {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    & $NavigationState.Heading $NavigationState $Parameter
}

function Get-ManhattanDistance {
    param(
        [PSCustomObject]
        $NavigationState
    )

    [Math]::Abs($NavigationState.EastPosition) + [Math]::Abs($NavigationState.NorthPosition)
}

function Travel {
    param(
        [PSCustomObject]
        $NavigationState,

        [PSCustomObject]
        $Instructions
    )

    $Instructions | % {
        Write-Verbose "Command: $($_.Command) Parameter: $($_.Parameter)"
        & $_.Command $NavigationState $_.Parameter
    }
}

Travel $NavigationState $Instructions

$Distance = Get-ManhattanDistance $NavigationState

@{
    FinalState = $NavigationState
    Distance = $Distance
}