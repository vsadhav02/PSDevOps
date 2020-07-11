function New-GitHubWorkflow {
    <#
    .Synopsis
        Creates a new GitHub Workflow
    .Example
        New-GitHubWorkflow -Step InstallPester
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Does not change state")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectComparisonWithNull", "", Justification = "Explicitly checking for null (0 is ok)")]
    param(
        # The input object.
        [Parameter(ValueFromPipeline)]
        [PSObject]$InputObject,

        # Optional changes to a component.
        # A table of additional settings to apply wherever a part is used.
        # For example -Option @{RunPester=@{env=@{"SYSTEM_ACCESSTOKEN"='$(System.AccessToken)'}}
        [Collections.IDictionary]
        $Option,

        # The name of parameters that should be supplied from the environment.
        # Wildcards accepted.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]
        $EnvironmentParameter,

        # The name of parameters that should be excluded.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]
        $ExcludeParameter,

        # The name of parameters that should be referred to uniquely.
        # For instance, if converting function foo($bar) {} and -UniqueParameter is 'bar'
        # The build parameter would be foo_bar.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]
        $UniqueParameter,

        # A collection of default parameters.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Collections.IDictionary]
        $DefaultParameter = @{}
    )

    dynamicParam {

        $newDynamicParameter = {
            param([string]$name, [string[]]$ValidSet, [type]$type = [string], [string]$ParameterSet = '__AllParameterSets', [switch]$Mandatory)

            $ParamAttr = [Management.Automation.ParameterAttribute]::new()
            $ParamAttr.Mandatory = $Mandatory
            $ParamAttr.ParameterSetName = $ParameterSet
            $ParamAttributes = [Collections.ObjectModel.Collection[System.Attribute]]::new()
            $ParamAttributes.Add($ParamAttr)

            if ($ValidSet) {
                $ParamAttributes.Add([Management.Automation.ValidateSetAttribute]::new($ValidSet))
            }

            [Management.Automation.RuntimeDefinedParameter]::new($name, $type, $ParamAttributes)
        }

        $DynamicParameters = [Management.Automation.RuntimeDefinedParameterDictionary]::new()

        $ThingNames = $script:ComponentNames.'GitHub'
        if ($ThingNames) {
            foreach ($kv in $ThingNames.GetEnumerator()) {
                $k = $kv.Key.Substring(0,1).ToUpper() + $kv.Key.Substring(1)
                $DynamicParameters.Add($k, $(& $newDynamicParameter $k $kv.Value ([string[]])))
            }
        }

        return $DynamicParameters
    }

    begin {
        $expandBuildStepCmd  = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Expand-BuildStep','Function')

        $expandADOBuildStep = @{
            BuildSystem = 'GitHub'
            SingleItemName = 'On','Name'
            DictionaryItemName = 'Jobs', 'Inputs','Outputs'
        }
    }

    process {

        $myParams = [Ordered]@{ } + $PSBoundParameters

        $stepsByType = [Ordered]@{ }
        $ThingNames = $script:ComponentNames.'GitHub'
        foreach ($kv in $myParams.GetEnumerator()) {
            if ($ThingNames[$kv.Key]) {
                $stepsByType[$kv.Key] = $kv.Value
            }
        }

        if ($InputObject -is [Collections.IDictionary]) {
            foreach ($key in $InputObject.Keys) {
                $stepsByType[$key] = $InputObject.$key
            }
        }

        elseif ($InputObject) {
            foreach ($property in $InputObject.psobject.properties) {
                $stepsByType[$property.name] = $InputObject.$key
            }
        }

        $expandSplat = @{} + $PSBoundParameters
        foreach ($k in @($expandSplat.Keys)) {
            if (-not $expandBuildStepCmd.Parameters[$k]) {
                $expandSplat.Remove($k)
            }
        }

        $yamlToBe = Expand-BuildStep -StepMap $stepsByType @expandSplat @expandADOBuildStep

        #$yamlToBe = & $expandComponents $stepsByType -ComponentType GitHub -SingleItemName On, Name
        @($yamlToBe | & $toYaml -Indent -2) -join '' -replace "$([Environment]::NewLine * 2)", [Environment]::NewLine
    }
}