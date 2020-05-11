﻿function Get-ADOServiceEndpoint
{
    <#
    .Synopsis
        Gets Azure DevOps Service Endpoints
    .Description
        Gets Service Endpoints from Azure DevOps.
        
        Service Endpoints are used to connect an Azure DevOps project to one or more web services.

        To see the types of service endpoints, use Get-ADOServiceEndpoint -GetEndpointType
    .Example
        Get-ADOServiceEndpoint -Organization MyOrg -Project MyProject -PersonalAccessToken $myPersonalAccessToken
    .Example
        Get-ADOServiceEndpoint -Organization MyOrg -GetEndpointType -PersonalAccessToken $myPersonalAccessToken
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get%20service%20endpoints?view=azure-devops-rest-5.1        
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/serviceendpoint/endpoints/get?view=azure-devops-rest-5.1   
    #>
    [CmdletBinding(DefaultParameterSetName='serviceendpoint/endpoints')]
    [OutputType('StartAutomating.PSDevOps.ServiceEndpoint', 'StartAutomating.PSDevOps.ServiceEndpoint.History', 'StartAutomating.PSDevOps.ServiceEndpoint.Type')]
    param(
    # The Organization
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/endpoints',ValueFromPipelineByPropertyName)]
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/endpoints/{EndpointId}',ValueFromPipelineByPropertyName)]
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/{EndpointId}/executionhistory',ValueFromPipelineByPropertyName)]
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/types',ValueFromPipelineByPropertyName)]
    [Alias('Org')]
    [string]
    $Organization,

    # The Project
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/endpoints',ValueFromPipelineByPropertyName)]
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/endpoints/{EndpointId}',ValueFromPipelineByPropertyName)]
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/{EndpointId}/executionhistory',ValueFromPipelineByPropertyName)]
    [string]
    $Project,

    # The Endpoint ID
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/endpoints/{EndpointId}',ValueFromPipelineByPropertyName)]
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/{EndpointId}/executionhistory',ValueFromPipelineByPropertyName)]
    [string]
    $EndpointID,

    # If set, will get the execution history of the endpoint.
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/{EndpointId}/executionhistory',ValueFromPipelineByPropertyName)]
    [Alias('ExecutionHistory')]
    [switch]
    $History,

    # If set, will get the types of endpoints.
    [Parameter(Mandatory,ParameterSetName='serviceendpoint/types',ValueFromPipelineByPropertyName)]
    [Alias('GetEndpointTypes')]
    [switch]
    $GetEndpointType,

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
    }

    process {
        $uri = # The URI is comprised of:  
            @(
                "$server".TrimEnd('/')   # the Server (minus any trailing slashes),
                $Organization            # the Organization,
                if ($Project) {$project} # the Project (if present),
                '_apis'                  # the API Root ('_apis'),
                (. $ReplaceRouteParameter $PSCmdlet.ParameterSetName)
                                         # and any parameterized URLs in this parameter set.
            ) -as [string[]] -ne '' -join '/'
        $uri += '?'
        $uri += $(@(                
            if ($ApiVersion) { # an api-version (if one exists)
                "api-version=$ApiVersion"
            }
        ) -join '&')
            

        $subTypeName = 
            if ($History) {
                '.History'
            } elseif ($GetEndpointType) {
                '.Type'
            } else {
                ''
            }
        Invoke-ADORestAPI @invokeParams -Uri $uri -PSTypeName @( # Prepare a list of typenames so we can customize formatting:
            "$Organization.$Project.ServiceEndpoint$subTypeName" # * $Organization.$Project.ServiceEndpoint
            "$Organization.ServiceEndpoint$subTypeName" # * $Organization.ServiceEndpoint
            "StartAutomating.PSDevOps.ServiceEndpoint$subTypeName" # * StartAutomating.PSDevOps.ServiceEndpoint
        ) -Property @{
            Organization = $Organization
            Project = $Project
        }
    }
}