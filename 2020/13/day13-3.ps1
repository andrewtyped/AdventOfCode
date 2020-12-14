$FilePath = "$PSScriptRoot\inputs\main.txt"


$RawInput = Get-Content $FilePath

$BusSchedules = $RawInput[1] -split ',' | % -Begin {
    $Offset = 0
} -Process {
    if($_ -eq 'x') {
        $Offset++
        return
    }

    [PSCustomObject]@{
        BusId = [int]$_
        Offset = $Offset++
    }
}

$TravelState = [PSCustomObject]@{
    BusSchedules = $BusSchedules
}

function Get-Departure {
    param(
        [PSCustomObject]
        $TravelState
    )

    $CurrentTime = [long]99999999999930

    $BusSchedules = $TravelState.BusSchedules | Sort-Object BusId -Descending

    $RelativeOffset = $BusSchedules[0].Offset

    foreach($BusSchedule in $BusSchedules) {
        $BusSchedule.Offset -= $RelativeOffset
    }

    $MaxOffset = ($BusSchedules.Offset | Measure-Object -Maximum).Maximum
    $TimeSkip = $BusSchedules[0].BusId
    $ExpectedLength = $TravelState.BusSchedules.Length - 1

    while($true) {
        $BusIds = for($i = 1; $i -lt $BusSchedules.Length; $i++) {
            $Bus = $BusSchedules[$i]

            if(($CurrentTime + $Bus.Offset) % $Bus.BusId -ne 0) {
                break
            } else {
                $Bus
            }
        }

        if($CurrentTime % 1000000 -eq 0) {
            Write-Verbose "Current Time is $CurrentTime. Matching departures: $($BusIds.Length)"
        }

        if($BusIds.Length -eq $ExpectedLength) {
            break
        }

        $CurrentTime += $TimeSkip
    }

    [PSCustomObject]@{
        DepartureTime = $CurrentTime + $MaxOffset
    }
}


$DepartureState = Get-Departure $TravelState

[PSCustomObject]@{
    TravelState = $TravelState
    DepartureState = $DepartureState
}