//
//  ShareGroupCardForwardComponentViewController.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/23.
//

import UIKit
import Foundation
import LarkSegmentedView
import SnapKit
import LarkUIKit
import LarkMessengerInterface
import LarkSearchCore
import LarkSetting
import LarkContainer

final class ShareGroupCardForwardComponentViewController: ForwardComponentViewController, JXSegmentedListContainerViewListDelegate {
    var listWillAppearHandler: () -> Void
    public init(forwardConfig: ForwardConfig,
                listWillAppearHandler: @escaping () -> Void) {
        self.listWillAppearHandler = listWillAppearHandler
        super.init(forwardConfig: forwardConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody
    }

    func updateNavigationItem() {
        let currentNavigationItem = inputNavigationItem ?? self.navigationItem
        if isMultiSelectMode {
            currentNavigationItem.leftBarButtonItem = self.cancelItem
            currentNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
        } else {
            self.addCancelItem()
            currentNavigationItem.rightBarButtonItem = self.multiSelectItem
        }
    }

    // MARK: JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }

    func listWillAppear() {
        updateNavigationItem()
        self.listWillAppearHandler()
    }

    func listWillDisappear() {
        let currentNavigationItem = inputNavigationItem ?? self.navigationItem
        currentNavigationItem.rightBarButtonItem = nil
        currentNavigationItem.leftBarButtonItem = self.addCancelItem()
        /// 取消选中时失去第一响应，transitionCoordinator 有值是代表是 container 生命周期触发 disappear，不作响应
        if self.transitionCoordinator == nil {
            self.view.endEditing(true)
        }
    }
}
