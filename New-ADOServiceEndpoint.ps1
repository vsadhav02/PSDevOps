﻿function New-ADOServiceEndpoint
{
    <#
    .Synopsis
        Creates Azure DevOps Service Endpoints
    .Description
        Creates Service Endpoints in Azure DevOps.
        
        Service Endpoints are used to connect an Azure DevOps project to one or more web services.

        To see the types of service endpoints, use Get-ADOServiceEndpoint -GetEndpointType
    .Example
        New-ADOServiceEndpoint -Organization MyOrg -Project MyProject -Name MyGitHubConnection -Url https://github.com -Type GitHub -Authorization @{
            scheme = 'PersonalAccessToken'
            parameters = @{
                accessToken = $MyGitHubPersonalAccessToken
            }
        } -PersonalAccessToken $MyAzureDevOpsPersonalAccessToken -Data @{pipelinesSourceProvider='github'}
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops-rest-5.1
    #>
    [CmdletBinding(DefaultParameterSetName='serviceendpoint/endpoints',SupportsShouldProcess)]
    [OutputType('StartAutomating.PSDevOps.ServiceEndpoint')]
    param(
    # The Organization
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('Org')]
    [string]
    $Organization,

    # The Project
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]
    $Project,

    # The name of the endpoint
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]
    $Name,

    # Initial administrators of the endpoint
    [Parameter(ValueFromPipelineByPropertyName)]
    [PSObject]
    $AdministratorsGroup,

    # Endpoint authorization data 
    [Parameter(ValueFromPipelineByPropertyName)]
    [PSObject]
    $Authorization,

    # General endpoint data
    [Parameter(ValueFromPipelineByPropertyName)]
    [PSObject]
    $Data,

    # Initial readers of the endpoint
    [Parameter(ValueFromPipelineByPropertyName)]
    [PSObject]
    $ReadersGroup,

    # The endpoint type.  To see available endpoint types, use Get-ADOServiceEndpoint -GetEndpointType
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Type,

    # The endpoint description.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Description,

    # The endpoint service URL.
    [Parameter(ValueFromPipelineByPropertyName)]
    [uri]
    $Url,

    # If set, the endpoint will be shared across projects
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch]
    $IsShared,
    
    # The server.  By default https://dev.azure.com/.
    # To use against TFS, provide the tfs server URL (e.g. http://tfsserver:8080/tfs).
    [Parameter(ValueFromPipelineByPropertyName)]
    [uri]
    $Server = "https://dev.azure.com/",

    # The api version.  By default, 5.1-preview.
    # If targeting TFS, this will need to change to match your server version.
    # See: https://docs.microsoft.com/en-us/azure/devops/integrate/concepts/rest-api-versioning?view=azure-devops
    [string]
    $ApiVersion = "5.1-preview",

    # A Personal Access Token
    [Alias('PAT')]
    [string]
    $PersonalAccessToken,

    # Specifies a user account that has permission to send the request. The default is the current user.
    # Type a user name, such as User01 or Domain01\User01, or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $Credential,

    # Indicates that the cmdlet uses the credentials of the current user to send the web request.
    [Alias('UseDefaultCredential')]
    [switch]
    $UseDefaultCredentials,

    # Specifies that the cmdlet uses a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.
    [uri]
    $Proxy,

    # Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter. The default is the current user.
    # Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $ProxyCredential,

    # Indicates that the cmdlet uses the credentials of the current user to access the proxy server that is specified by the Proxy parameter.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [switch]
    $ProxyUseDefaultCredentials    
    )

    begin {
        #region Copy Invoke-ADORestAPI parameters
        $invokeParams = & $getInvokeParameters $PSBoundParameters
        #endregion Copy Invoke-ADORestAPI parameters
        $queryParameters = ,'apiVersion'
    }

    process {
        $uri = # The URI is comprised of:  
            @(
                "$server".TrimEnd('/') # the Server (minus any trailing slashes),
                $Organization          # the Organization,
                $Project               # the Project,
                '_apis'                # the API Root ('_apis'),
                (. $ReplaceRouteParameter $PSCmdlet.ParameterSetName)
                                       # and any parameterized URLs in this parameter set.
            ) -as [string[]] -ne '' -join '/'
        $uri += '?' # The URI has a query string containing:
        $uri += @(
            if ($ApiVersion) { # * The api-version
                "api-version=$ApiVersion"
            }
        ) -join '&'
        
        $notInvokeParams = . $getNotInvokeParameters $PSBoundParameters         
        foreach ($k in @($notInvokeParams.Keys)) {
            if ($queryParameters -contains $k) {
                $notInvokeParams.Remove($k)
            }
        }

        $body = $notInvokeParams
        $invokeParams += @{Uri=$uri;Body =$body;Method='POST'}
        if ($WhatIfPreference) {
            $invokeParams.Remove('PersonalAccessToken')
            return $invokeParams
        }


        if (-not $psCmdlet.ShouldProcess("$($invokeParams.method) $($invokeParams.Uri)")) { return }
        
        Invoke-ADORestAPI @invokeParams -PSTypeName @( # Prepare a list of typenames so we can customize formatting:
            "$Organization.$Project.ServiceEndpoint" # * $Organization.$Project.ServiceEndpoint
            "$Organization.ServiceEndpoint" # * $Organization.ServiceEndpoint
            "StartAutomating.PSDevOps.ServiceEndpoint" # * StartAutomating.PSDevOps.ServiceEndpoint
        ) -Property @{
            Organization = $organization
            Project = $project
        }
    }
}