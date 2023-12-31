//
//  ChatChooseViewController.swift
//  LarkForward
//
//  Created by shizhengyu on 2021/1/5.
//

import UIKit
import Foundation
import LarkSegmentedView
import SnapKit
import LarkUIKit
import LarkMessengerInterface
import LarkSnsShare

final class ChatChooseViewController: ForwardViewController, ChooseChatViewControllerAbility, JXSegmentedListContainerViewListDelegate {

    var closeHandler: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        searchWrapper?.snp.updateConstraints({ make in
            make.top.equalToSuperview().inset(6)
        })
        view.backgroundColor = UIColor.ud.bgBase
    }

    // MARK: JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }

    func listWillDisappear() {
        let currentNavigationItem = inputNavigationItem ?? navigationItem
        currentNavigationItem.rightBarButtonItem = nil
        currentNavigationItem.leftBarButtonItem = leftBarButtonItem
        // 取消选中时失去第一响应，transitionCoordinator 有值是代表是 container 生命周期触发 disappear，不作响应
        if transitionCoordinator == nil {
            view.endEditing(true)
        }
    }

    @objc
    public override func closeBtnTapped() {
        closeHandler?()
        super.closeBtnTapped()
    }

    @objc
    public override func backItemTapped() {
        closeHandler?()
        super.backItemTapped()
    }
}
