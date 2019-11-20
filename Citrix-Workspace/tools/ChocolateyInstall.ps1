## Template VirtualEngine.Build ChocolateyInstall.ps1 file for EXE/MSI installations

<# Citrix change the download URL after a new version is released. Here we grab the latest download link from the RSS feed. #>

Function Get-RssFeed {
    Begin {
    } 
    Process { 
        $rssFeedUri = 'https://www.citrix.com/content/citrix/en_us/downloads/workspace-app.rss'
        $rssFeedWebResponse = (New-Object -TypeName System.Net.WebClient).DownloadString($rssFeedUri)
        $feed = [System.Xml.XmlDocument] $rssFeedWebResponse
    
        $feed
    }
    End { 
    }   
}

Function Get-LatestRelease {
    param([Parameter(Mandatory, ValueFromPipeline)][System.Xml.XmlDocument] $feed)

    Begin {        
    }
    Process {
        Write-Host "Resolving latest Citrix Workspace app download link..."
        $regex = "^(New - )?Citrix Workspace app (?<version>\d+) for Windows"
        $latest = $feed.rss.channel.item | Where-Object { $_.Title -match $regex } | ForEach-Object {    
            $_.Title -match $regex | Out-Null    
            $release = "" | Select-Object Version, Url
            $release.Version = $matches["version"]
            $release.Url = $_.link
            $release
        } | Sort-Object -Property Version -Descending | Select-Object -First 1
        
        Write-Host -ForegroundColor Green "Latest version found: $($latest.Version)"
        $latest
    }
    End {
    }
}

Function Get-DownloadUri {
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Version,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Url
    )
      
    Begin {        
    }
    Process {        
        ## Kindly borrowed from https://github.com/chocolatey-community/chocolatey-coreteampackages/blob/master/automatic/wps-office-free/update_helper.ps1
        $READYSTATE_READY = 4
        $internetExplorer = New-Object -ComObject InternetExplorer.Application
        $internetExplorer.Navigate2($releaseUri) 
        $internetExplorer.Visible = $false
        while ($internetExplorer.ReadyState -ne $READYSTATE_READY) {
            Start-Sleep -Seconds 1
        }
        $link = $internetExplorer.Document.getElementsByTagName('a') | Where-Object { $_.href -match '.html#ctx-dl-eula$' } | Select-Object -First 1 
        $downloadUri = 'https:{0}' -f $link.rel
        $internetExplorer.Quit()
    }
    End {
    }
}

Function Get-ChocolateyPackageParams {    
    param([Parameter(Mandatory, ValueFromPipeline)][string] $downloadUri)    
    Begin {        
    }
    Process {
        $installChocolateyPackageParams = @{
            PackageName    = "Citrix-Workspace";
            FileType       = "EXE";
            SilentArgs     = "/noreboot /silent";
            Url            = "$downloadUri";
            ValidExitCodes = @(0, 3010);
            Checksum       = "1DA12FCFE95944693C9628C2CF3349102717317D3BFFDEDDF7384087383BA430";
            ChecksumType   = "sha256";
        }
    
        $installChocolateyPackageParams
    }
    End {
    }
}

$installChocolateyPackageParams = Get-RssFeed | Get-LatestRelease | Get-DownloadUri | Get-ChocolateyPackageParams
Install-ChocolateyPackage @installChocolateyPackageParams;

<#! POST-INSTALL-TASKS !#>
