//
//  ShareGroupCardViewController.swift
//  LarkForward
//
//  Created by 姜凯文 on 2020/4/22.
//

import UIKit
import Foundation
import LarkSegmentedView
import SnapKit
import LarkUIKit

final class ShareGroupCardViewController: ForwardViewController, JXSegmentedListContainerViewListDelegate {
    var listWillAppearHandler: () -> Void
    public init(viewModel: ForwardViewModel,
                router: ForwardViewControllerRouter,
                inputNavigationItem: UINavigationItem? = nil,
                listWillAppearHandler: @escaping () -> Void) {
        self.listWillAppearHandler = listWillAppearHandler
        super.init(viewModel: viewModel, router: router, inputNavigationItem: inputNavigationItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        searchWrapper?.snp.updateConstraints({ make in
            make.top.equalToSuperview().inset(6)
        })

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
