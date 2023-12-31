//
//  UDInput+Theme.swift
//  UniverseDesignInput
//
//  Created by 姚启灏 on 2020/11/24.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
  /// Input Label Text Color , Value: "input-label-text-color"
  static let inputLabelTextColor = UDColor.Name("input-label-text-color")

  /// Input Label Text Color , Value: "input-label-title-color"
  static let inputLabelTitleColor = UDColor.Name("input-label-title-color")

  /// Input Required Color , Value: "input-required-color"
  static let inputRequiredColor = UDColor.Name("input-required-color")

  /// Input Normal Border Color , Value: "input-normal-border-color"
  static let inputNormalBorderColor = UDColor.Name("input-normal-border-color")

  /// Input Normal Bg Color , Value: "input-normal-bg-color"
  static let inputNormalBgColor = UDColor.Name("input-normal-bg-color")

  /// Input Normal Placeholder Text Color , Value: "input-normal-placeholder-text-color"
  static let inputNormalPlaceholderTextColor = UDColor.Name("input-normal-placeholder-text-color")

  /// Input Normal Helper Validation Text Color , Value: "input-normal-helper-validation-text-color"
  static let inputNormalHelperValidationTextColor = UDColor.Name("input-normal-helper-validation-text-color")

  /// Input Activated Border Color , Value: "input-activated-border-color"
  static let inputActivatedBorderColor = UDColor.Name("input-activated-border-color")

  /// Input Activated Bg Color , Value: "input-activated-bg-color"
  static let inputActivatedBgColor = UDColor.Name("input-activated-bg-color")

  /// Input Activated Helper Validation Text Color , Value: "input-activated-helper-validation-text-color"
  static let inputActivatedHelperValidationTextColor = UDColor.Name("input-activated-helper-validation-text-color")

  /// Input Inputting Border Color , Value: "input-inputting-border-color"
  static let inputInputtingBorderColor = UDColor.Name("input-inputting-border-color")

  /// Input Inputting Bg Color , Value: "input-inputting-bg-color"
  static let inputInputtingBgColor = UDColor.Name("input-inputting-bg-color")

  /// Input Inputting Text Color , Value: "input-inputting-text-color"
  static let inputInputtingTextColor = UDColor.Name("input-inputting-text-color")

  /// Input Inputting Helper Validation Text Color , Value: "input-inputting-helper-validation-text-color"
  static let inputInputtingHelperValidationTextColor = UDColor.Name("input-inputting-helper-validation-text-color")

  /// Input Inputcomplete Border Color , Value: "input-inputcomplete-border-color"
  static let inputInputcompleteBorderColor = UDColor.Name("input-inputcomplete-border-color")

  /// Input Inputcomplete Bg Color , Value: "input-inputcomplete-bg-color"
  static let inputInputcompleteBgColor = UDColor.Name("input-inputcomplete-bg-color")

  /// Input Inputcomplete Text Color , Value: "input-inputcomplete-text-color"
  static let inputInputcompleteTextColor = UDColor.Name("input-inputcomplete-text-color")

  /// Input Disable Border Color , Value: "input-disable-border-color"
  static let inputDisableBorderColor = UDColor.Name("input-disable-border-color")

  /// Input Disable Bg Color , Value: "input-disable-bg-color"
  static let inputDisableBgColor = UDColor.Name("input-disable-bg-color")

  /// Input Disable Placeholder Text Color , Value: "input-disable-placeholder-text-color"
  static let inputDisablePlaceholderTextColor = UDColor.Name("input-disable-placeholder-text-color")

  /// Input Disable Text Color , Value: "input-disable-text-color"
  static let inputDisableTextColor = UDColor.Name("input-disable-text-color")

  /// Input Disable Helper Validation Text Color , Value: "input-disable-helper-validation-text-color"
  static let inputDisableHelperValidationTextColor = UDColor.Name("input-disable-helper-validation-text-color")

  /// Input Error Border Color , Value: "input-error-border-color"
  static let inputErrorBorderColor = UDColor.Name("input-error-border-color")

  /// Input Error Bg Color , Value: "input-error-bg-color"
  static let inputErrorBgColor = UDColor.Name("input-error-bg-color")

  /// Input Error Placeholdertext Color , Value: "input-error-placeholdertext-color"
  static let inputErrorPlaceholdertextColor = UDColor.Name("input-error-placeholdertext-color")

  /// Input Error Text Color , Value: "input-error-text-color"
  static let inputErrorTextColor = UDColor.Name("input-error-text-color")

  /// Input Error Helper Validation Text Color , Value: "input-error-helper-validation-text-color"
  static let inputErrorHelperValidationTextColor = UDColor.Name("input-error-helper-validation-text-color")

  /// Input Tertiary Icon Color , Value: "input-tertiary-icon-color"
  static let inputTertiaryIconColor = UDColor.Name("input-tertiary-icon-color")

  /// Input Secondary Icon Color , Value: "input-secondary-icon-color"
  static let inputSecondaryIconColor = UDColor.Name("input-secondary-icon-color")

  /// Input Railing Icon Pressed Color , Value: "input-railing-icon-pressed-color"
  static let inputRailingIconPressedColor = UDColor.Name("input-railing-icon-pressed-color")

  /// Input Property Text Color , Value: "input-property-text-color"
  static let inputPropertyTextColor = UDColor.Name("input-property-text-color")

  /// Input Property Text Disable Color , Value: "input-property-text-disable-color"
  static let inputPropertyTextDisableColor = UDColor.Name("input-property-text-disable-color")

  /// Input Property Pressedproperty Color , Value: "input-property-pressedproperty-color"
  static let inputPropertyPressedpropertyColor = UDColor.Name("input-property-pressedproperty-color")

  /// Input Tagbg Color , Value: "input-tagbg-color"
  static let inputTagbgColor = UDColor.Name("input-tagbg-color")

  /// Input Tagtext Color , Value: "input-tagtext-color"
  static let inputTagtextColor = UDColor.Name("input-tagtext-color")

  /// Input Charactercounter Normal Color , Value: "input-charactercounter-normal-color"
  static let inputCharactercounterNormalColor = UDColor.Name("input-charactercounter-normal-color")

  /// Input Password Text Color , Value: "input-password-text-color"
  static let inputPasswordTextColor = UDColor.Name("input-password-text-color")

  /// Input Icon Disable Color , Value: "input-icon-disable-color"
  static let inputIconDisableColor = UDColor.Name("input-icon-disable-color")

  /// Input Charactercounter Disable Color , Value: "input-charactercounter-disable-color"
  static let inputCharactercounterDisableColor = UDColor.Name("input-charactercounter-disable-color")

}

/// UDInput Color Theme
public struct UDInputColorTheme {

  /// Input Label Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputLabelTextColor: UIColor {
      return UDColor.getValueByKey(.inputLabelTextColor) ?? UDColor.neutralColor12
  }

  /// Input Label Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputLabelTitleColor: UIColor {
      return UDColor.getValueByKey(.inputLabelTitleColor) ?? UDColor.textTitle
  }

  /// Input Required Color Color, Default Color: UDColor.alertColor6
  public static var inputRequiredColor: UIColor {
      return UDColor.getValueByKey(.inputRequiredColor) ?? UDColor.functionDangerContentDefault
  }

  /// Input Normal Border Color Color, Default Color: UDColor.neutralColor6
  public static var inputNormalBorderColor: UIColor {
      return UDColor.getValueByKey(.inputNormalBorderColor) ?? UDColor.lineBorderComponent
  }

  /// Input Normal Bg Color Color, Default Color: UDColor.neutralColor1
  public static var inputNormalBgColor: UIColor {
      return UDColor.getValueByKey(.inputNormalBgColor) ?? UDColor.udtokenComponentOutlinedBg
  }

  /// Input Normal Placeholder Text Color Color, Default Color: UDColor.neutralColor7
  public static var inputNormalPlaceholderTextColor: UIColor {
      return UDColor.getValueByKey(.inputNormalPlaceholderTextColor) ?? UDColor.textPlaceholder
  }

  /// Input Normal Helper Validation Text Color Color, Default Color: UDColor.neutralColor7
  public static var inputNormalHelperValidationTextColor: UIColor {
      return UDColor.getValueByKey(.inputNormalHelperValidationTextColor) ?? UDColor.neutralColor7
  }

  /// Input Activated Border Color Color, Default Color: UDColor.primaryColor6
  public static var inputActivatedBorderColor: UIColor {
      return UDColor.getValueByKey(.inputActivatedBorderColor) ?? UDColor.primaryFillDefault
  }

  /// Input Activated Bg Color Color, Default Color: UDColor.neutralColor1
  public static var inputActivatedBgColor: UIColor {
      return UDColor.getValueByKey(.inputActivatedBgColor) ?? UDColor.primaryContentDefault
  }

  /// Input Activated Helper Validation Text Color Color, Default Color: UDColor.neutralColor7
  public static var inputActivatedHelperValidationTextColor: UIColor {
      return UDColor.getValueByKey(.inputActivatedHelperValidationTextColor) ?? UDColor.neutralColor7
  }

  /// Input Inputting Border Color Color, Default Color: UDColor.primaryColor6
  public static var inputInputtingBorderColor: UIColor {
      return UDColor.getValueByKey(.inputInputtingBorderColor) ?? UDColor.primaryContentDefault
  }

  /// Input Inputting Bg Color Color, Default Color: UDColor.neutralColor1
  public static var inputInputtingBgColor: UIColor {
      return UDColor.getValueByKey(.inputInputtingBgColor) ?? UDColor.udtokenComponentOutlinedBg
  }

  /// Input Inputting Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputInputtingTextColor: UIColor {
      return UDColor.getValueByKey(.inputInputtingTextColor) ?? UDColor.textTitle
  }

  /// Input Inputting Helper Validation Text Color Color, Default Color: UDColor.neutralColor7
  public static var inputInputtingHelperValidationTextColor: UIColor {
      return UDColor.getValueByKey(.inputInputtingHelperValidationTextColor) ?? UDColor.neutralColor7
  }

  /// Input Inputcomplete Border Color Color, Default Color: UDColor.neutralColor6
  public static var inputInputcompleteBorderColor: UIColor {
      return UDColor.getValueByKey(.inputInputcompleteBorderColor) ?? UDColor.neutralColor6
  }

  /// Input Inputcomplete Bg Color Color, Default Color: UDColor.neutralColor1
  public static var inputInputcompleteBgColor: UIColor {
      return UDColor.getValueByKey(.inputInputcompleteBgColor) ?? UDColor.neutralColor1
  }

  /// Input Inputcomplete Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputInputcompleteTextColor: UIColor {
      return UDColor.getValueByKey(.inputInputcompleteTextColor) ?? UDColor.neutralColor12
  }

  /// Input Disable Border Color Color, Default Color: UDColor.neutralColor6
  public static var inputDisableBorderColor: UIColor {
      return UDColor.getValueByKey(.inputDisableBorderColor) ?? UDColor.neutralColor6
  }

  /// Input Disable Bg Color Color, Default Color: UDColor.neutralColor4
  public static var inputDisableBgColor: UIColor {
      return UDColor.getValueByKey(.inputDisableBgColor) ?? UDColor.neutralColor4
  }

  /// Input Disable Placeholder Text Color Color, Default Color: UDColor.neutralColor6
  public static var inputDisablePlaceholderTextColor: UIColor {
      return UDColor.getValueByKey(.inputDisablePlaceholderTextColor) ?? UDColor.neutralColor6
  }

  /// Input Disable Text Color Color, Default Color: UDColor. neutralColor6
  public static var inputDisableTextColor: UIColor {
      return UDColor.getValueByKey(.inputDisableTextColor) ?? UDColor.neutralColor6
  }

  /// Input Disable Helper Validation Text Color Color, Default Color: UDColor.neutralColor6
  public static var inputDisableHelperValidationTextColor: UIColor {
      return UDColor.getValueByKey(.inputDisableHelperValidationTextColor) ?? UDColor.neutralColor6
  }

  /// Input Error Border Color Color, Default Color: UDColor.alertColor6
  public static var inputErrorBorderColor: UIColor {
      return UDColor.getValueByKey(.inputErrorBorderColor) ?? UDColor.functionDangerContentDefault
  }

  /// Input Error Bg Color Color, Default Color: UDColor.neutralColor1
  public static var inputErrorBgColor: UIColor {
      return UDColor.getValueByKey(.inputErrorBgColor) ?? UDColor.neutralColor1
  }

  /// Input Error Placeholdertext Color Color, Default Color: UDColor.neutralColor7
  public static var inputErrorPlaceholdertextColor: UIColor {
      return UDColor.getValueByKey(.inputErrorPlaceholdertextColor) ?? UDColor.neutralColor7
  }

  /// Input Error Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputErrorTextColor: UIColor {
      return UDColor.getValueByKey(.inputErrorTextColor) ?? UDColor.neutralColor12
  }

  /// Input Error Helper Validation Text Color Color, Default Color: UDColor.alertColor6
  public static var inputErrorHelperValidationTextColor: UIColor {
      return UDColor.getValueByKey(.inputErrorHelperValidationTextColor) ?? UDColor.functionDangerContentDefault
  }

  /// Input Tertiary Icon Color Color, Default Color: UDColor.neutralColor7
  public static var inputTertiaryIconColor: UIColor {
      return UDColor.getValueByKey(.inputTertiaryIconColor) ?? UDColor.neutralColor7
  }

  /// Input Secondary Icon Color Color, Default Color: UDColor.neutralColor8
  public static var inputSecondaryIconColor: UIColor {
      return UDColor.getValueByKey(.inputSecondaryIconColor) ?? UDColor.neutralColor8
  }

  /// Input Railing Icon Pressed Color Color, Default Color: UDColor.neutralColor12.withAlphaComponent(0.1)
  public static var inputRailingIconPressedColor: UIColor {
      return UDColor
        .getValueByKey(.inputRailingIconPressedColor) ?? UDColor.neutralColor12.withAlphaComponent(0.1)
  }

  /// Input Property Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputPropertyTextColor: UIColor {
      return UDColor.getValueByKey(.inputPropertyTextColor) ?? UDColor.neutralColor12
  }

  /// Input Property Text Disable Color Color, Default Color: UDColor.neutralColor6
  public static var inputPropertyTextDisableColor: UIColor {
      return UDColor.getValueByKey(.inputPropertyTextDisableColor) ?? UDColor.neutralColor6
  }

  /// Input Property Pressedproperty Color Color, Default Color: UDColor.primaryColor6
  public static var inputPropertyPressedpropertyColor: UIColor {
      return UDColor.getValueByKey(.inputPropertyPressedpropertyColor) ?? UDColor.primaryContentDefault
  }

  /// Input Tagbg Color Color, Default Color: UDColor.neutralColor12.withAlphaComponent(0.1)
  public static var inputTagbgColor: UIColor {
      return UDColor.getValueByKey(.inputTagbgColor) ?? UDColor.neutralColor12.withAlphaComponent(0.1)
  }

  /// Input Tagtext Color Color, Default Color: UDColor.neutralColor10
  public static var inputTagtextColor: UIColor {
      return UDColor.getValueByKey(.inputTagtextColor) ?? UDColor.neutralColor10
  }

  /// Input Charactercounter Normal Color Color, Default Color: UDColor.neutralColor7
  public static var inputCharactercounterNormalColor: UIColor {
      return UDColor.getValueByKey(.inputCharactercounterNormalColor) ?? UDColor.neutralColor7
  }

  /// Input Password Text Color Color, Default Color: UDColor.neutralColor12
  public static var inputPasswordTextColor: UIColor {
      return UDColor.getValueByKey(.inputPasswordTextColor) ?? UDColor.neutralColor12
  }

  /// Input Icon Disable Color Color, Default Color: UDColor.neutralColor6
  public static var inputIconDisableColor: UIColor {
      return UDColor.getValueByKey(.inputIconDisableColor) ?? UDColor.neutralColor6
  }

  /// Input Charactercounter Disable Color Color, Default Color: UDColor.neutralColor6
  public static var inputCharactercounterDisableColor: UIColor {
      return UDColor.getValueByKey(.inputCharactercounterDisableColor) ?? UDColor.neutralColor6
  }
}
