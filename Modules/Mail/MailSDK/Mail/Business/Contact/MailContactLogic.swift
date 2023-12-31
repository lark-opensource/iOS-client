//
//  MailContactLogic.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/6/9.
//

import Foundation
import RustPB
import LKCommonsLogging
import RxSwift

class MailContactLogic {
    static let `default` = MailContactLogic()

    let logger = Logger.log(MailContactLogic.self, category: "Module.MailContactLogic")

    var disposeBag = DisposeBag()

    // type result
    enum ContactDetailActionType {
        case profile
        case nameCard
        case actionSheet
    }
}

// open profile / namecard / sheet
// pb helper
protocol MailContactTypeDetailCheckable {
    func isJumpDetailAble() -> Bool
}

extension MailContactLogic {
    func checkContactDetailAction(userId: String?,
                                  tenantId: String?,
                                  currentTenantID: String,
                                  userType: MailContactTypeDetailCheckable,
                                  result: @escaping (ContactDetailActionType) -> Void) {
        var showSheet = false
        if !userType.isJumpDetailAble() {
            showSheet = true
        }
        if showSheet {
            result(.actionSheet)
        } else if let user = userId, !user.isEmpty {
            if let tenant = tenantId {
                if tenant == "0" { // 要触发兜底逻辑
                    MailModelManager
                        .shared
                        .getUserTenantId(userId: user)
                        .observeOn(MainScheduler.instance).subscribe { [weak self] (tenantId) in
                        guard let self = self else { return }
                            if self.checkIsExternal(tenantId: tenantId, currentTenantID: currentTenantID) {
                                // external tenant, show actionSheet
                                result(.nameCard)
                            } else {
                                // same tenant, show profile
                                result(.profile)
                            }
                    } onError: { [weak self] (_) in
                        guard let self = self else { return }
                        self.logger.info("MailContactLogic check tenantId fail")
                        result(.actionSheet)
                        }.disposed(by: disposeBag)
                } else {
                    if self.checkIsExternal(tenantId: tenant, currentTenantID: currentTenantID) {
                        // external tenant, show actionSheet
                        result(.nameCard)
                    } else {
                        // same tenant, show profile
                        result(.profile)
                    }
                }
            } else {
                // no tenantId
                result(.actionSheet)
            }
        } else {
            // 没有 user id的情况，要打开名片夹
            result(.nameCard)
        }
    }

    func checkTenantId(userId: String, tenantIdRes: @escaping (String?) -> Void) {
        MailModelManager
            .shared
            .getUserTenantId(userId: userId)
            .observeOn(MainScheduler.instance).subscribe { [weak self] (tenantId) in
            guard let self = self else { return }
                tenantIdRes(tenantId)
        } onError: { [weak self] (_) in
            guard let self = self else { return }
            tenantIdRes(nil)
            }.disposed(by: disposeBag)
    }

    private func checkIsExternal(tenantId: String, currentTenantID: String) -> Bool {
        return tenantId.isEmpty || tenantId != currentTenantID
    }
}
// Type transform
extension Email_Client_V1_Address.LarkEntityType {
    /// 是否为群组或者
    var isGroupOrEnterpriseMailGroup: Bool {
        return self == .group || self == .enterpriseMailGroup
    }
    
    func toContactType() -> ContactType {
        var type = ContactType.unknown
        switch self {
        case .user:
            type = .chatter
        case .group:
            type = .group
        case .sharedMailbox:
            type = .sharedMailbox
        case .enterpriseMailGroup:
            type = .enterpriseMailGroup
        case .unknown:
            type = .unknown
        @unknown default:
            break
        }
        return type
    }
}

extension ContactType {
    /// 会丢失用户信息细节，请酌情使用。
    /// - Returns: description
    func toLarkEntityType() -> Email_Client_V1_Address.LarkEntityType {
        var type = Email_Client_V1_Address.LarkEntityType.unknown
        switch self {
        case .chatter: type = .user
        case .group: type = .group
        case .sharedMailbox: type = .sharedMailbox
        case .enterpriseMailGroup: type = .enterpriseMailGroup
        case .unknown: type = .unknown
        case .externalContact: type = .unknown
        case .nameCard: type = .unknown
        @unknown default: break
        }
        return type
    }
}

// pb helper extension
extension Email_Client_V1_Address.LarkEntityType: MailContactTypeDetailCheckable {
    func isJumpDetailAble() -> Bool {
        if self.isGroupOrEnterpriseMailGroup || self == .sharedMailbox {
            return false
        }
        return true
    }
}

extension ContactType: MailContactTypeDetailCheckable {
    func isJumpDetailAble() -> Bool {
        if self == .group || self == .sharedMailbox || self == .enterpriseMailGroup {
            return false
        }
        return true
    }
}
