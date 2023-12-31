//
//  TeamTopStructureSelectViewController.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/7/19.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSDKInterface
import LarkSearchCore
import LarkMessengerInterface
import UniverseDesignColor
import LarkAccountInterface

final class TeamTopStructureSelectViewController: TopStructureSelectViewController {
    /// 水槽标题
    var headerTitle: String?
    var customLeftBarButtonItem: Bool = false
    var hideRightNaviBarItem: Bool = false

    /// 搜索群鉴权
    var checkSearchChatDeniedReasonForDisabledPick: ((ChatterPickeSelectChatType) -> Bool)?
    var checkSearchChatDeniedReasonForWillSelected: ((ChatterPickeSelectChatType, UIViewController) -> Bool)?
    /// 搜索人鉴权
    var checkSearchChatterDeniedReasonForDisabledPick: ((Bool) -> Bool)?
    var checkSearchChatterDeniedReasonForWillSelected: ((Bool, UIViewController) -> Bool)?

    private var waterChannelHeaderView: UIView?
    private let headerHeight: CGFloat = 30
    private var currentTenantID: String {
        return passportUserService.userTenant.tenantID
    }

    private lazy var jumpItem: LKBarButtonItem = {
        let jumpItem = LKBarButtonItem(title: BundleI18n.LarkTeam.Project_MV_SkipButton)
        jumpItem.button.addTarget(self, action: #selector(jumpDidClick), for: .touchUpInside)
        jumpItem.button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        jumpItem.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        return jumpItem
    }()

    override func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        if let checkSearchChatDeniedReasonForDisabledPick = self.checkSearchChatDeniedReasonForDisabledPick,
           let selectChatType = option.asPickerSelectChatType(),
           checkSearchChatDeniedReasonForDisabledPick(selectChatType) {
            return true
        }

        if let checkSearchChatterDeniedReasonForDisabledPick = self.checkSearchChatterDeniedReasonForDisabledPick,
           let chatterPickerSelectedInfo = option.asChatterPickerSelectedInfo(),
           checkSearchChatterDeniedReasonForDisabledPick(chatterPickerSelectedInfo.isExternal(currentTenantId: currentTenantID)) {
            return true
        }

        return super.picker(picker, disabled: option, from: from)
    }

    override func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        if let checkSearchChatDeniedReasonForWillSelected = self.checkSearchChatDeniedReasonForWillSelected,
           let selectChatType = option.asPickerSelectChatType(),
           !checkSearchChatDeniedReasonForWillSelected(selectChatType, self) {
            return false
        }

        if let checkSearchChatterDeniedReasonForWillSelected = self.checkSearchChatterDeniedReasonForWillSelected,
           let chatterPickerSelectedInfo = option.asChatterPickerSelectedInfo(),
           !checkSearchChatterDeniedReasonForWillSelected(chatterPickerSelectedInfo.isExternal(currentTenantId: currentTenantID), self) {
            return false
        }

        return super.picker(picker, willSelected: option, from: from)
    }

    override func updateSureButtonTitle(items: [Option]) {
        self.sureButton.setTitle(BundleI18n.LarkTeam.Project_MV_ButtonsAddHere, for: .normal)
        self.sureButton.sizeToFit()
        self.sureButton.isEnabled = !items.isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupWaterChannelView()
    }

    override func configNaviBar() {
        super.configNaviBar()
        if customLeftBarButtonItem {
            customNavigationItem.leftBarButtonItem = jumpItem
        }
        if hideRightNaviBarItem {
            customNavigationItem.rightBarButtonItem = nil
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if size.width != self.view.bounds.width {
            self.waterChannelHeaderView?.frame = CGRect(origin: .zero,
                                                        size: CGSize(width: size.width, height: headerHeight))
        }
    }

    private func setupWaterChannelView() {
        guard let headerTitle = self.headerTitle else { return }
        let waterChannelHeaderView = WaterView(title: headerTitle)
        waterChannelHeaderView.frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: headerHeight))
        if let structureView = picker.defaultView as? StructureView {
            structureView.customTableViewHeader(customView: waterChannelHeaderView)
        }
        self.waterChannelHeaderView = waterChannelHeaderView
    }

    @objc
    func jumpDidClick() {
        self.closeBtnTapped()
    }
}

final class WaterView: UIView {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        return titleLabel
    }()

    init(title: String) {
        super.init(frame: .zero)
        self.titleLabel.text = title
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
