function Import-TreeLine {
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath
    )

    if(!(Test-Path $FilePath)) {
        throw "Input file not found at $FilePath"
    }

    Get-Content $FilePath
}


function Get-NextX {
    param(
        [int]
        [Parameter(Mandatory)]
        $SlopeWidth,

        [int]
        [Parameter(Mandatory)]
        $SlopeX,

        [int]
        [Parameter(Mandatory)]
        $CurrentX
    )

    $NextX = $CurrentX + $SlopeX

    if ($NextX -ge $SlopeWidth) {
        $NextX = $NextX % $SlopeWidth
    }

    $NextX
}

function Get-TreeCollisionCount {
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath,

        [int]
        [Parameter(Mandatory)]
        $SlopeX,

        [int]
        [Parameter(Mandatory)]
        $SlopeY
    )

    Import-TreeLine -FilePath $FilePath |
        ForEach-Object -Begin {
            $NextX = $SlopeX
            $NextY = $SlopeY
            $TreeCount = 0
            $CurrentY = 0
            $CurrentX = 0
        } -Process {
            if ($CurrentY -ne $NextY) {
                Write-Verbose "Skipping line. Current Y is $CurrentY, next Y is $NextY"
                $CurrentY++
                return
            }

            $CurrentLine = $_
            $SlopeWidth = $CurrentLine.Length
            $CurrentX = Get-NextX -SlopeWidth $SlopeWidth -SlopeX $SLopeX -CurrentX $CurrentX

            if ($CurrentLine[$CurrentX] -eq '#') {
                Write-Verbose "Tree collision at X:$CurrentX Y:$CurrentY"
                $TreeCount++
            } else {
                Write-Verbose "No tree at X:$CurrentX Y:$CurrentY"
            }

            $CurrentY++
            $NextY += $SlopeY
        } -End {
            $TreeCount
        }
}

function Get-TreeCollisionProduct {
    param(
        [string]
        [Parameter(Mandatory)]
        $FilePath,

        [int]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $SlopeX,

        [int]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $SlopeY
    )

    Begin {
        $Product = 1
    }

    Process {
        $TreeCount = Get-TreeCollisionCount -FilePath $FilePath -SlopeX $SlopeX -SlopeY $SlopeY
        $Product *= $TreeCount

        Write-Verbose "Tree Count for slope X: $SlopeX Y: $SlopeY is $TreeCount. CurrentProduct is $Product"
    }

    End {
        Write-Verbose "Final product is $Product"
        $Product
    }
}

$Part2Slopes = @(
    [PSCustomObject]@{
        SlopeX = 1
        SlopeY = 1
    },
    [PSCustomObject]@{
        SlopeX = 3
        SlopeY = 1
    },
    [PSCustomObject]@{
        SlopeX = 5
        SlopeY = 1
    },
    [PSCustomObject]@{
        SlopeX = 7
        SlopeY = 1
    },
    [PSCustomObject]@{
        SlopeX = 1
        SlopeY = 2
    }
)