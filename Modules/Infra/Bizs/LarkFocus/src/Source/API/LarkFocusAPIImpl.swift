//
//  LarkFocusAPIImpl.swift
//  EEAtomic
//
//  Created by Hayden Wang on 2021/9/8.
//

import Foundation
import RxSwift
import RustPB
import LarkRustClient
import LarkSDKInterface
import ServerPB

public final class LarkFocusAPIImpl: LarkFocusAPI {

    public var client: RustService

    public init(client: RustService) {
        self.client = client
    }

    /// 新增
    public func createFocusStatus(title: String,
                                  iconKey: String,
                                  statusDescRichText: FocusStatusDescRichText,
                                  notDisturb: Bool) -> Observable<UserFocusStatus> {
        var request = Contact_V1_CreateUserCustomStatusRequest()
        request.title = title
        request.iconKey = iconKey
        request.isNotDisturbMode = notDisturb
        request.statusDesc = statusDescRichText
        return client.sendAsyncRequest(request) { (response: CreateFocusResponse) in
            response.status
        }
    }

    /// 删除一组
    public func deleteFocusStatus(byIds ids: [Int64]) -> Observable<[Int64: UserFocusStatus]> {
        var request = Contact_V1_DeleteUserCustomStatusRequest()
        request.deleteIds = ids
        return client.sendAsyncRequest(request) { (response: DeleteFocusResponse) in
            response.status
        }
    }

    /// 删除单个
    public func deleteFocusStatus(byId id: Int64) -> Observable<[Int64: UserFocusStatus]> {
        return deleteFocusStatus(byIds: [id])
    }

    /// 修改一组
    public func updateFocusStatus(with updaters: [FocusStatusUpdater]) -> Observable<[Int64: UserFocusStatus]> {
        var request = Contact_V1_UpdateUserCustomStatusRequest()
        request.updateStatus = updaters
        return client.sendAsyncRequest(request) { (response: UpdateFocusResponse) in
            response.status
        }
    }

    /// 修改单个
    public func updateFocusStatus(with updater: FocusStatusUpdater) -> Observable<UserFocusStatus?> {
        var request = Contact_V1_UpdateUserCustomStatusRequest()
        request.updateStatus = [updater]
        return client.sendAsyncRequest(request) { (response: UpdateFocusResponse) in
            response.status[updater.id]
        }
    }

    /// 查询
    public func getFocusList(strategy: Basic_V1_SyncDataStrategy) -> Observable<[UserFocusStatus]> {
        var request = Contact_V1_GetUserCustomStatusRequest()
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request) { (response: GetFocusListResponse) in
            response.status
        }
    }

    /// 获取推荐的表情 Key
    public func getRecommendedIcons(strategy: Basic_V1_SyncDataStrategy) -> Observable<[String]> {
        var request = Contact_V1_GetChatterStatusIconsRequest()
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request) { (response: RecommendedFocusIconResponse) in
            response.icons.map { $0.iconKey }
        }
    }
    
    public func checkCanCreateNewStatus() -> Observable<Bool> {
        let request = ServerPB_Im_settings_IsAllowedCreateUserCustomStatusRequest()
        return client.sendPassThroughAsyncRequest(request, serCommand: .isAllowedCreateUserCustomStatus) { (response: ServerPB_Im_settings_IsAllowedCreateUserCustomStatusResponse) in
            response.isAllowed
        }
    }
}
