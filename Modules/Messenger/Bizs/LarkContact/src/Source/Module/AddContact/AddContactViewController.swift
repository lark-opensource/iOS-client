//
//  AddContactViewController.swift
//  LarkContact
//
//  Created by ChalrieSu on 2018/9/12.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkFeatureSwitch
import LarkFeatureGating
import LarkFoundation

protocol AddContactViewControllerRouter {
    /// 扫描二维码
    func pushScanQRCodeViewController(vc: AddContactViewController)
    /// 邀请好友
    func pushInviteContactsViewController(vc: AddContactViewController, didClickInviteOtherWith content: String)
    /// 我的二维码
    func pushMyQRCodeViewController(vc: AddContactViewController)
    /// 跳转个人卡片页面，带UserProfile
    func pushPersonalCardVC(_ vc: AddContactViewController, userProfile: UserProfile)
}

final class AddContactViewController: BaseUIViewController {

    private let router: AddContactViewControllerRouter
    private let applicationAPI: ChatApplicationAPI
    private let enableInviteFriends: Bool

    private let textField = SearchUITextField()
    private let scanButton = UIButton()
    private let seperator = UIView()
    private let QRCodeButton = UIButton()

    private let disposeBag = DisposeBag()

    init(router: AddContactViewControllerRouter,
         chatApplicationAPI: ChatApplicationAPI,
         enableInviteFriends: Bool) {
        self.router = router
        self.applicationAPI = chatApplicationAPI
        self.enableInviteFriends = enableInviteFriends
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.LarkContact.Lark_Legacy_AddContact
        isNavigationBarHidden = true
        view.backgroundColor = .white
        addCloseItem()

        let naviBar = UIView()

        let closeButton = UIButton()
        closeButton.setImage(Resources.navigation_close_light, for: .normal)
        naviBar.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        closeButton.rx.tap.subscribe(onNext: { [weak self] () in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)

        let titleLabel = UILabel()
        naviBar.addSubview(titleLabel)
        titleLabel.text = BundleI18n.LarkContact.Lark_Legacy_AddContact
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.top.equalTo(viewTopConstraint)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        textField.placeholder = BundleI18n.LarkContact.Lark_Legacy_PhoneOrEmail
        textField.canEdit = false
        textField.tapBlock = { [weak self] (_) in
            self?.searchBarDidClick()
        }
        view.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(naviBar.snp.bottom).offset(17.5)
            make.height.equalTo(36)
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        view.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom).offset(13)
            make.left.right.equalToSuperview()
        }

        scanButton.setImage(Resources.invite_scan, for: .normal)
        scanButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_InviteScanContactsQrCode, for: .normal)
        scanButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        scanButton.setTitleColor(UIColor.ud.N900, for: .normal)
        scanButton.contentHorizontalAlignment = .left
        scanButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        scanButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16 + 12, bottom: 0, right: 0)
        scanButton.addTarget(self, action: #selector(scanButtonDidClick), for: .touchUpInside)
        scanButton.adjustsImageWhenHighlighted = false

        let scanEnable: Bool = !Utils.isiOSAppOnMacSystem
        if scanEnable {
            stackView.addArrangedSubview(self.scanButton)
            self.scanButton.snp.makeConstraints { (make) in
                make.height.equalTo(55)
            }
        }

        /// 邀请朋友需要响应FG Key配置
        if enableInviteFriends {
            scanButton.lu.addBottomBorder(leading: 48)

            let inviteButton = UIButton()
            inviteButton.setImage(Resources.invite_partners, for: .normal)
            inviteButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_InviteContacts, for: .normal)
            inviteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            inviteButton.setTitleColor(UIColor.ud.N900, for: .normal)
            inviteButton.contentHorizontalAlignment = .left
            inviteButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            inviteButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16 + 12, bottom: 0, right: 0)
            inviteButton.addTarget(self, action: #selector(inviteButtonDidClick), for: .touchUpInside)
            inviteButton.adjustsImageWhenHighlighted = false
            stackView.addArrangedSubview(inviteButton)
            inviteButton.snp.makeConstraints { (make) in
                make.height.equalTo(55)
            }
        }

        seperator.backgroundColor = UIColor.ud.N100
        view.addSubview(seperator)
        seperator.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom)
            make.height.equalTo(8)
        }
        QRCodeButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_InviteMyQrCode, for: .normal)
        QRCodeButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        QRCodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        QRCodeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        QRCodeButton.addTarget(self, action: #selector(myQRCodeButtonDidClick), for: .touchUpInside)
        view.addSubview(QRCodeButton)
        QRCodeButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(seperator.snp.bottom)
        }
    }

    private func searchBarDidClick() {
        let searchVC = AddContactSearchViewController(chatApplicationAPI: applicationAPI, enableInviteFriends: self.enableInviteFriends)
        searchVC.delegate = self
        navigationController?.delegate = self
        navigationController?.pushViewController(searchVC, animated: true)
    }

    @objc
    private func scanButtonDidClick() {
        Tracer.trackScan(source: "add_contacts")
        router.pushScanQRCodeViewController(vc: self)
    }

    @objc
    private func inviteButtonDidClick() {
        Tracer.trackInviteEntrance()
        router.pushInviteContactsViewController(vc: self, didClickInviteOtherWith: "")
    }

    @objc
    private func myQRCodeButtonDidClick() {
        router.pushMyQRCodeViewController(vc: self)
    }
}

extension AddContactViewController: AddContactSearchViewControllerDelegate {
    func searchViewController(_ vc: AddContactSearchViewController, didClickInviteOtherWith content: String) {
        /// 点击了邀请某人使用飞书
        router.pushInviteContactsViewController(vc: self, didClickInviteOtherWith: content)
    }

    func searchViewController(_ vc: AddContactSearchViewController, didSelect userProfile: UserProfile) {
        /// 搜索结果中点击了某人
        router.pushPersonalCardVC(self, userProfile: userProfile)
    }
}
