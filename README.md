Azure VM Metrics
================

            

In some cases you would like to get performance metrics easily from Azure VM’s that gives you a holistic view of mutiple machines. There are several ways to do this and I thought I will provide a scriptable repeatable way.


The script will retrieve the information from azure and draw the charts for you based on you desired metrics. It uses the .net DataVisualization.Charting to provide the Graph. This can be replaced with some more nifty graphing if needed.


When executing script, ensure the powershell sessions is already logged into Azure and the correct Azure subscription is already select where your Vm’s are allocated.


 


 

 

![Image](https://github.com/azureautomation/azure-vm-metrics/raw/master/report.png)


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
