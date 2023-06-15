[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='Expect-*')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

<#
.SYNOPSIS
Assert a condition is true.
.DESCRIPTION
If a given Condition evaluates to True, does nothing. If it evaluates
to False, throws an exception. The exception object is a message string
with the failed Condition and Premises.
.PARAMETER Condition
Condition script to assert. A condition is a scriptblock that outputs
an object convertible to a boolean.
.PARAMETER Premises
.OUTPUTS
No output.
#>
function Assert {
  [OutputType([void])]
  param(
    [scriptblock] $Condition,
    [string[]]    $Premises
  )

  if (!(&$Condition)) {
    # $conditionS = $Condition -replace " {2,}", " "
    $conditionS = "$Condition".Trim()
    $msg = "Assertion has failed: $conditionS."

    if ($Premises.Count -ge 1) {
      $nl  = [Environment]::NewLine

      $msg = "$msg With the premises:"
      $Premises = $Premises | ForEach-Object { "$_;" }
      $msg = "$msg$nl$Premises" -replace ";$", "."
    }

    throw $msg
  }
}

<#
.SYNOPSIS
Assert conditions are true.
.PARAMETER Conditions
Condition scripts to assert with their premises.
A condition is a scriptblock that outputs an object
convertible to a boolean.

An array of objects should have the form:

script/condition, 0 or n strings/premises,
script/condition, 0 or n strings/premises,
...
script/condition, 0 or n strings/premises
.PARAMETER OnSuccess
Scriptblock executed when a condition succeeds.
The scriptblock is expected to have the signature:

OnSuccess
  [-Condition] <scriptblock>
  [-Premise] <string[]>
.PARAMETER OnFailure
Scriptblock executed when a condition fails.
The scriptblock is expected to have the same
signature as OnSuccess.
.EFFECTS
No side effects.
.EXCEPTION
If one of conditions evaluates to False and
OnFailure is not provided, throws an exception.
The exception object is a message string with
the failed Condition.
.OUTPUTS
No output.
#>
function Expect-Condition {
  [OutputType([void])]
  param (
    [Object[]]    $Conditions,
    [scriptblock] $OnSuccess,
    [scriptblock] $OnFailure
  )

  $condition = $null
  $premises  = [List[string]]::new()

  function _assert {
    if ($condition) {
      try {
        Assert $condition $premises

        if ($OnSuccess) {
          &$OnSuccess $condition $premises
        }
      } catch {
        if ($OnFailure) {
          &$OnFailure $condition $premises
        } else {
          throw $_
        }
      }

      $premises.Clear()
    }
  }

  for ($i = 0; $i -lt $Conditions.Count; $i++) {
    switch ($Conditions[$i].GetType()) {
      scriptblock {
        _assert
        $condition = $Conditions[$i]
      } string {
        $premises.Add($Conditions[$i])
      } Default {
        throw 'Unknown type $_'
      }
    }
  }

  _assert
}


<#
.SYNOPSIS
Run and format a test.
.DESCRIPTION
Given Action and Result, formats the test header. Then runs the test
Script and outputs its result.
TODO
Test Context parameter.
.PARAMETER Action
Description of tested code, displayed as a part of the header.
Action or argument.
.PARAMETER Script
Scripblock, the output of which is piped back to the caller.
.PARAMETER Context
Description of a context, in which the tested code runs.
.PARAMETER Result
Description of the result of tested code, displayed as a part
of the header.
.PARAMETER Group
Test is a group of other tests. This indication is
used to improve visual distinctiveness of the output.
.PARAMETER First
First test have less space above the header.
.EFFECTS
No side effects aside from the side effects of a given script.
.OUTPUTS
Array of objects in that order:
-An array of strings constituting the test header
-Output of Script that can be null
#>
function New-Test {
  [OutputType([Object[]])]
  param(
    [string]      $Action,
    [scriptblock] $Script,
    [string]      $Context,
    [string]      $Result,
    [switch]      $Group,
    [switch]      $First
  )

  #region Head
  #———————————

    $labelStl = $PSStyle.Foreground.BrightMagenta
    $style0   = $PSStyle.Foreground.BrightMagenta
    $style1   = $PSStyle.Foreground.BrightGreen

    if ($Group) {
    $space  = "`t"
    $label  = "TEST GROUP"
    } else {
    $space  = ""
    $label  = "TEST"
    }

    $r  = $PSStyle.Reset

    ""
    if (-not $First) {
    "","",""
    if ($Group) {
    "","",""
    }
    }
    if ($Context) {
      "$space$labelStl${label}"
      "$space${labelStl}Action :$r $style0$Action$r"
      "$space${labelStl}Context:$r $style0$Context$r"
      "$space${style1}result in$r $style0$Result$r"
    } else {
      "$space$labelStl${label}:$r $style0$Action$r ${style1}result in$r $style0$Result$r"
    }

  #—————————
  #endregion
  #region Output
  #—————————————

    $output = &$Script

    if ($Group) {
      $output
    } else {
      "$style1⭳⭳⭳$r"
      $output
      "$style1⭱⭱⭱$r"
    }

  #—————————
  #endregion
}

<#
.SYNOPSIS
Test and assert Code throws an exception.
.PARAMETER Cause
.PARAMETER Code
.OUTPUTS
Same as New-Test, but the output is an exception in a string
form. The form depends on the value of Verbose.
#>
function New-TestException {
  [OutputType([Object[]])]
  param(
    [string]      $Cause,
    [scriptblock] $Code
  )

  New-Test $Cause -Result "An exception" {
    $exception = $null
    $o = $null

    try {
      $o = &$Code
    } catch {
      $exception = $_
    }

    Expect-Condition { $null -ne $exception },
                     "$Cause is expected to cause an exception",
                     { $null -eq $o }

    if ($Verbose) {
      $exception | Out-String
    } else {
      "$exception"
    }
  }
}

#region StyleData
#————————————————

enum CodeColor {
  Source
  Property
  String
  Number
  Constant
  Function
  Operator
  Type
}

$CodeColor = [pscustomobject]@{
  Source   = $PSStyle.Foreground.FromRgb(0x9fcec9)
  Property = $PSStyle.Foreground.FromRgb(0xe9bb83)
  String   = $PSStyle.Foreground.FromRgb(0xce9178)
  Number   = $PSStyle.Foreground.FromRgb(0xb5cea8)
  Constant = $PSStyle.Foreground.FromRgb(0x569cd6)
  Function = $PSStyle.Foreground.FromRgb(0xecdc98)
  Operator = $PSStyle.Foreground.FromRgb(0x699e99)
  Type     = $PSStyle.Foreground.FromRgb(0x89cc96)
}

enum AvocadoColor {
  Success
  Error
  Label
}

$AvocadoColor = [pscustomobject]@{
  Success = $PSStyle.Foreground.BrightGreen
  Error   = $PSStyle.Foreground.BrightRed
  Label   = $PSStyle.Foreground.BrightBlack
}

#—————————
#endregion

<#
.SYNOPSIS
.DESCRIPTION
EFFECT
TODO
-Documentation
-Test
.PARAMETER
.OUTPUTS
#>
function Format-Colored {
  [OutputType([string])]
  param (
    [Parameter(Position=0)]
    [string]       $Object,
    [Parameter(ParameterSetName='Color')]
    [AvocadoColor] $Color,
    [Parameter(ParameterSetName='CodeColor')]
    [CodeColor]    $Code
  )

  if ($PSCmdlet.ParameterSetName -eq 'Color') {
    $ColorSet = $AvocadoColor
  } else {
    $ColorSet = $CodeColor
    [CodeColor] $Color = $Code
  }

  "$($ColorSet.$Color)$Object$($PSStyle.Reset)"
}

Export-ModuleMember -Variable @(
  'CodeColor'
  'AvocadoColor'
)