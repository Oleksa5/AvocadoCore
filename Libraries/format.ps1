using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Reflection

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='Indent-*')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='Trim-*')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='Shorten-*')]
param()

<#
.SYNOPSIS
Prepend space to each line of a string.
.DESCRIPTION
.PARAMETER Object
.PARAMETER Level
.PARAMETER Size
Length of a level.
.OUTPUTS
string
#>
function Indent-Line {
  [OutputType([string])]
  param(
    [string] $Object,
    [int]    $Level = 1,
    [int]    $Size  = 2
  )

  $Object -replace "(?m)(?<=^)", (' ' * $Size * $Level)
}

<#
.SYNOPSIS
Trim empty lines around text.
.DESCRIPTION
.PARAMETER Object
.OUTPUTS
string
#>
function Trim-EmptyLine {
  [OutputType([string])]
  param (
    [string] $Object
  )

  $Object -replace "(?s)^\s*\n|\s*$"
}

<#
.SYNOPSIS
Shorten a string replacing a left out part with an ellipsis.
.PARAMETER Object
.PARAMETER Count
Character count of a shortened string or line count if Line
is specified. The parameter is mandatory.
.PARAMETER LeftOut
Position of the part of a string that is left out.
.PARAMETER Line
Not implemented.
.PARAMETER Ellipsis
.OUTPUTS
string
Shorten string.
#>
function Shorten-String {
  [OutputType([string])]
  param (
    [string] $Object,
    [int]    $Count = -1,
    [ValidateSet('Start','Middle','End')]
    [string] $LeftOut = 'End',
    [switch] $Line,
    [string] $Ellipsis = '…'
  )

  Assert { $Count -ne -1 } 'Count is mandatory'

  if (!$Line) {
    $length = [System.Math]::Min($Count-$Ellipsis.Length, $Object.Length)

    if ($length -lt $Object.Length) {
      switch ($LeftOut) {
        Start {
          $start  = $Object.Length - $length
          $elPos  = 0
          $Object = $Object.Substring($start, $length)
        } Middle {
          $start  = $length / 2
          $elPos  = $start
          $Object = $Object.Remove($start, $Object.Length - $length)
        } End {
          $start  = 0
          $elPos  = $length
          $Object = $Object.Substring($start, $length)
        } Default {
          throw "Unknown enumeration value"
        }
      }

      $Object = $Object.Insert($elPos, $Ellipsis)
    }


  } else {
    throw [NotImplementedException]::new(
      'Shortening string lines is not implemented'
    )
  }

  $Object
}

<#
.SYNOPSIS
Remove Select Graphic Rendition (SGR) control sequences from a string.
.DESCRIPTION
SGR control sequence is a character sequence of form 'CSI n m', where
CSI is a Control Sequence Introducer 'ESC[', n is any number (including none)
of semicolon-separated numbers and 'm' is a final byte literal.
.PARAMETER Object
Any string.
.OUTPUTS
Given string with no SGR control sequences.
#>
function Remove-AnsiStyle {
  [OutputType([string])]
  param (
    [string] $Object
  )

  $Object -replace '\x1b\[[0-9;]*m'
}

#region OutputRendering
#——————————————————————

$prevOutputRendering = $null

<#
.SYNOPSIS
Set OutputRendering to ANSI, saving the previous value.
.OUTPUTS
No output.
#>
function Use-AnsiOutputRendering {
  [OutputType([void])]
  param()

  $script:prevOutputRendering = $PSStyle.OutputRendering
  $PSStyle.OutputRendering = 'ANSI'
}

<#
.SYNOPSIS
Restore the previous value of OutputRendering saved by
Use-AnsiOutputRendering.
.OUTPUTS
No output.
#>
function Reset-OutputRendering {
  [OutputType([void])]
  param()

  $PSStyle.OutputRendering = $prevOutputRendering
  $prevOutputRendering = $null
}

#—————————
#endregion

class ObjectInfoFormat {
  [string] $Name
  [string] $Type
  [string] $Hash

  [string] ToString() {
    return ($this.Name, $this.Type, $this.Hash -ne "") -join ' '
  }
}

<#
.SYNOPSIS
Format object as object info.
.DESCRIPTION
Object info includes a name, type and hash.
.PARAMETER Name
.PARAMETER Object
.OUTPUTS
ObjectInfoFormat
#>
function Format-ObjectInfo {
  [OutputType([ObjectInfoFormat])]
  param(
    [string] $Name,
    [Object] $Object
  )

  $info = [ObjectInfoFormat]::new()

  $info.Name = Format-Code $Name 'Source'
  $info.Type = Format-Code $Object 'Type'
  $info.Hash = $null -ne $Object ? (Format-Code $Object.GetHashCode()) : ""

  $info
}

enum FormatCodeValueType {
  Infer
  Source
  Property
  Type
}

<#
.SYNOPSIS
Format an object as a string colored as a themed source code.
.PARAMETER Value
.OUTPUTS
string
.NOTES
An object is converted to a string by string interpolation.
#>
function Format-Code {
  [OutputType([string])]
  param (
    [Object] $Value,
    [FormatCodeValueType] $Type = 'Infer',
    [scriptblock] $ToString = { param($Value) "$Value" }
  )

  #region Lib
  #——————————

    function IsNum {
      [OutputType([bool])]
      param (
        [TypeInfo] $Type
      )

      ($Type -eq [int   ]) -or
      ($Type -eq [double])
    }

    function IsConvertedToType {
      [OutputType([bool])]
      param(
        [Object] $Value
      )

      $type = $Value.GetType().Name
      $Value = (&$ToString $Value)

      $Value -eq $type
    }

  #—————————
  #endregion

  switch ($Type) {
    Source {
      $color = $CodeColor.Source
    } Property {
      $color = $CodeColor.Property
    } Type {
      $color = $CodeColor.Type
      $Value = $null -eq $Value ? 'Object' : $Value.GetType()
    } Infer {
      $color = &{
        if ($null -eq $Value) {
          $CodeColor.Constant
        } elseif ($Value -is [TypeInfo]) {
          $CodeColor.Type
        } else {
          switch ($Value.GetType()) {
            string       { $CodeColor.String   }
            { IsNum $_ } { $CodeColor.Number   }
            bool         { $CodeColor.Constant }
            scriptblock  { $CodeColor.Source   }
            Default      { (IsConvertedToType $Value) ?
                             $CodeColor.Type :
                             $CodeColor.Source }
          }
        }
      }

      if ($null -eq $Value) {
        $Value = 'null'
      } elseif ($Value -is [string]) {
        $Value = "'$Value'"
      } elseif ($Value -is [scriptblock]) {
        $Value = "{$Value}"
      }
    }
  }

  $Value = &$ToString $Value

  if ($Value) {
    $Value = "$color$Value$r"
  }

  $Value
}

<#
.SYNOPSIS
Format objects as an extended table.
.DESCRIPTION
Extended table is a table of objects with prepended
additional properties. These properties are: a name, which
includes a parent name if provided, type name and a hash code.

If an object supplied with no name, its index in the Object
parameter array is used.

Format-ExtendedTable is based on the Format-Table cmdlet, so
can be expected to have a similar behaviour.
.PARAMETER Object
One of the following:
-Hashtable, where the key is a name and the value is an object
-Object array or object
.PARAMETER Parent
Parent name to prepend to object names.
.PARAMETER ForceExpandable
Suppress an exception if an object is expandable.
.OUTPUTS
string[]
Array of strings.
#>
function Format-ExtendedTable {
  [OutputType([string[]])]
  param(
    [Object] $Object,
    [string] $Parent,
    [switch] $ForceExpandable
  )

  #region Lib
  #——————————

    function _checkNotExpandable {
      [OutputType([void])]
      param (
        [string] $Name,
        [Object] $Object
      )

      foreach ($property in Expand-Property $Object -Depth 1) {
        if ($property.Ancestors.Count -gt 0) {
          $propertyName = $property.Ancestors[0].Name

          throw "Object $Name has an expandable property $propertyName " +
                "that Format-ExtendedTable may be unable to show."
        }
      }
    }

  #—————————
  #endregion

  #region To dictionary
  #————————————————————

    if ($Object -isnot [Collections.IDictionary]) {
      $_object = [ordered]@{}
      $i = 0
      foreach ($obj in $Object) {
        $_object["[$i]"] = $obj

        $i++
      }

      $Object = $_object
    }

  #—————————
  #endregion
  #region Add parent
  #———————————

    if ($Parent) {
      $_object = [ordered]@{}
      foreach ($obj in $Object.GetEnumerator()) {
        $_object["$Parent $($obj.Key)"] = $obj.Value
      }

      $Object = $_object
    }

  #—————————
  #endregion
  #region Check
  #————————————

    if (-not $ForceExpandable) {
      foreach ($obj in $Object.GetEnumerator()) {
        _checkNotExpandable $obj.Key $obj.Value
      }
    }

  #—————————
  #endregion
  #region To psobjects
  #———————————————————

    $haveProperties = $false

    $psobjects = &{
      foreach ($obj in $Object.GetEnumerator()) {
        $info   = Format-ObjectInfo $obj.Key $obj.Value
        $name   = $info.Name
        if ($null -eq $obj.Value) {
        $second = Format-Code $obj.Value
        $third  = $null
        } else {
        $second = $info.Type
        $third  = $info.Hash
        }

        $psobject = [pscustomobject]@{
          " "   = $name
          "  "  = $second
          "   " = $third
        }

        (Get-Variable haveProperties).Value = HasProperty $obj.Value

        Prepend-Property $obj.Value $psobject
      }
    }

  #—————————
  #endregion
  #region Format table
  #———————————————————

    Use-AnsiOutputRendering

    $table =  $psobjects | Format-Table -HideTableHeaders:(!$haveProperties)

    $table = Trim-EmptyLine ($table | Out-String)

    #region Remove info header separator
    #———————————————————————————————————

      $table = [regex]::new('-'  ).Replace($table, ' '  , 1)
      $table = [regex]::new('--' ).Replace($table, '  ' , 1)
      $table = [regex]::new('---').Replace($table, '   ', 1)

    #—————————
    #endregion

    Reset-OutputRendering

  #—————————
  #endregion

  ""
  $table
}

#region FormatExpanded
#—————————————————————

class Property {
  [List[Property]] $Ancestors
  [string]         $Name
  [Object]         $Value
}

$expandPropertyDepth = -1

<#
.SYNOPSIS
Expand an object and its descendent properties
as a list of properties.
.PARAMETER Object
.PARAMETER Depth
Maximum depth of an expansion.
.OUTPUTS
Property[]
Array of properties.
Ancestors list of each property has the following order:
-At index 0 is the ancestor closest to the root
-At index Count-1 is the ancestor closest to the property
#>
function Expand-Property {
  [OutputType([Property[]])]
  param (
    [Object] $Object,
    [int]    $Depth = -1
  )

  #region Lib
  #——————————

    function ExcludedFromExpansion {
      [OutputType([bool])]
      param (
        [Object] $Object
      )

      ($Object -is [scriptblock]) -or
      ($Object -is [string]     ) -or
      ($Object -is [Enum]       )
    }

    function ExpandProperty {
      [OutputType([Property[]])]
      param (
        [Object] $Object
      )

      $expandPropertyDepth++

      if (($Depth               -eq -1) -or
          ($expandPropertyDepth -le $Depth)) {

        foreach ($property in (Get-Property $Object -ElementAsProperty)) {
          $name  = $property.Name
          $value = $property.Value

          if (-not (ExcludedFromExpansion $value)) {
            $expansion = ExpandProperty $value
          } else {
            $expansion = $null
          }

          $property = [Property]::new()

          $property.Ancestors = [List[Property]]::new()
          $property.Name      = $name
          $property.Value     = $value

          if ($expansion) {
            foreach ($childProperty in $expansion) {
              $childProperty.Ancestors.Add($property)
              $childProperty
            }
          } else {
            $property
          }
        }
      }

      $expandPropertyDepth--
    }

  #—————————
  #endregion

  $properties = ExpandProperty $Object

  foreach ($property in $properties) {
    $property.Ancestors.Reverse()
  }

  $properties
}

<#
.SYNOPSIS
Format an object ad its descendent properties
as a list of properties.
.PARAMETER Object
.PARAMETER Name
.PARAMETER Depth
Maximum depth of an expansion.
.PARAMETER ShowTypes
.OUTPUTS
string[]
#>
function Format-Expanded {
  [OutputType([string[]])]
  param (
    [Object] $Object,
    [string] $Name,
    [int]    $Depth = -1,
    [switch] $ShowTypes
  )

  #region Lib
  #——————————

    function FormatName {
      [OutputType([string])]
      param (
        [Property] $Property,
        [Property] $PrevProperty
      )

      #region Lib
      #——————————

        function GetPropertyAncestry {
          param ([Property] $Property)

          if ($Property) {
            $Property.Ancestors.ToArray() + $Property
          }
        }

      #—————————
      #endregion

      Assert { $null -ne $Property }

      $propAncestry = GetPropertyAncestry $Property
      $prevAncestry = @(GetPropertyAncestry $PrevProperty)

      $accum = [List[string]]::new()

      for ($i = 0; $i -lt $propAncestry.Count; $i++) {
        $ancestor = $propAncestry[$i]
        $prev     = $prevAncestry[$i]

        $name = Format-Code $ancestor.Name 'Property'
        if ($ShowTypes) {
        $type = Format-Code $ancestor.Value 'Type' -ToString {
          param($type)

          "{0,-7}" -f (Shorten-String $type -Count 7)
        }
        $name = "$type $name"
        }

        if ($ancestor.Equals($prev)) {
          $accum.Add(' ' * (Remove-AnsiStyle $name).Length)
        } else {
          $accum.Add($name)
        }
      }

      "$accum"
    }

    function FormatProperties {
      [OutputType([string[]])]
      param (
        [Property[]] $Properties
      )

      $Properties = &{
        $prev = $null

        foreach ($prop in $Properties) {
          @{
            Name  = FormatName $prop $prev
            Value = Format-Code $prop.Value
          }

          $prev = $prop
        }
      }

      Use-AnsiOutputRendering

      $Properties | Format-Table (
        @{ E='Name' }, @{ E={ ':' } }, @{ E='Value' }
      ) -HideTableHeaders

      Reset-OutputRendering

    }

  #—————————
  #endregion

  $info = Format-ObjectInfo $Name $Object
  if ($null -eq $Object) {
    $Object = Format-Code $Object
  } else {
    $Object = Expand-Property $Object $Depth
    $Object = FormatProperties $Object | Out-String
    $Object = Trim-EmptyLine $Object
  }

  ""
  Indent-Line $info
  ""
  Indent-Line $Object -Level 2
}

#—————————
#endregion

<#
.SYNOPSIS
Format an exception.
.PARAMETER ErrorRecord
.OUTPUTS
string
void
No output if ErrorRecord is null.
#>
function Format-Exception {
  [OutputType([string[]], [void])]
  param(
    [ErrorRecord] $ErrorRecord
  )

  if ($ErrorRecord) {
    $exceptionS = "$($ErrorRecord.Exception)"
    $lineWidth  = [Math]::Min($exceptionS.Length, [System.Console]::WindowWidth)
    $line       = $("-" * $lineWidth)
    $stack      = $ErrorRecord.ScriptStackTrace

    ""
    "$($AvocadoColor.Error)$exceptionS"
    "$line"
    "$stack$r"
  }
}