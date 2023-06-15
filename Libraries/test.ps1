<#
.SYNOPSIS
Format function call components as a function scheme.
.DESCRIPTION
.PARAMETER Component
Array of objects, where an element at 0 is the argument of a call,
at 1 - function, at 2 - output. An element after the output starts
components for the next scheme.
.PARAMETER Width
Array of widths for component columns. Width at index 0 is
for the argument column, at 1 - for function, at 2 - for output.
.PARAMETER Center
Center components horizontally in their columns.
.OUTPUTS
string[]
Array of function schemes.
#>
function Format-FunctionScheme {
  [OutputType([string[]])]
  param(
    [Parameter(Position=0, ValueFromRemainingArguments)]
    [Object[]] $Component,
    [int   []] $Width,
    [switch  ] $Center
  )

  #region Lib
  #——————————

    <#
    .OUTPUTS
    Always returns an array object containing zero or more array objects
    representing schemes. Scheme object is an array of three strings
    for an argument, function and ouput.
    #>
    function NewScheme {
      [OutputType([string[][]])]
      param(
        [Object[]] $Components
      )

      $schemes = [List[string[]]]::new()

      for ($i = 0; $i -lt $Components.Count; $i+=3) {
        $scheme = @(
          FormatComponent $Components[$i]
          FormatComponent $Components[$i+1]
          FormatComponent $Components[$i+2]
        )
        Assert { $scheme[1] }

        $schemes.Add($scheme)
      }

      , $schemes.ToArray()
    }

    function FormatComponent {
      [OutputType([string])]
      param (
        [Object] $Component
      )

      if ($Component -is [scriptblock]) {
        $Component = "{$Component}"
      }

      "$Component"
    }

    function FindMaxComponentLength {
      [OutputType([int[]])]
      param (
        [Object[]] $StringArray
      )

      [int] $StringCount = 3
      $len = ,0 * $StringCount

      foreach ($array in $StringArray) {
        Assert { $array -is [array] }

        for ($i = 0; $i -lt $StringCount; $i++) {
          Assert { $array[$i] -is [string] }

          $len[$i] = [Math]::Max($array[$i].Length, $len[$i])
        }
      }

      $len
    }

    function FormatStyledComponent {
      [OutputType([void])]
      param (
        [Object[]] $Scheme
      )

      foreach ($s in $Scheme) {
        Assert { $s -is [array] }
        $s[0] = $s[0] ? "$($CodeColor.Source  )$($s[0])$r" : ""
        $s[1] =         "$($CodeColor.Function)$($s[1])$r"
        $s[2] = $s[2] ? "$($CodeColor.Source  )$($s[2])$r" : ""
      }
    }

    function FormatSchemeTable {
      [OutputType([string[]])]
      param (
        [Object[]] $Scheme,
        [int[]]    $Width,
        [bool]     $Center
      )

      Assert { $null -ne $Width }

      $ArgmntA = $Center ? "center" : "left"
      $OutputA = $ArgmntA

      $arw = "$($CodeColor.Operator)→$r"
      $arw0 = { $_[0] ? $arw : '' }
      $arw1 = { $_[2] ? $arw : '' }

      [Object] $scheme = ,$Scheme | Format-Table @(
        if ($Width[0] -ne 0) {
        @{ E={ $_[0] }; W=$Width[0]; Align=$ArgmntA }
        @{ E=  $arw0  ; W=1        ; Align="center" }
        }
        @{ E={ $_[1] }; W=$Width[1]; Align="center" }
        if ($Width[2] -ne 0) {
        @{ E=  $arw1  ; W=1        ; Align="center" }
        @{ E={ $_[2] }; W=$Width[2]; Align=$OutputA }
        }
      ) -Force -HideTableHeaders -DisplayError

      Use-AnsiOutputRendering

      $scheme = Trim-EmptyLine ($scheme | Out-String)

      Reset-OutputRendering

      $scheme
    }

  #—————————
  #endregion

  $schemes = NewScheme $Component
  $Width ??= FindMaxComponentLength $schemes
  FormatStyledComponent $schemes
  FormatSchemeTable $schemes $Width $Center
}

<#
.SYNOPSIS
Format conditions as successful.
.DESCRIPTION
.PARAMETER Conditions
.OUTPUTS
String[]
Formatted conditions.
#>
function Format-Expect {
  [OutputType([string[]])]
  param(
    [string[]] $Conditions
  )

  $Conditions  = $Conditions | ForEach-Object { "✔ $_" }
  $conditionsF = $Conditions -join [Environment]::NewLine
  $conditionsF = "$($AvocadoColor.Success)$conditionsF$r"

  ""
  $conditionsF
}

#region Testee
#—————————————

  class ClassTestee0 {
    [int   ] $Num
    [string] $Text
    [bool  ] $Condition
    [Object] $Child
  }

  class ClassTestee0Short {
    [int ] $Num
    [bool] $Condition
  }

  class ClassTestee1 {
    [Object] $A
    [Object] $B
    [Object] $C
  }

  <#
  .SYNOPSIS
  Get an object to use in a function test.
  .PARAMETER Index
  .PARAMETER Depth
  Depth of the descendent tree.
  .PARAMETER Short
  .OUTPUTS
  Object
  #>
  function Get-ClassTestee {
    [OutputType([Object])]
    param(
      [int]    $Index,
      [int]    $Type,
      [int]    $Depth = -1,
      [switch] $Short
    )

    #region Lib
    #——————————

      function NewClassTestee0 {
        [OutputType([ClassTestee0])]
        param(
          [int] $Index
        )

        $obj = [ClassTestee0]::new()

        switch ($Index) {
          0 {
            $obj.Num       = 5
            $obj.Text      = "blue sky"
            $obj.Condition = $true
            $obj.Child     = $null
          } 1 {
            $obj.Num       = 1
            $obj.Text      = "white cloud"
            $obj.Condition = $true
            $obj.Child     = $null
          } 2 {
            $obj.Num       = 3
            $obj.Text      = "green tree"
            $obj.Condition = $false
            $obj.Child     = $null
          } Default {
            throw "No object at Index $Index."
          }
        }

        $obj
      }

      function NewClassTestee0Short {
        $obj = [ClassTestee0Short]::new()
        $obj.Num = 5
        $obj.Condition = $true

        $obj
      }

      function NewClassTestee1 {
        [OutputType([ClassTestee1])]
        param(
          [int] $Index
        )

        $obj = [ClassTestee1]::new()

        switch ($Index) {
          0 {
            $obj.A = 1
            $obj.B = 22
            $obj.C = 333
          } Default {
            throw "No object at Index $Index."
          }
        }

        $obj
      }

      function SortIndices {
        param ($First)

        $allIndices = 0,1,2
        Assert { $allIndices -contains $First }

        @($First) + ($allIndices -ne $First)
      }

    #—————————
    #endregion

    $indices = SortIndices -First $Index

    switch ($Type) {
      0 {
        if ($Short) {
          $obj = NewClassTestee0Short
          if ($Index -ne 0) {
            Write-Warning "Get-ClassTestee -Short ignores Index."
          } if ($NoDescendant) {
            Write-Warning "Get-ClassTestee -Short has no descendants regardless of NoDescendant."
          }
        } else {
          switch ($Depth) {
            0 {
              $obj = NewClassTestee0 $indices[0]
            } 1 {
              $obj       = NewClassTestee0 $indices[0]
              $obj.Child = NewClassTestee0 $indices[1]
            } Default {
              $obj             = NewClassTestee0 $indices[0]
              $obj.Child       = NewClassTestee0 $indices[1]
              $obj.Child.Child = NewClassTestee0 $indices[2]
            }
          }
        }
      } 1 {
        $obj = NewClassTestee1
      } Default {
        throw "No type at Index $Type."
      }
    }

    $obj
  }

#—————————
#endregion