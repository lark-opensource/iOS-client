//
//  NavigationBarFullScreenItemSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/8.
//

import Foundation
import UIKit
import LarkOpenChat
import LarkSplitViewController
import LarkUIKit

class NavigationBarFullScreenItemSubModule: BaseNavigationBarItemSubModule {
    private var metaModel: ChatNavigationBarMetaModel?
    lazy var itemsTintColor: UIColor = {
        if self.metaModel?.chat.chatMode != .threadV2 {
            return UIColor.ud.N900
        } else {
            return Display.pad ? UIColor.ud.N900 : UIColor.ud.N00.alwaysLight
        }
    }()

    var _items: [ChatNavigationExtendItem] = []

    override var items: [ChatNavigationExtendItem] {
        return _items
    }

    private lazy var fullScreenButton: UIButton = {
        let fullScreenButton = UIButton()
        fullScreenButton.addPointerStyle()
        fullScreenButton.addTarget(self, action: #selector(fullScreenButtonClicked(sender:)), for: .touchUpInside)
        fullScreenButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        self.updateFullButtonIcon(button: fullScreenButton)
        return fullScreenButton
    }()

    private var needShowFullScreen: Bool = false {
        didSet {
            if oldValue != needShowFullScreen {
                self.context.refreshLeftItems()
            }
        }
    }
    private var fullScreenIsOn: Bool = false {
        didSet {
            if oldValue != fullScreenIsOn {
                self.updateFullButtonIcon(button: self.fullScreenButton)
            }
        }
    }

    override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self._items = []
        if self.needShowFullScreen {
            self._items.append(ChatNavigationExtendItem(type: .fullScreen, view: fullScreenButton))
        }
    }

    override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.metaModel = model
    }

    override func viewWillAppear() {
        self.updateFullScreenItem()
    }

    override func viewWillRealRenderSubView() {
        self.updateFullScreenItem()
    }
    override func splitSplitModeChange() {
        self.updateFullScreenItem()
    }
    override func splitDisplayModeChange() {
        self.updateFullScreenItem()
    }
    @objc
    private func fullScreenButtonClicked(sender: UIButton) {
        if self.fullScreenIsOn {
            NavigationBarSubModuleTool.leaveFullScreenItemFor(vc: self.context.chatVC())
        } else {
            NavigationBarSubModuleTool.enterFullScreenFor(vc: self.context.chatVC())
        }
    }

    fileprivate func updateFullScreenItem() {
        NavigationBarSubModuleTool.updateFullScreenItemFor(vc: self.context.chatVC()) { [weak self] (needShowFullScreen, isFullScreenOn) in
            self?.needShowFullScreen = needShowFullScreen
            if let isFullScreenOn = isFullScreenOn {
                self?.fullScreenIsOn = isFullScreenOn
            }
        }
    }

    /// 更新全屏按钮 icon
    private func updateFullButtonIcon(button: UIButton) {
        let icon = self.fullScreenIsOn ?
            LarkSplitViewController.Resources.leaveFullScreen :
            LarkSplitViewController.Resources.enterFullScreen
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: icon,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(
            image,
            for: .normal
        )
    }

}
