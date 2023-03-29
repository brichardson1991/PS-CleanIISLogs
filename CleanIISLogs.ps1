<#
.DESCRIPTION
This script cleans up log files older than a specified number of days in all website log directories.

.PARAMETER DaysToKeep
Number of days to keep the log files. Default is 1.

.PARAMETER Extensions
Array of file extensions to delete. Default is "*.log", "*.blg", "*.etl", "*.xml".
#>

# Import required modules
Import-Module WebAdministration

# Clean log files in a given directory older than a specified number of days
function CleanLogFilesInDirectory($Directory, $DaysToKeep, $Extensions) {
    if (Test-Path $Directory -PathType Container) {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$DaysToKeep)
        $Files = Get-ChildItem $Directory -Include $Extensions -Recurse | Where-Object {$_.LastWriteTime -le $LastWrite}
        $TotalFiles = $Files.Count
        $Count = 0
        
        if ($TotalFiles -gt 0) {
            Write-Verbose "Deleting files in $Directory older than $DaysToKeep days..."
        }
        
        foreach ($File in $Files) {
            $FullName = $File.FullName
            Write-Verbose "Deleting file: $FullName"
            Remove-Item $FullName -ErrorAction SilentlyContinue -Force | Out-Null
            $Count++
            Write-Progress -Activity "Deleting log files..." -Status "$Count/$TotalFiles files deleted" -PercentComplete (($Count/$TotalFiles)*100)
        }
    }
    else {
        Write-Warning "Directory $Directory does not exist"
    }
}

# Get all website log paths and clean their log files
function CleanWebsiteLogs {
    foreach($WebSite in Get-Website) {
        $IISlogPath = "$($WebSite.logFile.directory)\w3svc$($WebSite.id)".replace("%SystemDrive%",$env:SystemDrive)
        CleanLogFilesInDirectory $IISLogPath $DaysToKeep $Extensions
    }
}

# Define parameters
[CmdletBinding()]
Param(
    [Parameter()]
    [int]$DaysToKeep = 1,
    [Parameter()]
    [string[]]$Extensions = @("*.log", "*.blg", "*.etl", "*.xml")
)

# Main script logic
try {
    # Clean website log files
    CleanWebsiteLogs
    
    Write-Verbose "Log files older than $DaysToKeep days have been deleted."
}
catch {
