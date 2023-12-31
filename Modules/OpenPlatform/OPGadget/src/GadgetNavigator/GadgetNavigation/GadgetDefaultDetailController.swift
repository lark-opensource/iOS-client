//
//  GadgetDefaultDetailController.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/27.
//

import Foundation
import LarkUIKit
import UIKit
import LarkSplitViewController
import UniverseDesignEmpty
import TTMicroApp

/// 用于模态弹出时如果导航栈中的内容为空，显示的占位符
/// 这个占位符带关闭按钮显示导航栏
final class GadgetDefaultDetailController: BaseUIViewController, DefaultDetailVC  {

    /// 恢复闭包的别名
    typealias RecoverAction = (_ blankViewController: UIViewController) -> ()

    override func viewDidLoad() {
        super.viewDidLoad()
        /// 显示关闭按钮
        self.addCloseItem()
        self.isNavigationBarHidden = false
        let title = BDPI18n.openPlatform_Workplace_PageRemoved ?? ""
        let emptyView = UDEmpty(config: UDEmptyConfig(title: nil,
                                                        description: UDEmptyConfig.Description(
                                                            descriptionText: title,
                                                            font: UIFont.systemFont(ofSize: 16)),
                                                        spaceBelowImage: 10,
                                                        spaceBelowTitle: 0,
                                                        spaceBelowDescription: 0,
                                                        spaceBetweenButtons: 0,
                                                        type: .noApplication))
        emptyView.sizeToFit()
        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.center.equalTo(self.view.snp.center)
        }
    }

    override func closeBtnTapped() {
        /// 点击关闭按钮之后将他自己的NC dimiss掉
        self.navigationController?.op_dismissIfNeed(animated: true, complete: {

        }, failure: {
            _ in
        })
    }

    /// 设置空白页面占位符的恢复行为，接受当前空白页面，可利用这个上下文进行恢复
    var recoverAction: RecoverAction? = nil

}
