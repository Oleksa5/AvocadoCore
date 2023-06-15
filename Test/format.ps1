using namespace System.Collections.Generic

param([switch] $Verbose)

Import-Module AvocadoCore -Force -DisableNameChecking

$PSModuleAutoLoadingPreference = 'None'
$WarningPreference             = 'Continue'
$ErrorActionPreference         = 'Stop'

$testIndex = 10

if ($testIndex -contains 0) {
  New-Test "Format-Exception" -R "Formatted exception" -Group -First {
    New-Test               `
      "ErrorRecord object" `
      -R "Formatted ErrorRecord string" `
      -First               `
      -Script {
        #region CODE
        #———————————

          try {
            throw "abc"
          } catch {
            $o = Format-Exception $_
          }

        #—————————
        #endregion

        Remove-AnsiStyle ($o | Out-String)
      }
  }
}

# TODO: move to test scopes
$obj0 = Get-ClassTestee 0 -Depth 0
$obj1 = Get-ClassTestee 1

try {
  switch ($testIndex) {
  1 {
  New-Test -Group "Indent-Line" -R "Intended string lines" {

    $objS = $obj0 | Format-List | Out-String

    New-Test "Formatted class object with no explicit level" -R "" -First {
      #region Code
      #———————————

        Indent-Line $objS

      #—————————
      #endregion
    }

    New-Test "Level 0" -R "No indent" {
      #region Code
      #———————————

        Indent-Line $objS -Level 0

      #—————————
      #endregion
    }

    New-Test "Level 1" -R "" {
      #region Code
      #———————————

        Indent-Line $objS -Level 1

      #—————————
      #endregion
    }

    New-Test "Level 1, Size 1" -R "" {
      #region Code
      #———————————

        Indent-Line $objS -Level 1 -Size 1

      #—————————
      #endregion
    }

    New-Test "Level 1, Size 2" -R "" {
      #region Code
      #———————————

        Indent-Line $objS -Level 1 -Size 2

      #—————————
      #endregion
    }
  }
  } 2 {
  New-Test -Group "Trim-EmptyLine" -R "" {
    New-Test "String with new lines around text" -R "" -First {
      $nl = [System.Environment]::NewLine

      #region Code
      #———————————

        $o = Trim-EmptyLine "${nl}abc$nl$nl"

      #—————————
      #endregion
      #region Test
      #———————————

        Expect-Condition { $o -eq "abc" }

        $o

      #—————————
      #endregion
    }
  }
  } 3 {
  New-Test -Group "Shorten-String" -R "" {

    $obj = "Beautiful modern city"

    New-Test "Count 10" -R "" -First {
      #region Code
      #———————————

        Shorten-String $obj -Count 10

      #—————————
      #endregion
    }

    New-Test "LeftOut" -R "" {
      #region Code
      #———————————

        Shorten-String $obj -Count 10 -LeftOut Start
        Shorten-String $obj -Count 10 -LeftOut Middle
        Shorten-String $obj -Count 10 -LeftOut End

      #—————————
      #endregion
    }

    New-Test "Ellipsis" -R "" {
      #region Code
      #———————————

        Shorten-String $obj -Count 10
        Shorten-String $obj -Count 10 -Ellipsis "..."
        Shorten-String $obj -Count 10 -Ellipsis "***"

      #—————————
      #endregion
    }
  }
  } 4 {
  New-Test -Group "Remove-AnsiStyle" -R "String with no SGR" {
    #region Test
    #———————————

      $sequences = [ordered]@{
        $PSStyle.Foreground.BrightGreen = $null
        $PSStyle.Background.Green       = $null
        $PSStyle.Bold                   = $PSStyle.BoldOff
        $PSStyle.Italic                 = $PSStyle.ItalicOff
      }

    #—————————
    #endregion

    $index = 0
    foreach ($s in $sequences.GetEnumerator()) {
      #region Test
      #———————————

        $sequence    = $s.Key
        $r           = $s.Value ?? $PSStyle.Reset
        $sequenceHex = $sequence | Format-Hex
        $first       = $index -eq 0

      #—————————
      #endregion
      New-Test                `
        "String with $($sequenceHex.Ascii)" `
        -R "Plain string"  `
        -First:$first      `
        -Script {
          #region Code
          #———————————

            $text = "green ${sequence}apple$r"
            $o = Remove-AnsiStyle $text

          #—————————
          #endregion
          #region Test
          #———————————

            Expect-Condition { $sequence -is [string] }
            # at a minimum the sequence is "`e[nm"
            Expect-Condition { $sequence.Length -gt 2 }
            Expect-Condition { $o -eq "green apple" }

            $text
            ""
            "$($text | Format-Hex)" -replace '(?m)^ +'
            ""
            "↓"
            ""
            $o
            ""
            "$($o | Format-Hex)"

          #—————————
          #endregion
        }

      $index++
    }
  }
  } 5 {
  New-Test -Group "OutputRendering" -R "" {
    New-Test "Default" -R "" -First {
      #region Code
      #———————————

        $o = $obj0 | Out-String

      #—————————
      #endregion
      #region Test
      #———————————

        "OutputRendering: $($PSStyle.OutputRendering)"
        Expect-Condition { $PSStyle.OutputRendering -eq 'Host' }
        "Host is the default behavior. The ANSI escape sequences are removed from redirected or piped output."
        $o

      #—————————
      #endregion
    }

    New-Test "Use-AnsiOutputRender" -R "" {
      #region Code
      #———————————

        Use-AnsiOutputRendering
        #region Test
        #———————————

          $outputRendering = $PSStyle.OutputRendering

        #—————————
        #endregion
        $o = $obj0 | Out-String
        Reset-OutputRendering

      #—————————
      #endregion
      #region Test
      #———————————

        "OutputRendering: $outputRendering"
        Expect-Condition { $outputRendering -eq 'ANSI' }
        "ANSI escape sequences are always passed through as-is."
        $o

      #—————————
      #endregion
    }
  }
  } 6 {
  New-Test -Group "Format-ObjectInfo" -R "ObjectInfoFormat" {
    #region Code
    #———————————

      $o = Format-ObjectInfo obj0 $obj0

    #—————————
    #endregion

    New-Test "Name and object" -R "" -First {
      #region Test
      #———————————

        $o

      #—————————
      #endregion
    }

    New-Test "Interpolated output" -R "" {
      #region Test
      #———————————

        "$o"

      #—————————
      #endregion
    }

    New-Test "Null" -R "" {
      #region Code
      #———————————

        Format-ObjectInfo obj $null

      #—————————
      #endregion
    }
  }
  } 7 {
  New-Test -Group "Format-Code" -R "" {
    New-Test "Different types of Value" -R "" -First {
      #region Code
      #———————————

        Format-Code 5
        Format-Code abc
        Format-Code abc -Type Source
        Format-Code abc -Type Property
        Format-Code $true
        Format-Code { DoSomething }
        Format-Code $obj0
        Format-Code $obj0.GetType()

      #—————————
      #endregion
    }
  }
  } 8 {
  New-Test -Group "Format-ExtendedTable" -R "Objects formatted as extended table" {

    $obj0 = Get-ClassTestee 0 -Depth 0
    $obj1 = Get-ClassTestee 1 -Depth 0
    $obj2 = Get-ClassTestee 0 -Short

    New-Test "Dictionary for Object" -R "Table with keys as object names" -First {
      #region Code
      #———————————

        Format-ExtendedTable (
          [ordered]@{ obj0 = $obj0
                      obj1 = $obj1
                      obj2 = $obj2 }
        )

      #—————————
      #endregion
    }

    New-Test "Array for Object" -R "Table with indices as object names" {
      #region Code
      #———————————

        Format-ExtendedTable $obj0, $obj2

      #—————————
      #endregion
    }

    New-Test "Parent" -R "Parent name prepended to object name" {
      #region Code
      #———————————

        Format-ExtendedTable $obj0, $obj2 -Parent 'prn'

      #—————————
      #endregion
    }

    New-Test "Null" -R "" {
      #region Code
      #———————————

        $obj = $null

        Format-ExtendedTable @{ obj = $obj }

      #—————————
      #endregion
    }

    New-TestException "Expandable object" {
      #region Test
      #———————————

        $obj = Get-ClassTestee -Depth 1

      #—————————
      #endregion
      #region Code
      #———————————

        Format-ExtendedTable @{ obj = $obj }

      #—————————
      #endregion
    }
  }
  } 9 {
  New-Test -Group "Expand-Property" -R "Property[]" {

    $obj = Get-ClassTestee 1

    New-Test "Class object with class descendants" `
        -R "Object and its descendants are expanded" -First {
      #region Code
      #———————————

        $o = Expand-Property $obj

      #—————————
      #endregion
      #region Test
      #———————————

        $property = $o | Where-Object { $_.Ancestors.Count -eq 2 }

        Expect-Condition @(
          { $property[0].Ancestors[0].Value -eq $obj.Child }
            "Ancestors list order is: " +
            "ancestors closest to the root -> ancestors closest to the property"
        )

        $o

      #—————————
      #endregion
    }

    New-Test "Depth 0" -R "No child is expanded" {
      #region Code
      #———————————

        Expand-Property $obj -Depth 0

      #—————————
      #endregion
    }
  }
  } 10 {
  New-Test -Group "Format-Expanded" -R "" {

    $obj = Get-ClassTestee 0

    New-Test "Only class object with class descendants" -R "" -First {
      #region Code
      #———————————

        Format-Expanded $obj

      #—————————
      #endregion
    }

    New-Test "Name" -R "" {
      #region Code
      #———————————

        Format-Expanded $obj -Name obj

      #—————————
      #endregion
    }

    New-Test "Depth 1" -R "" {
      #region Code
      #———————————

        Format-Expanded $obj -Depth 1

      #—————————
      #endregion
    }

    New-Test "ShowTypes" -R "" {
      #region Code
      #———————————

        Format-Expanded $obj -ShowTypes

      #—————————
      #endregion
    }

    New-Test "Null" -R "" {
      #region Code
      #———————————

        Format-Expanded $null

      #—————————
      #endregion
    }
  }
  }
  }
} catch {
  Format-Exception $_
}
