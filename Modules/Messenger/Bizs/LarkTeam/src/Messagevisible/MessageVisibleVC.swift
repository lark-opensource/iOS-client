//
//  MessageVisibleVC.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2023/2/15.
//

import UIKit
import Foundation
import RustPB
import LarkTab
import RxSwift
import LarkCore
import RxCocoa
import LarkUIKit
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface

final class MessageVisibleVC: BaseUIViewController {

    let topView = MessageVisibleView()
    let bottomView = MessageVisibleView()

    var selectedCallback: ((Bool) -> Void)?
    var messageVisibilityCallback: ((@escaping () -> Void) -> Void)?

    // 消息设置：是否不可选择
    private let isMessageEnabled: Bool
    private let messageVisibility: Bool

    // 消息设置：true为公开，false为私密
    private var isMessageVisible: Bool
    private let errorTips: String?
    private let disposeBag = DisposeBag()

    init(isMessageVisible: Bool,
         isMessageEnabled: Bool,
         messageVisibility: Bool,
         errorTips: String?) {
        self.isMessageVisible = isMessageVisible
        self.isMessageEnabled = isMessageEnabled
        self.messageVisibility = messageVisibility
        self.errorTips = errorTips
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        self.title = BundleI18n.LarkTeam.Project_T_PrivacySettingsInTeam_Title
        self.view.backgroundColor = UIColor.ud.bgBase

        let contentView = UIView()
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        let topLineView = UIView()
        contentView.addSubview(topLineView)
        let lineHeight = 1 / UIScreen.main.scale
        topLineView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(lineHeight)
        }
        topLineView.backgroundColor = UIColor.ud.lineDividerDefault

        let bottomLineView = UIView()
        contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(lineHeight)
        }
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault

        contentView.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(lineHeight)
        }

        contentView.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(topView)
            make.top.equalTo(topView.snp.bottom)
            make.bottom.equalToSuperview().offset(-lineHeight)
        }
        topView.setTitle(BundleI18n.LarkTeam.Project_T_GroupPrivacy_Public_Title)
        topView.setDesc(BundleI18n.LarkTeam.Project_T_GroupPrivacy_Public_Desc)
        bottomView.setTitle(BundleI18n.LarkTeam.Project_T_GroupPrivacy_Private_Title)
        bottomView.setDesc(BundleI18n.LarkTeam.Project_T_GroupPrivacy_Private_Desc)
        setData()
        topView.selectedCallback = { [weak self] in
            guard let self = self else { return }
            if self.isMessageEnabled {
                if self.messageVisibility {
                    self.isMessageVisible = true
                    self.setData()
                    self.tapped()
                } else {
                    self.messageVisibilityCallback? { [weak self] in
                        self?.popSelf()
                    }
                }
            } else {
                if let errorTips = self.errorTips {
                    UDToast.showFailure(with: errorTips, on: self.view)
                }
            }
        }
        bottomView.selectedCallback = { [weak self] in
            guard let self = self else { return }
            self.isMessageVisible = false
            self.setData()
            self.tapped()
        }
    }

    private func setData() {
        topView.setUnavailableState(isMessageEnabled)
        topView.setSelectedState(isMessageVisible)
        bottomView.setSelectedState(!isMessageVisible)
    }

    private func tapped() {
        selectedCallback?(self.isMessageVisible)
        self.popSelf()
    }
}
