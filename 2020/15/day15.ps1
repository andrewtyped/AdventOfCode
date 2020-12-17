using namespace System.Collections.Generic

$PuzzleInput = @(11,18,0,20,1,7,16)
$DesiredNumber = 2020


function Get-GameInitialState {
    param(
        [int[]]
        $PuzzleInput
    )

    $GameState = [PSCustomObject]@{
        SpokenNumbers = [Dictionary[int,PSCustomObject]]::new()
        LastNumberSpoken = 0
        TotalNumbersSpoken = $PuzzleInput.Length + 1 # add 1 to account for speaking '0' after the last input item
    }

    for($i = 1; $i -le $PuzzleInput.Length; $i++) {
        $Number = $PuzzleInput[$i - 1]
        $Queue = [Queue[int]]::new()
        $Queue.Enqueue($i)
        $GameState.SpokenNumbers[$Number] = [PSCustomObject]@{
            TurnsSpoken = $Queue
        }
    }

    $GameState
}

function Solve-Puzzle {
    param(
        [int[]]
        $PuzzleInput
    )

    $GameState = Get-GameInitialState $PuzzleInput

    for($i = $GameState.TotalNumbersSpoken; $i -lt 30000000; $i++) {

        $LastSpoken = $GameState.LastNumberSpoken
        if($GameState.SpokenNumbers.ContainsKey($LastSpoken)) {
            $SpokenNumber = $GameState.SpokenNumbers[$LastSpoken]
            $PreviousSpokenTurn = $SpokenNumber.TurnsSpoken.Dequeue()
            $SpokenNumber.TurnsSpoken.Enqueue($i)
            $GameState.LastNumberSpoken = $i - $PreviousSpokenTurn

            Write-Verbose "Previous number repeated. LastSpoken: $LastSpoken. Previous turn: $PreviousSpokenTurn. This turn: $i. New last spoken: $($GameState.LastNumberSpoken)"
        } else {
            $Queue = [Queue[int]]::new()
            $Queue.Enqueue($i)
            $GameState.SpokenNumbers[$LastSpoken] = [PSCustomObject]@{
                TurnsSpoken = $Queue
            }
            $GameState.LastNumberSpoken = 0

            Write-Verbose "New number spoken: $LastSpoken. New last spoken is 0. This turn: $i"
        }

        $GameState.TotalNumbersSpoken++
    }

    $GameState
}


$PuzzleInput = @(11,18,0,20,1,7,16)
$PuzzleInput2 = @(0,3,6)
Solve-Puzzle $PuzzleInput