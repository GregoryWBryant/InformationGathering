# Import the ImportExcel module
# Install-Module ImportExcel
# Import-Module ImportExcel

$Files = Get-ChildItem -Path "Path to CSVs"

foreach ($File in $Files) {

    $CSVPath = $File.FullName
    $XlsxPath = $File.FullName -replace ".csv",".xlsx"

    $Data = Import-Csv -Path $CSVPath

    # Export the data to an XLSX file and format it as a table
    $Data | Export-Excel -Path $XlsxPath -TableName "DataTable" -AutoSize
}