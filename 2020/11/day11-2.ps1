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

function Get-SeatId {
    param(
        [int]
        $Row,

        [int]
        $Column,

        [int]
        $TotalRows
    )

    $Row * $TotalRows + $Column
}

function Get-SeatRowColumn {
    param(
        [int]
        $SeatId,

        [int]
        $TotalRows
    )

    $Column = $SeatId % $TotalRows
    $Row = ($SeatId - $Column) / $TotalRows

    $Row
    $Column
}

function Get-SeatAdjacencyList {
    param(
        [char[][]]
        $SeatingArea,

        [int]
        $TotalRows,

        [int]
        $TotalColumns
    )

    $SeatAdjacencyList = @{}

    for($i = 0; $i -lt $TotalRows; $i++) {
        for($j = 0; $j -lt $TotalColumns; $j++) {
            $CurrentSeat = $SeatingArea[$i][$j]
            $SeatId = Get-SeatId $i $j $TotalRows

            if($CurrentSeat -eq $global:Floor) {
                continue
            }

            $AdjacencyList = [List[int]]::new()

            if(!$SeatAdjacencyList[$SeatId]) {
                Write-Verbose "Creating empty adjacency list for seat $SeatId"
                $SeatAdjacencyList[$SeatId] = $AdjacencyList
            }

            $LeftAdjacency = $null
            $RightAdjacency = $null
            $TopAdjacency = $null
            $BottomAdjacency = $null
            $LeftTopAdjacency = $null
            $RightTopAdjacency = $null
            $LeftBottomAdjacency = $null
            $RightBottomAdjacency = $null

            #Left Right Adjacency
            for($i1 = 0; $i1 -lt $TotalColumns; $i1++) {
                if($i1 -eq $j) {
                    if($null -ne $LeftAdjacency) {
                        Write-Verbose "Seat $SeatId LeftAdjacency: $LeftAdjacency"
                        $AdjacencyList.Add($LeftAdjacency)
                    }

                    continue
                }

                $AdjacentSeat = $SeatingArea[$i][$i1]

                if($AdjacentSeat -eq $global:Floor) {
                    continue
                }

                if($i1 -gt $j) {
                    $RightAdjacency = Get-SeatId $i $i1 $TotalRows
                    Write-Verbose "Seat $SeatId RightAdjacency: $RightAdjacency"
                    $AdjacencyList.Add($RightAdjacency)
                    break
                } else {
                    $LeftAdjacency = Get-SeatId $i $i1 $TotalRows
                }

            }

            #Top Bottom Adjacency
            for($i1 = 0; $i1 -lt $TotalRows; $i1++) {
                if($i1 -eq $i) {
                    if($null -ne $TopAdjacency) {
                        $AdjacencyList.Add($TopAdjacency)
                    }

                    continue
                }

                $AdjacentSeat = $SeatingArea[$i1][$j]

                if($AdjacentSeat -eq $global:Floor) {
                    continue
                }

                if($i1 -gt $i) {
                    $BottomAdjacency = Get-SeatId $i1 $j $TotalRows
                    $AdjacencyList.Add($BottomAdjacency)
                    break
                } else {
                    $TopAdjacency = Get-SeatId $i1 $j $TotalRows
                }
            }

            #LeftTop Adj

            $i1 = $i - 1
            $j1 = $j - 1

            while($i1 -ge 0 -and $j1 -ge 0) {
                $AdjacentSeat = $SeatingArea[$i1][$j1]

                if($AdjacentSeat -eq $global:Floor) {
                    $i1--
                    $j1--
                    continue
                }

                $LeftTopAdjacency = Get-SeatId $i1 $j1 $TotalRows
                $AdjacencyList.Add($LeftTopAdjacency)
                break
            }

            #RightTop Adj

            $i1 = $i - 1
            $j1 = $j + 1

            while($i1 -ge 0 -and $j1 -lt $TotalColumns) {
                $AdjacentSeat = $SeatingArea[$i1][$j1]

                if($AdjacentSeat -eq $global:Floor) {
                    $i1--
                    $j1++
                    continue
                }

                $RightTopAdjacency = Get-SeatId $i1 $j1 $TotalRows
                $AdjacencyList.Add($RightTopAdjacency)
                break
            }

            #LeftBot Adj

            $i1 = $i + 1
            $j1 = $j - 1

            while($i1 -lt $TotalRows -and $j1 -ge 0) {
                $AdjacentSeat = $SeatingArea[$i1][$j1]

                if($AdjacentSeat -eq $global:Floor) {
                    $i1++
                    $j1--
                    continue
                }

                $LeftBottomAdjacency = Get-SeatId $i1 $j1 $TotalRows
                $AdjacencyList.Add($LeftBottomAdjacency)
                break
            }

            # RightBot Adj

            $i1 = $i + 1
            $j1 = $j + 1

            while($i1 -lt $TotalRows -and $j1 -lt $TotalColumns) {
                $AdjacentSeat = $SeatingArea[$i1][$j1]

                if($AdjacentSeat -eq $global:Floor) {
                    $i1++
                    $j1++
                    continue
                }

                $RightBottomAdjacency = Get-SeatId $i1 $j1 $TotalRows
                $AdjacencyList.Add($RightBottomAdjacency)
                break
            }
        }
    }

    $SeatAdjacencyList
}

function Get-NextState {
    param(
        [char[][]]
        $SeatingArea,

        [hashtable]
        $SeatAdjacencyList,

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

    $MaxOccupied = 5
    $OccupiedCount = 0
    $SeatId = Get-SeatId $Row $Column $TotalRows
    $Adjacencies = $SeatAdjacencyList[$SeatId]

    foreach($Adjacency in $Adjacencies) {
        $SeatRowColumn = Get-SeatRowColumn $Adjacency $TotalRows

        $AdjacencyState = $SeatingArea[$SeatRowColumn[0]][$SeatRowColumn[1]]

        if($AdjacencyState -eq $global:Occupied) {
            $OccupiedCount++
        }

        if($OccupiedCount -ge $MaxOccupied) {
            $global:Empty 
            return
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

        [HashTable]
        $SeatAdjacencyList,

        [int]
        $TotalRows,

        [int]
        $TotalColumns
    )

    $SeatingAreaChanged = $false

    for($i = 0; $i -lt $TotalRows; $i++) {
        for($j = 0; $j -lt $TotalColumns; $j++) {
            $SeatNextState = Get-NextState -SeatingArea $SeatingArea -SeatAdjacencyList $SeatAdjacencyList -TotalRows $TotalRows -TotalColumns $TotalColumns -Row $i -Column $j
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

        [HashTable]
        $SeatAdjacencyList,

        [int]
        $TotalRows,

        [int]
        $TotalColumns
    )

    $SeatingAreaChanged = $true
    $Ticks = 0

    while($SeatingAreaChanged) {
        Write-Verbose "Current tick is $Ticks"
        $SeatingAreaChanged = Invoke-SimulationTick -SeatingArea $SeatingArea -SeatingAreaNext $SeatingAreaNext -SeatAdjacencyList $SeatAdjacencyList -TotalRows $TotalRows -TotalColumns $TotalColumns

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

$SeatAdjacencyList = Get-SeatAdjacencyList -SeatingArea $SeatingArea -TotalRows $Rows -TotalColumns $Columns
Invoke-Simulation -SeatingArea $SeatingArea -SeatingAreaNext $SeatingAreaNext -SeatAdjacencyList $SeatAdjacencyList -TotalRows $Rows -TotalColumns $Columns
$OccupiedSeats = Get-OccupiedSeats -SeatingArea $SeatingArea -TotalRows $Rows -TotalColumns $Columns

@{
    Sal = $SeatAdjacencyList
    S = $SeatingArea
    O = $OccupiedSeats
}