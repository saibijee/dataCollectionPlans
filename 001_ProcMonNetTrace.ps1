<#
<Title>001_ProcMonNetTrace.ps1</Title>
<Author>Sohaib Shaheed (SOSHAH)</Author>
<Version>1.0</Version>
<PublishDate>03-06-2021</PublishDate>
#>


# Function to allow Pretty Printing

Function Out-Verbose {
   Param($text)
        
        # Get Current Console Color Settings   
        $ConsoleDefaultFGColor=[console]::ForegroundColor
        $ConsoleDefaultBGColor=[console]::BackgroundColor
      
        # Set Custom Console Color Settings
        [console]::ForegroundColor = "Green"
        #[console]::BackgroundColor = "DarkGreen"

        # Get Current Time
        $time = (Get-date)

        # Construct Message with Time Included
        $message = "$time - $text"

        # Display Message
        $message
        
        # Put Console Settings Back to as they were
        [console]::ForegroundColor = $ConsoleDefaultFGColor
        [console]::BackgroundColor = $ConsoleDefaultBGColor

}

$WorkingDir = "C:\temp"
$timestamp = Get-Date -Format yyyyMMddHHmmss

# Detect if running as an Admin

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Out-Verbose "Script running as an Administrator"
} else {
   Out-Verbose "Script Was Run as Non-Admin, Stopping."
   Write-Error  "Please run this script as an Administrator, so it can generate Self-signed SSL Certs" -ErrorAction Stop
}

#make working directory
if(Test-Path ($WorkingDir)){
    Out-Verbose "$WorkingDir exists"
}else{
    md $WorkingDir -Verbose
}

#Make Trace Directory
if(Test-Path ("$WorkingDir\$timestamp")){
    Out-Verbose "$WorkingDir\$timestamp exists"
}else{
    md $WorkingDir\$timestamp -Verbose
}

#download procmon
if(Test-Path ("$($WorkingDir)\ProcessMonitor.zip")){
    Out-Verbose "ProcessMonitor.zip exists, skilling download of ProcessMonitor.zip"
}else{
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://download.sysinternals.com/files/ProcessMonitor.zip","$($WorkingDir)\ProcessMonitor.zip")
    Out-Verbose "ProcessMonitor.zip downloaded"
}

#unzip procmon

if(Test-Path ("$($WorkingDir)\ProcessMonitor\procmon.exe")){
    Out-Verbose "Process Monitor Exists, skipping unzip operation of ProcessMonitor.zip"
}else{
    Expand-Archive -LiteralPath "$($WorkingDir)\ProcessMonitor.zip" -DestinationPath "$($WorkingDir)\ProcessMonitor" 
    Out-Verbose "Process Monitor Unzipped to folder $WorkingDir\ProcessMonitor"
}
#Step 1 - Start Traces:

netsh trace start capture=yes scenario=netconnection,internetclient tracefile="$WorkingDir\$timestamp\$($ENV:Computername)_NetConIntCliTrace.etl" persistent=no overwrite=yes maxSize=1024MB

Out-Verbose "Cyclic Netsh Trace/Packet Capture Started"

Clear-DnsClientCache

Out-Verbose "DNS Client Cache Cleared"

#Start ProcMon

$command = "$WorkingDir\ProcessMonitor\procmon.exe /accepteula /nofilter /backingfile '$WorkingDir\$timestamp\$($ENV:COMPUTERNAME).PML' /minimized"

Invoke-Expression -Command $command
Out-Verbose "Process Monitor trace Started in $WorkingDir\$timestamp"



#Reproduce the issue, if it works, great, if it breaks, even then this is valuable

$key= $null
while ($key -ne "x"){
   $key = Read-Host -Prompt "Please reproduce the issue, and once issue is reproduced, type x and press Enter to stop traces"
}


#Step 3- Stop Traces:

$stopCommand = "$WorkingDir\ProcessMonitor\procmon.exe /terminate"
Invoke-Expression -Command $stopCommand
Out-Verbose "Process Monitor trace Stoppped, file $WorkingDir\$timestamp\$($ENV:COMPUTERNAME).PML"
Out-Verbose "Attempting to stop traces, this may take a while (sometimes even more than 10 mins)..."
Netsh trace stop
Out-Verbose "Packet Capture Stopped, location $WorkingDir\$timestamp\$($ENV:Computername)_NetConIntCliTrace.cab"

Out-Verbose "Please compress/zip the folder $WorkingDir\$timestamp and upload to the Secure Upload Location for your Microsoft Case. If you do not have the link, please ask the case owner for it."

