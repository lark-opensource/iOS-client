//
//  BTContainer+Constaints.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/16.
//

import Foundation
import UniverseDesignColor

extension BTContainer {
    
    class Constaints {
        
        static let animationDuration: TimeInterval = 0.25
        
        /// ViewCatalogue 顶部颜色
        static let viewCatalogueTopColor = UDColor.bgBody.withAlphaComponent(0.35)
        /// ViewCatalogue 底部颜色（也是 ToolBar 顶部颜色）
        static let viewCatalogueBottomColor = UIColor.dynamic(light: UIColor.ud.rgb(0xF7F9FA), dark: UIColor.ud.rgb(0x202123))
        /// ToolBar 顶部颜色
        static let toolBarTopColor = viewCatalogueBottomColor
        /// ToolBar 底部颜色（也是WebView区顶部颜色）
        static let toolBarBottomColor = UDColor.bgBody
        static let onboardingTipsBackground = UDColor.rgb(0x1F2329).withAlphaComponent(0.8)
        
        /// 导航栏按钮背景色
        static let navBarButtonBackgroundColor = UDColor.N900.withAlphaComponent(0.05)
        static let navBarBackgroundColor: UIColor = .clear
        
        static let navBarIconHeight: CGFloat = 18.0
        static let navBarButtonBackgroundSize = CGSize(width: 32.0, height: 32.0)
        static let navBarButtonBackgroundCornerRadius = navBarButtonBackgroundSize.height / 2
        
        static let viewCatalogueContainerHeight: CGFloat = 60
        static let viewContainerCornerRadius: CGFloat = 24
        
        /// 视图容器收起后右侧剩余的最小宽度
        static let viewContainerRemainWidth: CGFloat = 43.0
        static let blockCatalogueMaxWidth: CGFloat = 340.0
        static let regularModeMinWidth: CGFloat = 500.0
        
        static let toolBarHeight: CGFloat = 28.0
        
        static let gestureSpeed: CGFloat = 10
    }
    
}
