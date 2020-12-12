using namespace System.Collections.Generic

$FilePath = "$PSScriptRoot\inputs\main.txt"
$Floor = '.'
$Empty = 'L'
$Occupied = '#'

$RawContent = Get-Content $FilePath

$Rows = $RawContent.Length
$Columns = $RawContent[0].Length

$SeatingArea = [char[][]]::new($Rows)
$SeatingAreaNext = [char[][]]::new($Rows)

$RawContent | % -Begin {
    $LineIndex = 0
} -Process { 
    $CurrentLine = $_
    
    $SeatingArea[$LineIndex] = [char[]]::new($Columns)
    $SeatingAreaNext[$LineIndex] = [char[]]::new($Columns)

    for($i = 0; $i -lt $Columns; $i++) {
        $CurrentChar = $CurrentLine[$i]
        $SeatingArea[$LineIndex][$i] = $CurrentChar
        $SeatingAreaNext[$LineIndex][$i] = ' '
    }

    $LineIndex++
}

function Get-NextState {
    param(
        [char[][]]
        $SeatingArea,

        [int]
        $TotalRows,

        [int]
        $TotalColumns,

        [int]
        $Row,

        [int]
        $Column
    )

    $CurrentState = $SeatingArea[$Row][$Column]

    if($CurrentState -eq $global:Floor) {
        return $global:Floor
    }

    $MaxOccupied = 4
    $OccupiedCount = 0

    for($i = $Row - 1; $i -le $Row + 1; $i++) {
        if($i -lt 0 -or $i -ge $TotalRows) {
            continue
        }

        for($j = $Column - 1; $j -le $Column + 1; $j++) {
            if ($i -eq $Row -and $j -eq $Column) {
                continue
            }

            if($j -lt 0 -or $j -ge $TotalColumns) {
                continue
            }

            if($SeatingArea[$i][$j] -eq $global:Occupied) {
                $OccupiedCount++
            }

            if($OccupiedCount -ge $MaxOccupied) {
                return $global:Empty
            }
        }
    }

    if($OccupiedCount -eq 0) {
        return $global:Occupied
    }

    return $CurrentState
}

function Invoke-SimulationTick {
    param(
        [char[][]]
        $SeatingArea,

        [char[][]]
        $SeatingAreaNext,

        [int]
        $TotalRows,

        [int]
        $TotalColumns
    )

    $SeatingAreaChanged = $false

    for($i = 0; $i -lt $TotalRows; $i++) {
        for($j = 0; $j -lt $TotalColumns; $j++) {
            $SeatNextState = Get-NextState -SeatingArea $SeatingArea -TotalRows $TotalRows -TotalColumns $TotalColumns -Row $i -Column $j
            $SeatingAreaNext[$i][$j] = $SeatNextState

            if(!$SeatingAreaChanged -and $SeatNextState -ne $SeatingArea[$i][$j]) {
                Write-Verbose "Change detected at position $i,$j. Old: $($SeatingArea[$i][$j]) New: $SeatNextState"
                $SeatingAreaChanged = $true
            }
        }
    }

    if(!$SeatingAreaChanged) {
        Write-Verbose "No changes detected"
    }

    $SeatingAreaChanged
}

function Invoke-Simulation {
    param(
        [char[][]]
        $SeatingArea,

        [char[][]]
        $SeatingAreaNext,

        [int]
        $TotalRows,

        [int]
        $TotalColumns
    )

    $SeatingAreaChanged = $true
    $Ticks = 0

    while($SeatingAreaChanged) {
        Write-Verbose "Current tick is $Ticks"
        $SeatingAreaChanged = Invoke-SimulationTick -SeatingArea $SeatingArea -SeatingAreaNext $SeatingAreaNext -TotalRows $TotalRows -TotalColumns $TotalColumns

        $Swap = $SeatingArea
        $SeatingArea = $SeatingAreaNext
        $SeatingAreaNext = $Swap
        $Ticks++
    }
}

function Get-OccupiedSeats {
    param(
        [char[][]]
        $SeatingArea,

        [int]
        $TotalRows,

        [int]
        $TotalColumns
    )

    $OccupiedSeats = 0

    for($i = 0; $i -lt $TotalRows; $i++) {
        for($j = 0; $j -lt $TotalColumns; $j++) {
            if($SeatingArea[$i][$j] -eq $global:Occupied) {
                $OccupiedSeats++
            }
        }
    }

    $OccupiedSeats
}

Invoke-Simulation -SeatingArea $SeatingArea -SeatingAreaNext $SeatingAreaNext -TotalRows $Rows -TotalColumns $Columns
$OccupiedSeats = Get-OccupiedSeats -SeatingArea $SeatingArea -TotalRows $Rows -TotalColumns $Columns

@{
    S = $SeatingArea
    N = $SeatingAreaNext
    O = $OccupiedSeats
}