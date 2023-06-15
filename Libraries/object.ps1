[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='Prepend-*')]
param()

<#
.SYNOPSIS
Get properties of an object.
.PARAMETER Object
.PARAMETER ElementAsProperty
Elements of an array is treated as properties and
other array properties are ignored.
.OUTPUTS
PSPropertyInfo
psobject

If Object is not an array or ElementAsProperty is not specified,
outputs an array of PSPropertyInfo, otherwise outputs PSObject with
Name and Value properties.
#>
function Get-Property {
  [OutputType(
    [PSPropertyInfo[]],
    [psobject])]
  param(
    [object] $Object,
    [switch] $ElementAsProperty
  )

  if ($ElementAsProperty -and ($Object -is [array])) {
    $i = 0
    foreach ($element in $Object) {
      [pscustomobject]@{ Name = "[$i]"; Value = $element }

      $i++
    }
  } else {
    $properties = $Object | Select-Object -Property *
    foreach ($property in $properties.psobject.Properties) {
      $property
    }
  }
}

<#
.SYNOPSIS
Determine whether an object has properties.
.PARAMETER Object
.OUTPUTS
bool
#>
function HasProperty {
  [OutputType([bool])]
  param (
    [Object] $Object
  )

  (Get-Property $Object).Count -gt 0
}

<#
.SYNOPSIS
Prepend properties to an object.
.PARAMETER Object
.PARAMETER Property
PSObject with any number of properties.
.OUTPUTS
PSObject
If both Object and Property are null, outputs
null, otherwise outputs PSObject.
#>
function Prepend-Property {
  [OutputType([psobject])]
  param (
    [Object]   $Object,
    [psobject] $Property
  )

  if (($null -eq $Object) -and
      ($null -eq $Property)) {
    return
  }

  $Property ??= [pscustomobject]@{}

  $objectH = [ordered]@{}
  Get-Property $Object | ForEach-Object {
    $objectH[$_.Name] = $_.Value
  }

  if ($objectH.Count) {
    $Property | Add-Member -NotePropertyMembers $objectH
  }

  $Property
}