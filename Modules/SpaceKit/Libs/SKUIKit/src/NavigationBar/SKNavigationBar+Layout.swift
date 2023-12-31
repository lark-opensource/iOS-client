//
//  SKNavigationBar+Layout.swift
//  SKNavigationBar
//
//  Created by 边俊林 on 2019/11/21.
//

import UIKit
import UniverseDesignColor

extension SKNavigationBar {

    /**
        The object to control navigation bar layout paramsters.

        If not necessary, you should place your layout attributes in here, and
        if your proprty is very high-level, you should place in `SKNavigationBar`.
        Please make sure there's no duplicated properties in both `SKNavigationbar` and `LayoutAttributes`

        @seealso: `SKNavigationBar`
     */
    public struct LayoutAttributes {

        public var titleFont: UIFont

        public var titleTextColor: UIColor

        public var subTitleFont: UIFont

        public var subTitleTextColor: UIColor

        public var showsBottomSeparator: Bool = false

        public var bottomSeparatorColor: UIColor = UDColor.lineDividerDefault
        
        public var titleHorizontalOffsetWhenLeft1Button: CGFloat = 8

        public var titleHorizontalOffset: CGFloat = 20 // also applies to temporaryTrailingButtonBar

        public var interButtonSpacing: CGFloat

        /// For leading button bar's leading margin and trailing button bar's trailing margin.
        /// Button bars have no internal leading and trailing paddings.
        public var barHorizontalInset: CGFloat

        public var titleHorizontalAlignment: UIControl.ContentHorizontalAlignment

        public var titleVerticalAlignment: UIControl.ContentVerticalAlignment

        public var buttonHitTestInset: UIEdgeInsets?

        /** CAUTION: Defensive parameter. */

        public var minimumHeight: CGFloat = 24

        public var defaultHeight: CGFloat = 44

        public var maximumHeight: CGFloat = 56

        public var maximumFontSize: CGFloat = 24
        
        public var textFieldSidePadding: CGFloat = 4
        
        public var textFieldVerticalPadding: CGFloat = 6
        
        public var editorHorizontalPadding: CGFloat = 24    //编辑标题栏跟最右边/最左边的按钮有24的距离

        public init(titleFont: UIFont, titleTextColor: UIColor, subTitleFont: UIFont, subTitleTextColor: UIColor, interButtonSpacing: CGFloat, barHorizontalInset: CGFloat, titleHorizontalAlignment: UIControl.ContentHorizontalAlignment, titleVerticalAlignment: UIControl.ContentVerticalAlignment) {
            self.titleFont = titleFont
            self.titleTextColor = titleTextColor
            self.subTitleFont = subTitleFont
            self.subTitleTextColor = subTitleTextColor
            self.interButtonSpacing = interButtonSpacing
            self.barHorizontalInset = barHorizontalInset
            self.titleHorizontalAlignment = titleHorizontalAlignment
            self.titleVerticalAlignment = titleVerticalAlignment
        }
        
        static var `default`: LayoutAttributes {
            return LayoutAttributes(titleFont: UIFont.systemFont(ofSize: 17, weight: .medium),
                                    titleTextColor: UDColor.textTitle,
                                    subTitleFont: UIFont.systemFont(ofSize: 12, weight: .regular),
                                    subTitleTextColor: UDColor.textCaption,
                                    interButtonSpacing: 20,
                                    barHorizontalInset: 16,
                                    titleHorizontalAlignment: .center, // 不要动这里！如果需要修改排序，请在业务场景访问 navigationBar.layoutAttributes.titleHorizontalAlignment
                                    titleVerticalAlignment: .center)
        }
    }

}
