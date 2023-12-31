//
//  SKButtonBar+Layout.swift
//  SKNavigationBar
//
//  Created by 边俊林 on 2019/12/4.
//

import UniverseDesignFont

extension SKButtonBar {

    /**
       The object to control button bar layout parameters.

       If not necessary, you should place your layout attributes in here, and
       if your proprty is very high-level, you should place in `SKButtonBar`.
       Please make sure there's no duplicated properties in both `SKButtonBar` and `LayoutAttributes`

       @seealso: `SKButtonBar`
    */
    public struct LayoutAttributes {

        public var titleFont: UIFont
        
        public var imageWithTitleFont: UIFont

        /**
        The height restriction of button, it will change the touchable area of button.

        If value sets to nil, the button height will be equal to that of the button bar.
        To expand the hitTest area, try to use `hitTestEdgeInsets`.
        */
        public var itemHeight: CGFloat?

        /**
         The overall foreground color mapping for all buttons.

         This configuration is shadowed by that of an individual `SKBarButtonItem`,
         meaning the per-button color mapping take effect. Remember to set this
         to `nil` if you want to honor individual settings.
         */
        public var itemForegroundColorMapping: [UIControl.State: UIColor] = SKBarButton.defaultIconColorMapping

        public var buttonHitTestInsets: UIEdgeInsets?
        
        /// 图标期望大小
        public var iconHeight: CGFloat?
        
        /// 圆形圆角半径
        public var cornerRadius: CGFloat?

        static var `default`: LayoutAttributes {
            return LayoutAttributes(titleFont: UIFont.systemFont(ofSize: 16),
                                    imageWithTitleFont: UDFont.title3,
                                    itemHeight: nil,
                                    buttonHitTestInsets: nil)
        }

        static var restricted: LayoutAttributes {
            return LayoutAttributes(titleFont: UIFont.systemFont(ofSize: 16),
                                    imageWithTitleFont: UDFont.title3,
                                    itemHeight: 24,
                                    buttonHitTestInsets: UIEdgeInsets(top: -6, left: -10, bottom: -6, right: -10))
        }
    }

}
