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
        #$htmlAgilityPackPath = '{0}\HtmlAgilityPack.dll' -f (Split-Path -Path $PSScriptRoot)        
        $htmlAgilityPackPath = Join-Path -Path $PSScriptRoot -ChildPath HtmlAgilityPack.dll
        [System.Reflection.Assembly]::LoadFrom($htmlAgilityPackPath) | Out-Null        
        
        <# Citrix sign the download link via Javascript so we have to parse the page to get the signed download Uri. #>
        Write-Host "Resolving latest Citrix Workspace app ($($latest.Version)) download token..."
        #$releaseUriWebResponse = New-Object -TypeName System.Net.WebClient
        #$releaseUriWebResponse.DownloadString($latest.Url)
        #$releaseUriWebResponse.Headers['user-agent'] = "myUserAgentString"
        $releaseUriWebResponse = Invoke-WebRequest -Uri "$url" -UserAgent "adlkjhaslkfhjsdafkljhasdfkljasdklf"

        $htmlDocument = New-Object -TypeName 'HtmlAgilityPack.HtmlDocument'
        $htmlDocument.LoadHtml($releaseUriWebResponse)
        $relativeUri = $htmlDocument.DocumentNode.SelectNodes('//a') |
            ForEach-Object { $_.Attributes } |
                Where-Object { $_.Value -match 'CitrixWorkspaceApp.exe' } |
                    Select-Object -ExpandProperty Value
        $downloadUri = 'https:{0}' -f $relativeUri
    
        $downloadUri
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
            SilentArgs     = "/noreboot /silent /includeSSON";
            Url            = "$downloadUri";
            ValidExitCodes = @(0,3010);
            Checksum       = "84056DA6674D09DD4861EC1EA7F435282CC469CB90075BD1AC569A4F60F5BF2B";
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