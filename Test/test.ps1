using namespace System.Collections.Generic

param([switch] $Verbose)

Import-Module AvocadoCore -Force -DisableNameChecking

$PSModuleAutoLoadingPreference = 'none'
$WarningPreference = 'Continue'
$ErrorActionPreference = 'Stop'

switch (2) {
0 {
New-Test -Group 'Format-FunctionScheme' -R "0 or more schemes representing function calls" {

  $allOutputs = [List[Object]]::new()

  #region Tests
  #————————————

    New-Test                                    `
      "3 string arguments"                      `
      -R "1 compact scheme with no extra space" `
      -First {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg f o

        #—————————
        #endregion
        #region Test
        #———————————

          Expect-Condition { $o -notmatch "  " }

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-Test `
      "Argument or output omission in the whole group" `
      -R "No error" { # TODO: replace No error with the actual result
        #region Code
        #———————————

          Format-FunctionScheme '' f o
          Format-FunctionScheme arg f ''

        #—————————
        #endregion
      }

    New-Test `
      "9 string arguments with different lengths of corresponding components" `
      -R "3 aligned schemes" {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg0 f0 o0 `
                                    arg1 f1 o1 `
                                    argument2 function2 output2 `

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-Test `
      "3 separate function calls" `
      -R "3 unaligned schemes" {
        #region Code
        #———————————

          $o0 = Format-FunctionScheme arg0 f0 o0
          $o1 = Format-FunctionScheme arg1 f1 o1
          $o2 = Format-FunctionScheme argument2 function2 output2

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.AddRange(($o0,$o1,$o2))

          $o0,$o1,$o2

        #—————————
        #endregion
      }

    New-Test `
      "Width larger than a component length" `
      -R "Spaced component" {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg f o -Width 10,10,10

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-Test `
      "Width shorter than a component length" `
      -R "Trimmed component" {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg functn output -Width 5,5,5

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-Test `
      "Center without explicit width" `
      -R "No difference" {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg f o -Center

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-Test `
      "Center with an explicit width larger than a component length" `
      -R "Component centered in the width space" {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg f o -Width 10,10,10 -Center

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-TestException `
      "Partial width specification" {
        #region Code
        #———————————

          Format-FunctionScheme arg f o -Width 10

        #—————————
        #endregion
      }

    New-Test               `
      "Omit component"  `
      -R "Persisting component alignment and absent respective arrow" {
        #region Code
        #———————————

          $o = Format-FunctionScheme arg0 f0 o0 `
                                    ''   f1 o1 `
                                    arg2 f2

        #—————————
        #endregion
        #region Test
        #———————————

          $allOutputs.Add($o)

          $o

        #—————————
        #endregion
      }

    New-TestException `
      "Omitting function" {
        #region Code
        #———————————

          Format-FunctionScheme arg0 '' o0

        #—————————
        #endregion
      }

    New-Test `
      "Omitting Width parameter name" `
      -R "argument binding as component" {
        #region Code
        #———————————

          Format-FunctionScheme arg0 f0 o0 arg1 f1 10,10,10

        #—————————
        #endregion
      }

  #—————————
  #endregion

  foreach ($output in $allOutputs) {
    Expect-Condition { $output -is [string] }
  }
}
} 1 {
New-Test -Group 'Format-Expect' -R "" {

  New-Test "Array of condition strings" -R "" -First {
    #region Code
    #———————————

      $o = Format-Expect "condition 0",
                          "condition 1",
                          "condition 2"

    #—————————
    #endregion
    #region Test
    #———————————

      Expect-Condition { $o -match "condition 0" },
                        { $o -match "condition 1" },
                        { $o -match "condition 2" }

      $topBorder
      $o
      $bottomBorder

    #—————————
    #endregion
  }
}
} 2 {
New-Test -Group "Get-ClassTestee" -R "" {

  New-Test "Index" -R "" -First {
    #region Code
    #———————————

      $o0 = Get-ClassTestee
      $o1 = Get-ClassTestee 1
      $o2 = Get-ClassTestee 2

    #—————————
    #endregion
    #region Test
    #———————————

      $o0 | Format-Custom
      $o1 | Format-Custom
      $o2 | Format-Custom

    #—————————
    #endregion
  }

  New-Test "Type" -R "" {
    #region Code
    #———————————

      $o0 = Get-ClassTestee 0 -Type 0
      $o1 = Get-ClassTestee 0 -Type 1

    #—————————
    #endregion
    #region Test
    #———————————

      $o0 | Format-Table
      $o1 | Format-Table

    #—————————
    #endregion
  }

  New-Test "Depth" -R "" {
    #region Code
    #———————————

      $o  = Get-ClassTestee
      $o0 = Get-ClassTestee -Depth 0
      $o1 = Get-ClassTestee -Depth 1
      $o2 = Get-ClassTestee -Depth 2
      $o3 = Get-ClassTestee -Depth 3

    #—————————
    #endregion
    #region Test
    #———————————

      "No explicit Depth:"
      $o | Format-Custom
      "Depth 0:"
      $o0 | Format-Custom
      "Depth 1:"
      $o1 | Format-Custom
      "Depth 2:"
      $o2 | Format-Custom
      "Depth 3:"
      $o3 | Format-Custom

    #—————————
    #endregion
  }

  New-Test "Short" -R "" {
    #region Code
    #———————————

      Get-ClassTestee -Short

    #—————————
    #endregion
  }
}
}
}