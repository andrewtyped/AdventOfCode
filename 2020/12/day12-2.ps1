
$FilePath = "$PSScriptRoot\inputs\main.txt"

$NavigationState = [PSCustomObject]@{
    Heading = 'E'
    EastPosition = 0
    NorthPosition = 0
    WaypointEastPosition = 10
    WaypointNorthPosition = 1
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

function Get-Radians {
    param(
        [int]
        $Degrees
    )

    ([Math]::PI / 180.0) * $Degrees
}

function N {
    param(
        [PSCustomObject]
        $NavigationState,

        [int]
        $Parameter
    )

    $NavigationState.WaypointNorthPosition += $Parameter
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

    $NavigationState.WaypointEastPosition += $Parameter
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

    $Angle = Get-Radians (-1 * $Parameter)
    $Sin = [Math]::Sin($Angle)
    $Cos = [Math]::Cos($Angle)

    $WaypointEastTranslation = $NavigationState.WaypointEastPosition - $NavigationState.EastPosition
    $WaypointNorthTranslation = $NavigationState.WaypointNorthPosition - $NavigationState.NorthPosition

    Write-Verbose "Translation: East $WaypointEastTranslation North $WaypointNorthTranslation"

    $WaypointEastRotation = $WaypointEastTranslation * $Cos - $WaypointNorthTranslation * $Sin
    $WaypointNorthRotation = $WaypointEastTranslation * $Sin + $WaypointNorthTranslation * $Cos

    $NavigationState.WaypointEastPosition = $WaypointEastRotation + $NavigationState.EastPosition
    $NavigationState.WaypointNorthPosition = $WaypointNorthRotation + $NavigationState.NorthPosition

    Write-Verbose "WayEast: $($NavigationState.WaypointEastPosition) WayNorth: $($NavigationState.WaypointNorthPosition)"
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

    $EastDiff = $NavigationState.WaypointEastPosition - $NavigationState.EastPosition
    $NorthDiff = $NavigationState.WaypointNorthPosition - $NavigationState.NorthPosition

    for($i = 0; $i -lt $Parameter; $i++) {
        $NavigationState.EastPosition += $EastDiff
        $NavigationState.NorthPosition += $NorthDiff
        $NavigationState.WaypointEastPosition += $EastDiff
        $NavigationState.WaypointNorthPosition += $NorthDiff
    }

    Write-Verbose "East: $($NavigationState.EastPosition) North: $($NavigationState.NorthPosition) WayEast: $($NavigationState.WaypointEastPosition) WayNorth: $($NavigationState.WaypointNorthPosition)"
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