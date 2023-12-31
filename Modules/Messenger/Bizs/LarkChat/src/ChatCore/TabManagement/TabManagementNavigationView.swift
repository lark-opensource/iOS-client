//
//  TabManagementNavigationView.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/8/2.
//

import UIKit
import Foundation
import SnapKit
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignToast
import RxSwift
import RxCocoa

enum ChatTabManagementStatus {
    // 初始态
    case normal
    // 排序态
    case sorting
}

final class TabManagementNavigationView: UIView {

    typealias SortOrFinishBlock = (_ managementStatus: ChatTabManagementStatus) -> Void

    typealias CloseViewBlock = () -> Void

    /**编辑状态block*/
    var sortOrFinishBlock: SortOrFinishBlock?
    /**关闭按钮block*/
    var closeViewBlock: CloseViewBlock?
    /**当前按钮状态*/
    private var managementStatus: ChatTabManagementStatus
    /**导航标题*/
    private var navTitleLabel: UILabel = UILabel()
    /**关闭按钮*/
    private let closeButton: UIButton = UIButton()
    /**编辑*/
    private let editButton: UIButton = UIButton()
    /**底部View*/
    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return lineView
    }()
    private weak var targetVC: UIViewController?
    private let disposeBag = DisposeBag()
    private let canManageTab: BehaviorRelay<(Bool, String?)>

    init(targetVC: UIViewController, canManageTab: BehaviorRelay<(Bool, String?)>) {
        self.managementStatus = .normal
        self.targetVC = targetVC
        self.canManageTab = canManageTab
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloatBase
        self.createTabManagementHeaderUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createTabManagementHeaderUI() {
        //导航标题
        self.addSubview(self.navTitleLabel)
        self.navTitleLabel.text = BundleI18n.LarkChat.Lark_IM_Tabs_Title_Mobile
        self.navTitleLabel.textAlignment = .center
        self.navTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        self.navTitleLabel.textColor = UIColor.ud.textTitle
        self.navTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.height.equalTo(24)
        }

        //关闭
        self.addSubview(self.closeButton)
        self.closeButton.setImage(Resources.tab_close_small_outlined, for: .normal)
        self.closeButton.addTarget(self, action: #selector(closeEvent), for: .touchUpInside)
        self.closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.centerY.equalTo(self.navTitleLabel)
        }

        //排序/保存
        self.addSubview(self.editButton)
        self.editButton.setTitle(BundleI18n.LarkChat.Lark_IM_Tabs_SortOrder_Button_Mobile, for: .normal)
        self.editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        self.editButton.addTarget(self, action: #selector(editEvent), for: .touchUpInside)
        self.editButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalTo(self.navTitleLabel)
        }
        self.canManageTab
            .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] canManage in
                self?.editButton.setTitleColor(canManage.0 ? UIColor.ud.textLinkNormal : UIColor.ud.textDisabled, for: .normal)
            }).disposed(by: disposeBag)

        self.addSubview(self.lineView)
        self.lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc
    func closeEvent() {
        if self.managementStatus == .sorting {
            self.managementStatus = .normal
            self.editButton.setTitle(BundleI18n.LarkChat.Lark_IM_Tabs_SortOrder_Button_Mobile, for: .normal)
        }
        self.closeViewBlock?()
    }

    /**导航右侧按钮Event*/
    @objc
    func editEvent() {
        guard let targetVC = self.targetVC else { return }
        if !self.canManageTab.value.0 {
            UDToast.showTips(with: self.canManageTab.value.1 ?? "", on: targetVC.view)
            return
        }
        switch self.managementStatus {
        case .normal:
            self.managementStatus = .sorting
            self.editButton.setTitle(BundleI18n.LarkChat.Lark_Legacy_Save, for: .normal)
        case .sorting:
            self.managementStatus = .normal
            self.editButton.setTitle(BundleI18n.LarkChat.Lark_IM_Tabs_SortOrder_Button_Mobile, for: .normal)
        }
        self.sortOrFinishBlock?(self.managementStatus)
    }
}
