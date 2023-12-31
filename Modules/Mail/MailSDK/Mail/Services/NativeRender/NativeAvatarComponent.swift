//
//  NativeAvatarComponent.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/5.
//

import Foundation
import LarkWebviewNativeComponent
import SnapKit
import EENavigator
import RxSwift
import RustPB
import UIKit

private struct InsertParamsObject {
    let avatarKey: String
    let entityId: String
    let name: String
    let address: String
    let userType: Int
    let tenantId: String

    static func createWithParams(params: [String: Any]) -> InsertParamsObject {
        let avatarKey = params["avatarkey"] as? String ?? ""
        let entityId = params["entityid"] as? String ?? ""
        let name = params["name"] as? String ?? ""
        let address = params["address"] as? String ?? ""
        let userType = params["userType"] as? String ?? ""
        let tenantId = params["tenantId"] as? String ?? ""

        return InsertParamsObject(avatarKey: avatarKey,
                                  entityId: entityId,
                                  name: name,
                                  address: address,
                                  userType: Int(userType) ?? 1,
                                  tenantId: tenantId)
    }
}

protocol NativeAvatarComponentDelegate: AnyObject {
    var currentTenantID: String { get }
    var profileRouter: ProfileRouter? { get }
    func showAddressSheet(address: String, sourceView: UIView)
    func didSaveMailContact()
}

class NativeAvatarComponent: UIView {
    var disposeBag = DisposeBag()
    var setImageTask: SetImageTask?

    private var insertParamsObject: InsertParamsObject?
    private var inSerted: Bool = false

    private let avatarImageView = MailAvatarImageView()

    weak var delegate: NativeAvatarComponentDelegate?

    required init() {
        super.init(frame: CGRect.zero)
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
        addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                          action: #selector(handleLongPress(reco:))))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.height / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NativeAvatarComponent: NativeComponentAble {

    var nativeView: UIView {
        return self
    }

    static var tagName: String {
        return "lk-native-avatar"
    }

    func willInsertComponent(params: [String: Any]) {
        /// 同层, WebView已经设置底色
        avatarImageView.dafaultBackgroundColor = UIColor.clear
        let object = InsertParamsObject.createWithParams(params: params)
        insertParamsObject = object
        print("-------------------- did Insert\(object)")
        let entityType = Email_Client_V1_Address.LarkEntityType(rawValue: object.userType) ?? .user
        // 邮件组不展示个人头像，不传LarkID
        let userid = entityType.isGroupOrEnterpriseMailGroup ? "" : object.entityId
        let avatarKey = entityType.isGroupOrEnterpriseMailGroup ? "" : object.avatarKey
        avatarImageView.loadAvatar(name: object.name,
                                   avatarKey: avatarKey,
                                   entityId: userid,
                                   setBackground: false) { img, error in
            if let error = error {
                MailLogger.debug("NativeAvatarComponent load avatar Fail: \(error)")
            }
        }
        inSerted = true
    }

    func didInsertComponent(params: [String: Any]) { }

    func updateCompoent(params: [String: Any]) {
        print("-------------------- did updateCompoent\(params)")
    }

    /// 即将移除
    func willBeRemovedComponent(params: [String: Any]) {
        print("-------------------- did willRemoveComponent\(params)")
    }
}

extension NativeAvatarComponent {
    @objc
    func handleClick() {
        guard let object = insertParamsObject else {
            mailAssertionFailure("no params")
            return
        }
        if let fromVC = delegate?.profileRouter?.navigator.mainSceneWindow?.fromViewController {
            /// 无法复用写信页弹出地址的逻辑，改动过多，三方暂时屏蔽同层渲染，三方不会走这里。
            let entityType = Email_Client_V1_Address.LarkEntityType(rawValue: object.userType) ?? .user
            MailContactLogic.default.checkContactDetailAction(userId: object.entityId,
                                                              tenantId: object.tenantId,
                                                              currentTenantID: delegate?.currentTenantID ?? "",
                                                              userType: entityType) { [weak self] result in
                guard let self = self else { return }
                if result == MailContactLogic.ContactDetailActionType.actionSheet {
                    self.delegate?.showAddressSheet(address: object.address, sourceView: self)
                } else if result == MailContactLogic.ContactDetailActionType.profile {
                    // internal user, show Profile
                    self.delegate?.profileRouter?.openUserProfile(userId: object.entityId, fromVC: fromVC)
                } else if result == MailContactLogic.ContactDetailActionType.nameCard {
                    let accountId = Store.settingData.currentAccount.value?.mailAccountID ?? ""
                    self.delegate?.profileRouter?.openNameCard(accountId: accountId,
                                                               address: object.address,
                                                               name: object.name,
                                                               fromVC: fromVC, callBack: { [weak self] success in
                        if success {
                            self?.delegate?.didSaveMailContact()
                        }
                    })
                }
            }
        } else {
            MailLogger.error("handleClick can't find top vc")
        }
    }

    @objc
    func handleLongPress(reco: UILongPressGestureRecognizer) {
        switch reco.state {
        case .began:
            self.alpha = CGFloat(0.7)
        case .changed:
            self.alpha = CGFloat(0.7)
        case .ended:
            self.alpha = CGFloat(1)
        default:
            break
        }
    }
}
