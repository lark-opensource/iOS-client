//
//  V3JoinTenantViewModel.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import RxSwift
import Homeric
import LarkAccountInterface
import ECOProbeMeta
import LarkContainer

struct V3JoinTenantTypeItem {
    let stepName: String?
    let title: String
    let icon: UIImage?
    let action: () -> Observable<Void>
    var needLoading: Bool {
        return false
    }
}

class V3JoinTenantViewModel: V3ViewModel {

    let joinTenantInfo: V4JoinTenantInfo

    private let api: JoinTeamAPIProtocol
    @Provider var userManager: UserManager

    var items: [V3JoinTenantTypeItem] = []

    init(
        step: String,
        joinTenantInfo: V4JoinTenantInfo,
        api: JoinTeamAPIProtocol,
        context: UniContextProtocol
    ) {
        self.joinTenantInfo = joinTenantInfo
        self.api = api
        super.init(step: step, stepInfo: joinTenantInfo, context: context)
        self.items = generateItems() ?? []
    }

    func generateItems() -> [V3JoinTenantTypeItem]? {
        return (self.joinTenantInfo.dispatchList?.map({ (item: Menu) -> V3JoinTenantTypeItem in
            V3JoinTenantTypeItem(
                stepName: item.next?.stepName,
                title: item.text,
                icon: image(by: item.actionType),
                action: { [weak self] in
                    guard let self = self else { return .just(()) }
                    if let stepData = item.next {
                        return self.joinTenant(stepData: stepData)
                    } else {
                        return .just(())
                    }
                })
        }))
    }

    func handleSelect(_ row: Int) -> Observable<Void> {
       guard row < items.count else {
           return .just(())
       }
       return items[row].action()
    }

    func item(_ row: Int) -> V3JoinTenantTypeItem {
        guard row < items.count else {
            return V3JoinTenantTypeItem(stepName: "", title: "", icon: UIImage(), action: {.just(())})
        }
       return items[row]
    }

    func joinTenant(stepData: V4StepData) -> Observable<Void> {
        guard let stepName = stepData.stepName, let _ = stepData.stepInfo else {
            Self.logger.error("no joinTenant stepInfo when joinTenant")
            return .error(V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))
        }
        
        if let currentUser = userManager.foregroundUser?.makeUser() { // user:current
            switch stepName {
            case PassportStep.joinTenantCode.rawValue:
                PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_team_code_entry, context: context)
                SuiteLoginTracker.track(Homeric.JOIN_TENANT_CLICK_ENTER_TEAM_CODE,
                                        params: [
                                            TrackConst.path: trackPath,
                                            TrackConst.userType: currentUser.userTypeInString,
                                            TrackConst.userUniqueId: currentUser.userID
                                        ])
            case PassportStep.joinTenantScan.rawValue:
                PassportMonitor.flush(EPMClientPassportMonitorInvitationJoinCode.join_by_scan_code_entry, context: context)
                SuiteLoginTracker.track(Homeric.JOIN_TENANT_CLICK_SCAN_QRCODE,
                                        params: [
                                            TrackConst.path: trackPath,
                                            TrackConst.userType: currentUser.userTypeInString,
                                            TrackConst.userUniqueId: currentUser.userID
                                        ])
            default:
                break
            }
        }

        return Observable.create { ob -> Disposable in
            self.post(
                event: stepName,
                serverInfo: stepData.nextServerInfo(),
                additionalInfo: self.additionalInfo,
                success: {
                    ob.onNext(())
                    ob.onCompleted()
                }, error: { error in
                    ob.onError(error)
                })
            return Disposables.create()
        }
    }

    func usePersonal() -> Observable<Void> {
        return api.create(
            UserCreateReqBody(
                isC: false,
                tenantType: TenantTag.simple.rawValue,
                context: context
            ), serverInfo: joinTenantInfo)
            .post(additionalInfo, context: context)
    }

}

extension V3JoinTenantViewModel {
    var title: String {
        return joinTenantInfo.title
    }

    var subtitle: NSAttributedString {
        return attributedString(for: joinTenantInfo.subtitle)
    }

//    var description: NSAttributedString {
//        return attributedString(for: joinTenantInfo.registerButton.text)
//    }
}

extension V3JoinTenantViewModel {
    func image(by actionType: ActionIconType?) -> UIImage? {
        guard let type = actionType else {
            return nil
        }
        switch type {
        case .register:
            return BundleResources.LarkAccount.V4.v4_register_new
        case .join:
            return BundleResources.LarkAccount.V4.v4_login_new
        case .joinCode:
            return BundleResources.LarkAccount.V3.join_tenant_input_team_code
        case .joinScan:
            return BundleResources.LarkAccount.V3.join_tenant_scan_qrcode
        case .createTenant:
            return BundleResources.LarkAccount.V4.v4_create_tenant
        case .createPersonal:
            return BundleResources.LarkAccount.V4.v4_create_user
        default:
            return nil
        }
    }
}
