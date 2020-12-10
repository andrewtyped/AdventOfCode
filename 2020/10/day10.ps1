using namespace System.Collections.Generic;
using namespace System.Numerics;

$File = "$PSScriptRoot\inputs\main.txt"

$Adapters = Get-Content $File | %{ [int]$_} | Sort-Object 

$Adapters | % -Begin {
    $OneJoltDifferences = 0
    $ThreeJoltDifferences = 0
    $PreviousJolt = 0
} -Process {

    $Difference = $_ - $PreviousJolt

    if($Difference -eq 1) {
        $OneJoltDifferences++
    }
    elseif($Difference -eq 3) {
        $ThreeJoltDifferences++
    }

    $PreviousJolt = $_
} -End {
    $ThreeJoltDifferences++
}

$JoltDistribution = $OneJoltDifferences * $ThreeJoltDifferences

$ChargingOutletJolts = 0
$DeviceAdapterJolts = $Adapters[$Adapters.Length - 1] + 3

$Adapters = @($ChargingOutletJolts) + $Adapters + @($DeviceAdapterJolts)

$AdapterGraph = [Dictionary[int,List[int]]]::new()
#$AdapterGraph[$DeviceAdapterJolts] = [List[int]]::new()

for($i = 0; $i -lt $Adapters.Length - 1; $i++) {
    $iJolts = $Adapters[$i]
    for($j = $i + 1; $j -lt $Adapters.Length; $j++) {
        $jJolts = $Adapters[$j]

        if($jJolts - $iJolts -gt 3) {
            break
        }

        $LinkedAdapters = [List[int]]::new()

        if($AdapterGraph.TryGetValue($iJolts, [ref]$LinkedAdapters)) {
            $AdapterGraph[$iJolts].Add($jJolts)
        } else {
            $LinkedAdapters = [List[int]]::new()
            $LinkedAdapters.Add($jJolts)
            $AdapterGraph[$iJolts] = $LinkedAdapters
        }
    }
}



function FindAllPathsRec {
    param(
        [HashSet[int]]
        $Visited,

        [Dictionary[int, List[int]]]
        $AdapterGraph,

        [int]
        $Current,

        [int]
        $Destination,

        [BigInteger]
        $PathsFound,

        [string]
        $CurrentPath,

        [Dictionary[int,BigInteger]]
        $Cache
    )

    $null = $Visited.Add($Current)
    $CurrentPath += "$Current "

    try
    {
        $CachedValue = 0
        if($Cache.TryGetValue($Current, [ref]$CachedValue)) {
            Write-Verbose "Cache hit for $Current : $CachedValue"
            return $CachedValue
        }
        elseif($Current -eq $Destination) {
            Write-Verbose "Path found: $CurrentPath"
            return 1
        }
        else {
            $Edges = $AdapterGraph[$Current]

            foreach($Edge in $Edges) {
                if(!$Visited.Contains($Edge)) {
                    $EdgePathsFound = FindAllPathsRec -Visited $Visited -AdapterGraph $AdapterGraph -Current $Edge -Destination $Destination -PathsFound $PathsFound -CurrentPath $CurrentPath -Cache $Cache
                    $Cache[$Edge] = $EdgePathsFound
                    $PathsFound =[BigInteger]::Add($PathsFound, $EdgePathsFound)
                }
            }

            return $PathsFound
        }
    }
    finally {
        $CurrentPath = $CurrentPath.Substring(0,$CurrentPath.Length - 2)
        $null = $Visited.Remove($Current)
    }
}


function FindAllPaths {
    param(
        [int]
        $Destination,

        [Dictionary[int,List[int]]]
        $AdapterGraph
    )
    $Visited = [HashSet[int]]::new()
    $Cache = [Dictionary[int,BigInteger]]::new()
    $Start = 0

    FindAllPathsRec -Visited $Visited -AdapterGraph $AdapterGraph -Current $Start -Destination $Destination -PathsFound 0 -Cache $Cache
}

$AdapterCombinations = FindAllPaths -Destination $DeviceAdapterJolts -AdapterGraph $AdapterGraph


@{
    JoltDistribution = $JoltDistribution
    AdapterCombinations = $AdapterCombinations
}