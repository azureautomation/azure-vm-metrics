<#
.Synopsis
   The script help with retireving Azure Metrics in a scriptable way. It will allow you to review server utilization and see if adjustments is required.

.DESCRIPTION
   The script help with retrieving Azure Metrics in a scriptable way. It will allow you to review server utilization and see if adjustments are required. Azure is structure in away that you want to consume the most of your resources that you assigned. For example, any CPU that is not being used, should be reduced as it is resourced payed for. 

.EXAMPLE
   Retrieves Default Metric for all VMs in subscription.  
   .\AzVM-Metrics.ps1

.EXAMPLE
   Retrieves Default Metrics for specified servers
   .\AzVM-Metrics.ps1 -VMName Server1,Server2

.EXAMPLE
   Retrieves a set of Metrics for specified Servers. It also overwrites default 7 Hour to 3 days
   .\AzVM-Metrics.ps1 -VMName Server1,Server2 -Metric 'Disk Write Bytes','Network Out','Network In','Percentage CPU' -Aggregation Average -Days -Value 3

.PARAMETER Days
   Change Data starttime to Day instead of Hours can be used in combination with Value to overwrite default of 7 hours

.PARAMETER Value
   Overwrites default 7 hours value. Use in combination of [days] switch to extend period

.PARAMETER Metric
   Set Metrics to collect

.PARAMETER VMName
   Specify Servers of which metrics should be collected

#>

#############################################################################
#                                     			 		                    #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 		                    #
#   Version 1.0                              			 	                #
#   Last Update Date: 14 August 2019                           	            #
#                                     			 		                    #
#############################################################################

#Requires -version 4
#Requires -module AzureRM.Profile,AzureRM.Compute,AzureRM.Storage

Param(
[string[]]$VMName = 'All',
[ValidateSet('Percentage CPU','Network Out','Network In','Disk Write Operations/Sec','Disk Write Bytes','Disk Read Bytes','Disk Read Operations/Sec','Network In Total','Network Out Total')][String[]]$Metric='Percentage CPU',
[Parameter(ParameterSetName='Parameter Set Hours')][ValidateNotNullOrEmpty()][ValidateRange(1,60)][Int]$Value=7,
[Switch]$Days,
[ValidateSet('Average','Count','Maximum','Minimum','Total','None')][String]$Aggregation = 'Average'
)


[Array]$report = @"
<html><head><Title>Metrics Report - $(Get-date) </Title>
<Style>
table {
    width: 1024px;
}
th {
	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	color: #FFFFFF;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	border-top: 1px solid #C1DAD7;
	letter-spacing: 2px;
	text-transform: uppercase;
	text-align: left;
	padding: 6px 6px 6px 12px;
	background: #5F9EA0;
}
td {
	font: 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	background: #fff;
	padding: 6px 6px 6px 12px;
	color: #6D929B;
}
</Style>
</head><body>
"@



Function Draw-Chart
{
Param([String]$VMId,[string]$MetricName)
    
    If ($Days)
    {$StartTime = (Get-Date).AddDays([int]"-$Value")}
    Else 
    {$StartTime = (Get-Date).AddHours([int]"-$Value")}

    [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea 
    $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
    [void]$Chart.Series.Add("Data")
    $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
  
    $Data = @((Get-AzureRmMetric -ResourceId $VMId -StartTime $StartTime -MetricNames $MetricName -WarningAction SilentlyContinue -AggregationType $Aggregation).Data)
        
    Switch ($Aggregation)
    {
    'Average' { $Chart.Series["Data"].Points.DataBindXY(($Data.Timestamp),$Data.Average)}
    'Count' {$Chart.Series["Data"].Points.DataBindXY(($Data.Timestamp),$Data.Count)}
    'Maximum' {$Chart.Series["Data"].Points.DataBindXY(($Data.Timestamp),$Data.Maximum)}
    'Minimum' {$Chart.Series["Data"].Points.DataBindXY(($Data.Timestamp),$Data.Minimum)}
    'Total' {$Chart.Series["Data"].Points.DataBindXY(($Data.Timestamp),$Data.Total)}
    'None' {$Chart.Series["Data"].Points.DataBindXY(($Data.Timestamp),$Data.Count)}
    }
    
    $Chart.Width = 500 ; $Chart.Height = 350
    $Chart.ChartAreas.Add($ChartArea)
   
    [void]$Chart.Titles.Add($MetricName) 
    $ChartArea.Area3DStyle.Enable3D = $false
    $ChartArea.AxisX.IsLabelAutoFit =  $true
    $ChartArea.AxisX.LabelAutoFitStyle = [System.Windows.Forms.DataVisualization.Charting.LabelAutoFitStyles]::LabelsAngleStep90
    $ChartArea.AxisX.MajorGrid.LineColor = [System.Drawing.Color]::LightGray
    $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::LightGray
    $filename = (Get-location).path + "\$(($VMId -split '/')[-1])$MetricName.png".Replace('/','-')
    $Chart.SaveImage($filename, "PNG")

    return $filename

}

if ($VMName -eq 'All')
{
$Vms = Get-AzureRmVM | %{[PSCustomObject]@{VMName = $_.Name; Size = $_.HardwareProfile.VmSize; DiagnosticsEnabled = $_.DiagnosticsProfile.BootDiagnostics.Enabled;Id = $_.Id}}
}Else
{$Vms =Get-AzureRmVM |?{$_.Name -in @($VMName)} | %{[PSCustomObject]@{VMName = $_.Name; Size = $_.HardwareProfile.VmSize; DiagnosticsEnabled = $_.DiagnosticsProfile.BootDiagnostics.Enabled;Id = $_.Id}}}

$VMCount = @($Vms).Count
$LoopCount = 0

foreach ($vm in $vms)
{
$LoopCount++
Write-Progress -Activity "VirtualMachine Performance Data collection ($($LoopCount)/$($VMCount)):" -Status "Virtual Machine: $($VM.VMName)" -PercentComplete ($LoopCount/$VMCount*100)  -Id 1

$report  += @"
<Table>
<tr><th colspan=$($Metric.Count)>$($vm.VMName) - Size:$($vm.Size)</th></tr>
<tr>$($Metric | %{"<td>$_</td>"})</tr>
<tr>$($Metric | %{"<td><img src="+[Char]34 +$(Draw-Chart -VMId $vm.id -MetricName $_) + [Char]34 +"</td>" })</tr>
"@
}


$report += "</body></html>"

$report | Out-File "$((Get-location).path)\Metricsreport.html"

Invoke-Item  "$((Get-location).path)\Metricsreport.html"









