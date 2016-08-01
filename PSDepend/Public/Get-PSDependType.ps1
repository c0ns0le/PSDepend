﻿Function Get-PSDependType {
    <#
    .SYNOPSIS
        Get dependency types and related information

    .DESCRIPTION
        Get dependency types and related information

        Checks PSDepend.yml for dependency types,
        verifies dependency scripts exist,
        gets help content for dependency scripts,
        returns various info on each dependency type
    
    .PARAMETER Path
        Path to PSDepend.yml defining dependency types

        Defaults to PSDepend.yml in the module root

    .PARAMETER DependencyType
        Optionally limited to this DependencyType

        Accepts wildcards

    .PARAMETER ShowHelp
        Show help content for specified dependency types

    .EXAMPLE
        Get-PSDependencyType -DependencyType FileSystem -ShowHelp

        Show help for the FileSystem dependency type.

    .LINK
        about_PSDepend

    .LINK
        https://github.com/RamblingCookieMonster/PSDepend
    #>
    [cmdletbinding()]
    param(
        [validatescript({Test-Path $_ -PathType Leaf -ErrorAction Stop})]
        [string]$Path = $(Join-Path $ModuleRoot PSDepend.yml),
        [string]$DependencyType = '*',
        [switch]$ShowHelp
    )

    # Abstract out reading the yaml and verifying scripts exist
    $DependencyDefinitions = ConvertFrom-Yaml -Path $Path

    foreach($Type in ($DependencyDefinitions.Keys | Where {$_ -like $DependencyType}))
    {
        #Determine the path to this script. Skip task dependencies...
        $Script =  $DependencyDefinitions.$Type.Script
        if($Script -ne '.')
        {
            if(Test-Path $Script)
            {
                $ScriptPath = $Script
            }
            else
            {
                # account for missing ps1
                $ScriptPath = Join-Path $ModuleRoot "PSDependScripts\$($Script -replace ".ps1$").ps1"
            }

            Try
            {
                $ScriptHelp = Get-Help $ScriptPath -Full -ErrorAction Stop
            }
            Catch
            {
                $ScriptHelp = "Error retrieving help: $_"
            }
        }
        if($ShowHelp)
        {
            $ScriptHelp
        }
        else
        {
            [pscustomobject]@{
                DependencyType = $Type
                Description = $DependencyDefinitions.$Type.Description
                DependencyScript = $ScriptPath
                HelpContent = $ScriptHelp
            }
        }
    }
}