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

    $CurrentTime = [long]0

    $BusSchedules = $TravelState.BusSchedules | Sort-Object BusId -Descending

    $RelativeOffset = $BusSchedules[0].Offset

    foreach($BusSchedule in $BusSchedules) {
        $BusSchedule.Offset -= $RelativeOffset
    }

    $MaxOffset = ($BusSchedules | Select-Object -ExpandProperty Offset | Measure-Object -Minimum).Minimum

    $BusIdCount = 2
    $TimeSkip = $BusSchedules[0].BusId

    while($BusIdCount -le $BusSchedules.Length) {
        $BusIds = for($i = 0; $i -lt $BusIdCount; $i++) {
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

        if($BusIds.Length -eq $TravelState.BusSchedules.Length) {
            Write-Verbose "Bus ID length matches bus schedule length"
            break
        }
        
        if($BusIds.Length -eq $BusIdCount) {
            $TimeSkip = $TimeSkip * $BusSchedules[$BusIdCount - 1].BusId
            $BusIdCount++
            Write-Verbose "New time skip is $TimeSkip. New BusId count is $BusIdCount"
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