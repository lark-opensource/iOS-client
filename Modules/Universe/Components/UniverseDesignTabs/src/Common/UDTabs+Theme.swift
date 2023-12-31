//
//  UDTabsColorTheme.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/11.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDTabs Color Theme
public struct UDTabsColorTheme {

  /// Tabs Fixed Title Normal Color Color, Default Color: UDColor.neutralColor8
  public static var tabsFixedTitleNormalColor: UIColor {
      return UDColor.textCaption
  }

  /// Tabs Fixed Title Pressed Color Color, Default Color: UDColor.primaryColor6
  public static var tabsFixedTitlePressedColor: UIColor {
      return UDColor.primaryContentDefault
  }

  /// Tabs Fixed Title Selected Color Color, Default Color: UDColor.primaryColor6
  public static var tabsFixedTitleSelectedColor: UIColor {
      return UDColor.primaryContentDefault
  }

  /// Tabs Fixed Bg Color Color, Default Color: UDColor.neutralColor1
  public static var tabsFixedBgColor: UIColor {
      return UDColor.bgBody
  }

  /// Tabs Fixed Indicator Active Color Color, Default Color: UDColor.primaryColor6
  public static var tabsFixedIndicatorActiveColor: UIColor {
      return UDColor.primaryContentDefault
  }

  /// Tabs Scrollable Disappear Color Color, Default Color: UDColor.neutralColor1
  public static var tabsScrollableDisappearColor: UIColor {
      return UDColor.bgBody
  }
}
