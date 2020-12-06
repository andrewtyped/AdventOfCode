$RowCache = @{}
$ColumnCache = @{}

function ConvertTo-BitArray {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $BoardingPassPart,

        [char]
        [Parameter(Mandatory)]
        $ZeroAlias,

        [char]
        [Parameter(Mandatory)]
        $OneAlias
    )

    $BitArray = New-Object bool[] $BoardingPassPart.Length

    for($i = 0; $i -lt $BitArray.Length; $i++) {
        $Current = $BoardingPassPart[$i]
        if($Current -eq $ZeroAlias) {
            $BitArray[$i] = $false
        } elseif ($Current -eq $OneAlias) {
            $BitArray[$i] = $true
        } else {
            throw "Unrecognized character $Current"
        }
    }

    $BitArray
}

function ConvertTo-Decimal {
    [CmdletBinding()]
    param(
        [bool[]]
        [Parameter(Mandatory)]
        $BitArray
    )

    $Number = 0
    $Pow = $BitArray.Length - 1

    foreach($Bit in $BitArray) {
        if ($Bit) {
            $Number += [Math]::Pow(2,$Pow)
        }

        $Pow--
    }

    $Number
}


function ConvertTo-SeatRowColumn {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory, ValueFromPipeline)]
        $BoardingPass,

        [int]
        [Parameter(Mandatory)]
        $ColumnStartIndex
    )

    $RowPart = $BoardingPass.Substring(0,$ColumnStartIndex)
    $ColumnPart = $BoardingPass.Substring($ColumnStartIndex)

    $Row = $RowCache[$RowPart]
    $Column = $ColumnCache[$ColumnPart]

    if (!$Row) {
        $BitArray = ConvertTo-BitArray -BoardingPassPart $RowPart -ZeroAlias 'F' -OneAlias 'B'
        $Row = ConvertTo-Decimal -BitArray $BitArray
        $RowCache[$RowPart] = $Row
    } else {
        Write-Verbose "Hit cache for row part $RowPart"
    }

    if (!$Column) {
        $BitArray = ConvertTo-BitArray -BoardingPassPart $ColumnPart -ZeroAlias 'L' -OneAlias 'R'
        $Column = ConvertTo-Decimal -BitArray $BitArray
        $ColumnCache[$ColumnPart] = $Column
    } else {
        Write-Verbose "Hit cache for column part $ColumnPart"
    }

    [PSCustomObject]@{
        Row = $Row
        Column = $Column
    }
}

function Get-SeatId {
    [CmdletBinding()]
    param(
        [int]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Row,

        [int]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Column,

        [int]
        [Parameter(Mandatory)]
        $ColumnsPerRow
    )

    $SeatId = $Row * $ColumnsPerRow + $Column

    Write-Verbose "Seat id at row, column $Row, $Column is $SeatId"

    $SeatId
}

function Get-MaxSeatId {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if (!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    Get-Content $FilePath | 
        ForEach-Object -Begin {
            $MaxSeatId = 0
        }  -Process {
            Write-Verbose "Current boarding pass is $_"
            $SeatId = ConvertTo-SeatRowColumn -BoardingPass $_ -ColumnStartIndex 7 |
                Get-SeatId -ColumnsPerRow 8

            $MaxSeatId = [Math]::Max($MaxSeatId, $SeatId)
            Write-Verbose "Current max seat id is $MaxSeatId"
        } -End {
            $MaxSeatId
        }
}

function Get-MySeatId {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if (!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    (Get-Content $FilePath | 
        ForEach-Object  -Process {
            Write-Verbose "Current boarding pass is $_"
            $SeatId = ConvertTo-SeatRowColumn -BoardingPass $_ -ColumnStartIndex 7 |
                Get-SeatId -ColumnsPerRow 8

            Write-Verbose "Current seat id is $SeatId"
            $SeatId
        }) | 
        Sort-Object | 
        ForEach-Object -Begin {
            $PreviousSeatId = $null
         } -Process {
            $SeatId = $_

            if(($SeatId - $PreviousSeatId) -eq 2) {
                $MySeatId = $SeatId - 1
                Write-Verbose "Possible seat id: $MySeatId"
                $MySeatId
            }

            $PreviousSeatId = $SeatId
         }
}