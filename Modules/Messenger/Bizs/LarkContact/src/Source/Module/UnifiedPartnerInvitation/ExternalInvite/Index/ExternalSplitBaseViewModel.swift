//
//  ExternalSplitBaseViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/12/30.
//

import UIKit
import Foundation
import LarkFoundation
import RxSwift
import LKCommonsTracker
import LarkFeatureGating
import LarkSetting
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkContainer
import Homeric
import LarkStorage

enum EntranceFlag: String {
    case createNearbyGroup // 面对面建群
    case importFromAddressbook
    case scan
}

struct ExternalSplitEntrance {
    let icon: UIImage
    let title: String
    let flag: EntranceFlag
}

struct ExternalInviteContext {
    let needDisplayGuide: Bool
    let inviteInfo: InviteAggregationInfo
}

class ExternalSplitBaseViewModel: UserResolverWrapper {
    private(set) var sectionCount: Int = 0
    private(set) var rowCountInSection: [Int] = []
    private(set) var entrances: [ExternalSplitEntrance] = []
    private lazy var externalInviteAPI: ExternalInviteAPI = {
        return ExternalInviteAPI(resolver: self.userResolver)
    }()
    private let monitor = InviteMonitor()
    @ScopedInjectedLazy var chatApplicationAPI: ChatApplicationAPI?
    let fromEntrance: ExternalInviteSourceEntrance
    var userResolver: LarkContainer.UserResolver

    init(fromEntrance: ExternalInviteSourceEntrance, resolver: UserResolver) {
        self.fromEntrance = fromEntrance
        self.userResolver = resolver
        genDataSource()
    }

    func genDataSource() {
        entrances = [ExternalSplitEntrance(
            icon: Resources.createNearbyGroupFromContacts,
            title: BundleI18n.LarkContact.Lark_NearbyGroup_Title,
            flag: .createNearbyGroup
        ),
        ExternalSplitEntrance(
            icon: Resources.scan,
            title: BundleI18n.LarkContact.Lark_Legacy_LarkScan,
            flag: .scan
        ),
        ExternalSplitEntrance(
            icon: Resources.add_from_contacts_icon,
            title: BundleI18n.LarkContact.Lark_Contacts_MobileContacts,
            flag: .importFromAddressbook
        )].filter { (entrance) -> Bool in
            switch entrance.flag {
            case .createNearbyGroup:
                return true
            case .importFromAddressbook:
                return !Utils.isiOSAppOnMacSystem
                && userResolver.fg.staticFeatureGatingValue(with: .enableAddFromMobileContact)
            case .scan:
                return !Utils.isiOSAppOnMacSystem
            }
        }
        sectionCount = entrances.isEmpty ? 0 : 1
        rowCountInSection = [entrances.count]
    }

    func fetchInviteLinkFromLocal() -> Observable<InviteAggregationInfo> {
        return externalInviteAPI.fetchInviteAggregationInfoFromLocal()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
    }

    func fetchInviteLinkFromServer() -> Observable<InviteAggregationInfo> {
        return externalInviteAPI.fetchInviteAggregationInfoFromServer()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
    }

    func fetchDisplayGuideFlag() -> Observable<Bool> {
        var hasDisplayExternalInviteGuideConf = KVConfig(
            key: KVKeys.Contact.hasDisplayExternalInviteGuide,
            store: udkv(domain: contactDomain)
        )
        if hasDisplayExternalInviteGuideConf.value {
            return .just(false)
        }
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_GUIDE,
            indentify: String(startTimeInterval)
        )
        guard let chatApplicationAPI = self.chatApplicationAPI else { return .just(false) }
        return chatApplicationAPI.fetchInviteGuideContext()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .map { (resp) -> Bool in
                return resp.success
            }
            .do(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                hasDisplayExternalInviteGuideConf.value = true
                self.monitor.endEvent(
                    name: Homeric.UG_INVITE_EXTERNAL_GUIDE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true"],
                    extra: [:]
                )
                Tracer.trackInvitePeopleExternalGuideView(source: self.fromEntrance.rawValue)
            }, onError: { [weak self] (error) in
                guard let apiError = error.underlyingError as? APIError else { return }
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_EXTERNAL_GUIDE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "false",
                               "error_code": apiError.code],
                    extra: ["error_msg": apiError.serverMessage]
                )
            })
    }

}
