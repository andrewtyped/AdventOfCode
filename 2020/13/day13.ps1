$FilePath = "$PSScriptRoot\inputs\main.txt"


$RawInput = Get-Content $FilePath

$EarliestDeparture = [int]$RawInput[0]
$BusSchedules = $RawInput[1] -split ',' | % {
    if($_ -eq 'x') {
        return
    }

    [int]$_
}

$TravelState = [PSCustomObject]@{
    EarliestDeparture = $EarliestDeparture
    BusSchedules = $BusSchedules
}

function Get-Departure {
    param(
        [PSCustomObject]
        $TravelState
    )

    $BusId = $null
    $CurrentTime = $TravelState.EarliestDeparture

    while(!$BusId) {
        $BusId = $TravelState.BusSchedules | ? { $CurrentTime % $_ -eq 0 }

        if($BusId) {
            break
        }

        $CurrentTime++
    }

    [PSCustomObject]@{
        BusId = $BusId
        DepartureTime = $CurrentTime
    }
}

function Get-Phase1Answer {
    param(
        [PSCustomObject]
        $TravelState,

        [PSCustomObject]
        $DepartureState
    )

    ($DepartureState.DepartureTime - $TravelState.EarliestDeparture) * $DepartureState.BusId
}

$DepartureState = Get-Departure $TravelState
$Phase1Answer = Get-Phase1Answer $TravelState $DepartureState

[PSCustomObject]@{
    TravelState = $TravelState
    DepartureState = $DepartureState
    Phase1Answer = $Phase1Answer
}