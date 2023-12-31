//
//  UserGroupViewModel.swift
//  LarkContact
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import LarkModel
import RxSwift
import RxRelay
import RustPB
import ServerPB
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging
import LarkRustClient

final class UserGroupViewModel {
    static let logger = Logger.log(UserGroupViewModel.self, category: "Module.IM.UserGroupViewModel")
    struct Cursor {
        var value: String = ""
        var isEnd = false
    }
    var pageCount = 30
    private(set) var userGroupCursor = Cursor()

    private let userGroupsVariable = BehaviorRelay<[SelectVisibleUserGroup]>(value: [])
    lazy var userGroupsObservable: Observable<[SelectVisibleUserGroup]> = self.userGroupsVariable.asObservable()
    public var client: RustService
    let groupSceneType: UserGroupSceneType

    public init(client: RustService,
                userGroupSceneType: UserGroupSceneType) {
        self.client = client
        self.groupSceneType = userGroupSceneType
    }

    func firstLoadUserGroupData() -> Observable<Void> {
        var request = ServerPB.ServerPB_Visibility_ScanUserVisibleGroupRequest()
        request.sceneType = transformServerSceneType()
        request.limit = Int32(pageCount)
        return client.sendPassThroughAsyncRequest(request, serCommand: .scanUserVisibleGroup).map { [weak self] (response: ServerPB_Visibility_ScanUserVisibleGroupResponse) in
            guard let self = self else { return }
            Self.logger.info("firstloadUserGroup server accept, groupCount = \(response.groups.count), has more: \(response.hasMore_p)")
            self.userGroupCursor.value = response.nextCursor
            self.userGroupCursor.isEnd = !response.hasMore_p
            let userGroups = response.groups.map { (groupEntity) -> SelectVisibleUserGroup in
                SelectVisibleUserGroup.transform(pb: groupEntity)
            }
            self.userGroupsVariable.accept(userGroups)
        }
    }

    func loadMoreUserGroupData() -> Observable<Bool> {
        var request = ServerPB.ServerPB_Visibility_ScanUserVisibleGroupRequest()
        request.sceneType = transformServerSceneType()
        request.limit = Int32(pageCount)
        request.cursor = userGroupCursor.value
        return client.sendPassThroughAsyncRequest(request, serCommand: .scanUserVisibleGroup).map { [weak self] (response: ServerPB_Visibility_ScanUserVisibleGroupResponse) -> Bool in
            guard let self = self else { return true }

            Self.logger.info("loadMoreUserGroup server accept, groupCount = \(response.groups.count), has more: \(response.hasMore_p)")
            var temp = self.userGroupsVariable.value
            let userGroups = response.groups.map { (groupEntity) -> SelectVisibleUserGroup in
                SelectVisibleUserGroup.transform(pb: groupEntity)
            }
            temp.append(contentsOf: userGroups)
            self.userGroupCursor.value = response.nextCursor
            self.userGroupCursor.isEnd = !response.hasMore_p
            self.userGroupsVariable.accept(temp)
            return !response.hasMore_p
        }
    }

    /// 用户组类型转换
    func transformServerSceneType() -> ServerPB_Visibility_GroupSceneType {
        return ServerPB_Visibility_GroupSceneType(rawValue: groupSceneType.rawValue) ?? ServerPB_Visibility_GroupSceneType()
    }
}

extension SelectVisibleUserGroup {

    fileprivate static func extractedFunc(_ pb: ServerPB_Visibility_ScanUserVisibleGroupResponse.GroupEntity, _ groupType: UserGroupType) -> SelectVisibleUserGroup {
        return SelectVisibleUserGroup(id: String(pb.id),
                                      name: pb.name,
                                      groupType: groupType)
    }

    public static func transform(pb: ServerPB.ServerPB_Visibility_ScanUserVisibleGroupResponse.GroupEntity) -> SelectVisibleUserGroup {
        var groupType: UserGroupType = .normal
        switch pb.type {
        case ServerPB_Visibility_GroupType.normal:
            break
        case ServerPB_Visibility_GroupType.dynamic:
            groupType = .dynamic
        @unknown default:
            assertionFailure("unknow type")
        }
        return extractedFunc(pb, groupType)
    }
}
