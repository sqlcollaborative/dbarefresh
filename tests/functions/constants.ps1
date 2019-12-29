# constants
if (Test-Path C:\temp\constants_psdatabaserefresh.ps1) {
    Write-Verbose "C:\temp\constants.ps1 found."
    . C:\temp\constants_psdatabaserefresh.ps1
}
else {
    $script:instance1 = "localhost\sql2017"
    $script:instance2 = "localhost\sql2017"
    $script:sourcedatabase = "DB1"
    $script:destinationdatabase = "DB2"
}