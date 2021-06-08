# dataCollectionPlans
Semi-automated Data Collection Plans for Troubleshooting Various Scenarios


# Usage: 

## 001_WIN_ProcMonNetTrace.ps1

Collects Process Monitor and Netsh Internet Client and Netconnection Scenarios in a circular buffer of 1024MB in C:\Temp\<timestamp>.zip

`(iwr -Uri https://raw.githubusercontent.com/saibijee/dataCollectionPlans/main/001_ProcMonNetTrace.ps1 -UseBasicParsing).content | iex `
