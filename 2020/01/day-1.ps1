cd 'C:\Users\Andrew\OneDrive - Bastian Solutions\Projects\Internal\AdventOfCode2020'


$items = (get-content .\day-1.input.txt) | ForEach-Object { [int]$_ }
$desiredSum = 2020


$lowItems = $items | Where-Object {
    $_ -lt ($desiredSum / 2)
}

$highItems = $items | Where-Object {
   $_ -ge ($desiredSum / 2)
}


foreach($lowItem in $lowItems) {
    foreach($highItem in $highItems) {
        if($lowItem + $highItem -eq $desiredSum) {
            break
        }
    }

    if($lowItem + $highItem -eq $desiredSum) {
            break
    }
}

"Item 1: $lowItem"
"Item 2: $highItem"
"Sum: $($lowItem + $highItem)"
"Product: $($lowItem * $highItem)"


$sumFound = $false

for($i = 0; $i -lt $items.Length - 3; $i++) {
    $item1 = $items[$i]

    for($j = $i + 1; $j -lt $items.Length - 2; $j++) {
        $item2 = $items[$j]

        for($k = $j + 1; $k -lt $items.Length - 1; $k++) {
            $item3 = $items[$k]

            if($item1 + $item2 + $item3 -eq $desiredSum) {
                $sumFound = $true
                break
            }
        }

        if($sumFound) {
            break
        }
    }

    if($sumFound) {
            break
    }
}


"Item 1: $item1"
"Item 2: $item2"
"Item 3: $item3"
"Sum: $($item1 + $item2 + $item3)"
"Product: $($item1 * $item2 * $item3)"