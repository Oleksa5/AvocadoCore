param([switch] $Verbose)

Import-Module AvocadoCore -Force -DisableNameChecking

$PSModuleAutoLoadingPreference = 'none'
$WarningPreference = 'Continue'
$ErrorActionPreference = 'Stop'

#region Common
#—————————————

  $t = $PSStyle.Foreground.Green
  $r = $PSStyle.Reset

  $nl  = [Environment]::NewLine
  $tnl = $nl * 2
  $gnl = $nl * 7

  $groupBgn0    = "$nl`t`t${t}TEST GROUP:$r"
  $groupBgn     = "$gnl$groupBgn0"
  $testBgn0     = "$nl${t}TEST:"
  $testBgn      = "$tnl$testBgn0"
  $topBorder    = "$t⭳⭳⭳$r" # ⤒⤓ ⭱⭳
  $bottomBorder = "$t⭱⭱⭱$r"

  class C {}
  $classObj = [C]::new()

  function TestAssert {
    param ([scriptblock] $Assert)

    $Name = ("$Assert".Trim() -split ' ')[0]

    #region TEST True
    #———————————

      "$testBgn0 Script that outputs an object that evaluates to True results in no exception."

      foreach ($item in $true, 3, "abc", $classObj) {
        $exception = $null
        $o = $null

        try {
          #region CODE
          #———————————

            $o = &$Assert { $item }

          #—————————
          #endregion
        } catch {
          $exception = $_
        }

        if ($null -ne $exception) {
          throw "Test $Name True has failed with the exception: $exception."
        }

        if ($null -ne $o) {
          throw "Test $Name True has failed with the unexpected output: $o."
        }
      }

    #—————————
    #endregion

    #region TEST False
    #———————————

      "$testBgn Script that outputs an object that evaluates to False results in an exception."

      $exception = $null

      foreach ($item in $false, 0, "", $null) {
        $o = $null

        try {
          #region CODE
          #———————————

            $o = &$Assert { $item }

          #—————————
          #endregion
        } catch {
          $e = $_ | Out-String
          $exception ??= $e
          if ($e -ne $exception) {
            throw "Exceptions are expected to be equal for all types."
          }
        }

        if ($null -eq $exception) {
          throw "Test $Name False has failed. An exception is expected."
        }

        if ($null -ne $o) {
          throw "Test $Name False has failed with the unexpected output: $o."
        }
      }

      $topBorder
      $exception | Out-String
      $bottomBorder

    #—————————
    #endregion

    #region TEST Premises
    #———————————

      "$testBgn Array of strings results in the strings shown in an exception message."

      $exception = $null
      $o = $null

      try {
        #region CODE
        #———————————

          $condition = $false
          $o = Assert { $condition } `
            "Condition is expected to be True",
            "True evaluates to True"

        #—————————
        #endregion
      } catch {
        $exception = $_
      }

      if ($null -eq $exception) {
        throw "Test $Name Premises has failed. An exception is expected."
      }

      if ($null -ne $o) {
        throw "Test $Name Premises has failed with the unexpected output: $o."
      }

      $topBorder
      $exception | Out-String
      $bottomBorder

    #—————————
    #endregion
  }

#—————————
#endregion

switch (1) {
0 {
#region TESTGROUP Assert
#————————————————

  "$groupBgn0 Assert"

  TestAssert {
    Assert @args
  }

#—————————
#endregion
} 1 {
#region TESTGROUP Expect-Condition
#————————————————

  "$groupBgn Expect-Condition"

  TestAssert {
    Expect-Condition @args
  }

  #region TEST Multiple conditions
  #———————————

    "$testBgn Array of conditions results in all conditions are evaluated."

    $exception = $null
    try {
      #region CODE
      #———————————

        Expect-Condition { $true  },
                         { 3      },
                           "Condition is expected to be 3",
                           "3 evaluates to True",
                         { $false },
                           "Condition is expected to be True",
                           "True evaluates to True"

      #—————————
      #endregion
    } catch {
      $exception = $_
    }

    if ($null -eq $exception) {
      throw "Test Expect-Condition Multiple conditions has failed."
    }

    $topBorder
    $exception | Out-String
    $bottomBorder

  #—————————
  #endregion

#—————————
#endregion
} 2 {
#region TESTGROUP New-Test
#————————————————

  "$groupBgn New-Test"

  function AddNumbers {
    param (
      $Num0,
      $Num1
    )

    $Num0 + $Num1
  }

  #region TEST Basic
  #———————————

    "$testBgn0 Given strings and a script result in the header"
    "comprising the strings and the piped back output of the script."

    #region CODE
    #———————————

      $o = New-Test "2 integers" -Result "Their sum" {
        AddNumbers 1 3
      }

    #—————————
    #endregion

    $os = $o | Out-String

    Expect-Condition { $os -match "2 integers"     },
                     { $os -match "Their sum"      },
                     { $os -match (AddNumbers 1 3) }

    $topBorder
    $o
    $bottomBorder

  #—————————
  #endregion

  #region TEST -First
  #———————————

    "$testBgn -First results in less space above the header."

    #region CODE
    #———————————

      $o = New-Test "2 integers" -Result "Their sum" -First {
        AddNumbers 1 3
      }

    #—————————
    #endregion

    $topBorder
    $o
    $bottomBorder

  #—————————
  #endregion

  #region TEST -Group
  #———————————

    "$testBgn -Group results in the visual distinctiveness of"
    "the group of tests placed inside the test."

    #region CODE
    #———————————

      $o = New-Test -Group "AddNumbers" -Result "Sum of numbers" {
        New-Test "2 integers" -Result "Their sum" {
          AddNumbers 1 3
        }
      }

    #—————————
    #endregion

    $topBorder
    $o
    $bottomBorder

  #—————————
  #endregion

#—————————
#endregion
} 3 {
#region TESTGROUP New-TestException
#————————————————

  "$groupBgn New-TestException"

  #region TEST Throw
  #———————————

    "$testBgn0 Code throwing an exception results in a successful assertion,"
    "the header and the exception string."

    function DoSomething {
      param([Object[]] $Element)

      if ($Element.Count -lt 3) {
        throw "Too few elements."
      }
    }

    #region CODE
    #———————————

      $o = New-TestException -Cause "Less than three elements" -Code {
        DoSomething 3,5
      }

    #—————————
    #endregion

    $topBorder
    $o
    $bottomBorder

  #—————————
  #endregion

  #region TEST Not throw
  #———————————

    "$testBgn0 Code not throwing an exception results in a failed assertion."

    $exception = $null
    $o = $null

    try {
      #region CODE
      #———————————

        $o = New-TestException -Cause "" -Code {
          DoSomething 3,5,1
        }

      #—————————
      #endregion
    } catch {
      $exception = $_
    }

    Expect-Condition { $null -eq $o },
                     { $null -ne $exception }

    $topBorder
    $exception | Out-String
    $bottomBorder

  #—————————
  #endregion

#—————————
#endregion
} 4 {
New-Test "Style Data" -R "" -Group {
  New-Test "Style color" -R "" -First{
    #region Code
    #———————————

      "$($CodeColor.Function)Do-Something$($PSStyle.Reset)"
      "$($AvocadoColor.Success)abc$($PSStyle.Reset)"

    #—————————
    #endregion
  }

  function IterateColor {
    param ([Collections.IDictionary] $StyleColor)

    foreach ($color in $StyleColor.GetEnumerator()) {
      "$($color.Value)$($color.Key)"
    }
  }

  New-Test "Iterate CodeColor" -R "" -First {
    #region Test
    #———————————

      IterateColor $CodeColor

    #—————————
    #endregion
  }

  New-Test "Iterate StyleColor" -R "" -First {
    #region Test
    #———————————

      IterateColor $AvocadoColor

    #—————————
    #endregion
  }
}
}
}