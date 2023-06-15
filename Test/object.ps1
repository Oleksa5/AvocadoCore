param([switch] $Verbose)

Import-Module AvocadoCore -Force -DisableNameChecking

$PSModuleAutoLoadingPreference = 'None'
$WarningPreference             = 'Continue'
$ErrorActionPreference         = 'Stop'

switch (2) {
0 {
New-Test -Group "Get-Property" -R ""  {

  $obj0 = Get-ClassTestee 0
  $property = @{ E='Name' }, @{ E='Value' }

  New-Test "Object" -R "" -First {
    #region Code
    #———————————

      Get-Property $obj0 | Format-Table $property

    #—————————
    #endregion
  }

  $obj1 = Get-ClassTestee 1

  New-Test "Array" -R "" {
    #region Code
    #———————————

      Get-Property $obj0, $obj1 | Format-Table $property

    #—————————
    #endregion
  }

  New-Test "ElementAsProperty" -R "" {
    #region Code
    #———————————

      Get-Property $obj0, $obj1 -ElementAsProperty

    #—————————
    #endregion
  }
}
} 1 {
New-Test "HasProperty" -R "" -Group {

  $obj = Get-ClassTestee 0

  New-Test "Object" -R "" -First {
    #region Code
    #———————————

      HasProperty $obj
      HasProperty "abc"
      HasProperty 3
      HasProperty $null

    #—————————
    #endregion
  }
}
} 2 {
New-Test -Group "Prepend-Property" -R "" {

  New-Test "Object and Property" -R "" -First {
    #region Test
    #———————————

      $obj = Get-ClassTestee

    #—————————
    #endregion
    #region Code
    #———————————

      $o = Prepend-Property $obj ([pscustomobject]@{ Prepended = 108 })

    #—————————
    #endregion
    #region Test
    #———————————

      $o | Format-List

    #—————————
    #endregion
  }

  New-Test "Two Objects" -R "" -First {
    #region Test
    #———————————

      $obj0 = Get-ClassTestee 0 -Type 0
      $obj1 = Get-ClassTestee 1 -Type 1

    #—————————
    #endregion
    #region Code
    #———————————

      Prepend-Property $obj0 $obj1

    #—————————
    #endregion
  }

  New-Test "Only Property" -R "" {
    #region Test
    #———————————

      $obj = Get-ClassTestee

    #—————————
    #endregion
    #region Code
    #———————————

      $o = Prepend-Property $null $obj

    #—————————
    #endregion
    #region Test
    #———————————

      $o | Format-List

    #—————————
    #endregion
  }

  New-Test "Only Object" -R "" {
    #region Test
    #———————————

      $obj = Get-ClassTestee

    #—————————
    #endregion
    #region Code
    #———————————

      $o = Prepend-Property $obj $null

    #—————————
    #endregion
    #region Test
    #———————————

      $o | Format-List

    #—————————
    #endregion
  }

  New-Test "Both null" -R "" {
    #region Code
    #———————————

      $o = Prepend-Property $null $null

    #—————————
    #endregion
    #region Test
    #———————————

      $o | Format-List

    #—————————
    #endregion
  }
}
}
}