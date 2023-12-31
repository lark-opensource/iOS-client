//
//  StructureService.swift
//  LarkContact
//
//  Created by JackZhao on 2021/3/23.
//

import Foundation
import LarkRustClient
import LarkContainer
import RxSwift
import RustPB
import ServerPB
import LKCommonsLogging

protocol StructureService {
    func fetchContactEntriesRequest(isFromServer: Bool, scene: Contact_V2_GetContactEntriesRequest.Scene) -> Observable<ContactEntries>

    // 当前默认一次性拉取组织架构、内部组织、外部组织可见性
    func fetchOrganizationVisible() -> Observable<OrganizationEntryVisible>

}

enum FetchSource {
    case local
    case server
}

final class StructureServiceImpl: StructureService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var rustService: RustService?

    private static var logger = Logger.log(StructureServiceImpl.self, category: "Contact")
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func fetchContactEntriesRequest(isFromServer: Bool, scene: Contact_V2_GetContactEntriesRequest.Scene) -> Observable<ContactEntries> {
        guard let rustService = self.rustService else { return .just(ContactEntries()) }
        var request = RustPB.Contact_V2_GetContactEntriesRequest()
        request.syncDataStrategy = isFromServer ? .forceServer : .local
        request.scene = scene
        return rustService.sendAsyncRequest(request) { (res: RustPB.Contact_V2_GetContactEntriesResponse) -> (ContactEntries) in
            var entries = ContactEntries()
            // 这个入口服务端不作控制, 后面下掉机器人代码统一去掉
            entries.isShowRobot = true
            entries.isShowOrganization = res.entries.first(where: { $0.type == .organization })?.isVisible ?? true
            entries.isShowExternalContacts = res.entries.first(where: { $0.type == .externalContacts })?.isVisible ?? true
            entries.isShowNewContacts = res.entries.first(where: { $0.type == .newContacts })?.isVisible ?? true
            entries.isShowChatGroups = res.entries.first(where: { $0.type == .chatGroups })?.isVisible ?? true
            entries.isShowHelpDesks = res.entries.first(where: { $0.type == .helpDesks })?.isVisible ?? true
            entries.isShowRelatedOrganizations = res.entries.first(where: { $0.type == .relatedOrganizations })?.isVisible ?? true
            entries.isShowSpecialFocusList = res.entries.first(where: { $0.type == .specialFocus })?.isVisible ?? true
            entries.isShowUserGroup = res.entries.first(where: { $0.type == .userGroup })?.isVisible ?? false
            entries.isShowMyAI = res.entries.first(where: { $0.type == .myAi })?.isVisible ?? true
            StructureServiceImpl.logger.info("Contact.Request: get contact entries: \(res.entries.compactMap { $0.isVisible ? $0.type.rawValue : nil })")
            return entries
        }
    }

    func fetchOrganizationVisible() -> Observable<OrganizationEntryVisible> {
        guard let rustService = self.rustService else { return .just(.defaultValue)}

        var request = ServerPB.ServerPB_Contact_PullContactStructureRequest()
        request.pullType = [.internalCollaboration, .subordinateDepartment]

        return rustService.sendPassThroughAsyncRequest(request, serCommand: .pullContactStructure) { (response: ServerPB_Contact_PullContactStructureResponse) -> OrganizationEntryVisible in
            OrganizationEntryVisible(subordinateDepartmentVisible: response.subordinateDept.visibleAny, internalCollaborationVisible: response.internalCollaboration.visibleAny)
        }.do(onError: { error in
            Self.logger.error("fetch organization fail", error: error)
        })
    }
}

struct OrganizationEntryVisible {
    // 组织内联系人是否展示
    var subordinateDepartmentVisible: Bool
    // 内部关联组织是否展示
    var internalCollaborationVisible: Bool

    static let defaultValue = OrganizationEntryVisible(subordinateDepartmentVisible: false, internalCollaborationVisible: false)

}
