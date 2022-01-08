function Get-SPOFolderFiles   # https://gallery.technet.microsoft.com/office/Find-checked-out-files-in-0533b17c/view/Discussions#content
{
param (
        [Parameter(Mandatory=$true,Position=1)]
		[string]$Username,
	[Parameter(Mandatory=$true,Position=2)]
		[string]$Url,
        [Parameter(Mandatory=$true,Position=3)]
		$password,
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ListTitle
		)

# Create context and test the connection
  $ctx=New-Object Microsoft.SharePoint.Client.ClientContext($Url)

  #Use this line if you are working on SharePoint Server
  #$ctx.Credentials = New-Object System.Net.NetworkCredential($Username, $password)

  #This line is working for SHarePoint Online. Comment it out, if you are running this script on a server
  $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $password)


  $ctx.Load($ctx.Web)
  $ctx.ExecuteQuery()


  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()


#region Get All Items

  # Get maximum ID of items in list
  $spqQuery = New-Object Microsoft.SharePoint.Client.CamlQuery  
  $spqQuery.ViewXml="<View Scope='RecursiveAll'><Query><OrderBy><FieldRef Name='ID' Ascending='False'/></OrderBy>"+
        "</Query>"+
        "<RowLimit>1</RowLimit>"+
        "</View>"

    $maxIndex=$ll.GetItems($spqQuery)
    $ctx.Load($maxIndex)
    $ctx.ExecuteQuery()
    $NumberOfItemsInTheList=$maxIndex[0].Id


    $ListItems=@()
    $ViewThreshold=4500


    [decimal]$NoOfRuns=($NumberOfItemsInTheList/$ViewThreshold)
    $NoOfRuns=[math]::Ceiling($NoOfRuns)

    for($WhichRun=0; $WhichRun -lt $NoOfRuns; $WhichRun++)
    {
        $startIndex=$WhichRun*$ViewThreshold
        $endIndex=$startIndex+$ViewThreshold      
        $spqQuery.ViewXml="<View Scope='RecursiveAll'><Query><Where><And><And>"+
		    "<Geq><FieldRef Name='ID'></FieldRef><Value Type='Number'>"+$startIndex+"</Value></Geq>"+
		    "<Lt><FieldRef Name='ID'></FieldRef><Value Type='Number'>"+$endIndex+"</Value></Lt>"+
		    "</And><Geq><FieldRef Name='CheckoutUser' LookupId='TRUE' /><Value Type='int'>0</Value></Geq></And></Where><GroupBy><FieldRef Name='CheckoutUser' Ascending='FALSE' /></GroupBy></Query></View>"
    
        Write-Host $spqQuery.ViewXml
        $partialItems=$ll.GetItems($spqQuery)
        $ctx.Load($partialItems)
        $ctx.ExecuteQuery()

        foreach($partialItem in $partialItems)
        {
            $ListItems += $partialItem
        }
     }
  
  
#endregion
        return $ListItems

     
}



      


#Paths to SDK
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"  
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"  
 
#Enter the data
$AdminPassword=Read-Host -Prompt "Enter password" -AsSecureString
$username="ana@etr56.onmicrosoft.com"
$Url="https://etr56.sharepoint.com/sites/demigtest11-2"
$ListTitle="testCheckOut"



Get-sPOFolderFiles -Username $username -Url $Url -password $AdminPassword -ListTitle $ListTitle 
