//
//  ContactDefaultPickerToolBar.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/6/1.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

open class PickerToolBar: UIToolbar {
    public var contentDidUpdateBlock: ((PickerToolBar) -> Void)?

    public var allowSelectNone: Bool = false
    public weak var navigationController: UIViewController?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.barStyle = .default
        self.isTranslucent = false
        let backgroundImage = UIImage.lu.fromColor(UIColor.ud.bgBody)
        let shadowImage = UIImage.lu.fromColor(UIColor.ud.lineDividerDefault)
            .kf.resize(to: CGSize(width: UIScreen.main.bounds.width, height: (1.0 / UIScreen.main.scale)))
        if #available(iOS 15.0, *) {
            updateBarStyle(backgroundImage: backgroundImage, shadowImage: shadowImage)
        } else {
            self.setBackgroundImage(backgroundImage, forToolbarPosition: .any, barMetrics: .default)
            self.setShadowImage(shadowImage, forToolbarPosition: .top)
        }
    }

    // https://developer.apple.com/forums/thread/683265
    // https://www.jianshu.com/p/8b37428bab92
    @available(iOS 15.0, *)
    func updateBarStyle(backgroundImage: UIImage, shadowImage: UIImage) {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundImage = backgroundImage
        appearance.shadowImage = shadowImage
        self.standardAppearance = appearance
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            self.scrollEdgeAppearance = appearance
        }
        #endif
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Default return empty array.
    open func toolbarItems() -> [UIBarButtonItem] {
        return []
    }

    // Called when the chatter or chat is selected. Default does nothing
    open func updateSelectedItem(firstSelectedItems: [Any],
                                 secondSelectedItems: [Any],
                                 updateResultButton: Bool) {
        DispatchQueue.main.async {
            self.contentDidUpdateBlock?(self)
        }
    }

    /// 传入一个点击位置，响应这个发生在这个位置的点击事件
    ///
    /// - Parameter location: 点击的位置
    public func locationTapped(location: CGPoint) {
        let hitView = self.hitTest(location, with: nil)
        if let button = hitView as? UIControl {
            button.sendActions(for: .touchUpInside)
        }
        contentDidUpdateBlock?(self)
    }
}
