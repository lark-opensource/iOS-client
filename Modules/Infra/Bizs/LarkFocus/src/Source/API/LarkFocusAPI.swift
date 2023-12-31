//
//  LarkFocusAPI.swift
//  EEAtomic
//
//  Created by Hayden Wang on 2021/9/8.
//

import Foundation
import RxSwift
import RustPB
import LarkRustClient
import ServerPB

/// 新增状态的服务端返回值
public typealias CreateFocusResponse = Contact_V1_CreateUserCustomStatusResponse
/// 删除状态的服务端返回值
public typealias DeleteFocusResponse = Contact_V1_DeleteUserCustomStatusResponse
/// 修改状态的服务端返回值
public typealias UpdateFocusResponse = Contact_V1_UpdateUserCustomStatusResponse
/// 查询状态的服务端返回值
public typealias GetFocusListResponse = Contact_V1_GetUserCustomStatusResponse
/// 推荐状态表情的返回值
public typealias RecommendedFocusIconResponse = Contact_V1_GetChatterStatusIconsResponse

/// 个人状态相关 API
public protocol LarkFocusAPI {

    /// 增：创建新的个人状态
    func createFocusStatus(title: String,
                           iconKey: String,
                           statusDescRichText: FocusStatusDescRichText,
                           notDisturb: Bool) -> Observable<UserFocusStatus>

    /// 删：删除一组个人状态
    func deleteFocusStatus(byIds ids: [Int64]) -> Observable<[Int64: UserFocusStatus]>

    /// 删：删除单个个人状态
    func deleteFocusStatus(byId id: Int64) -> Observable<[Int64: UserFocusStatus]>

    /// 改：修改一组个人状态
    func updateFocusStatus(with updaters: [FocusStatusUpdater]) -> Observable<[Int64: UserFocusStatus]>

    /// 改：修改单个个人状态
    func updateFocusStatus(with updater: FocusStatusUpdater) -> Observable<UserFocusStatus?>

    /// 查：获取当前的个人状态列表
    func getFocusList(strategy: Basic_V1_SyncDataStrategy) -> Observable<[UserFocusStatus]>

    /// 获取推荐的表情 Key
    func getRecommendedIcons(strategy: Basic_V1_SyncDataStrategy) -> Observable<[String]>
    
    /// 询问服务端是否能继续创建个人状态
    func checkCanCreateNewStatus() -> Observable<Bool>
}

extension Error {

    var debugMessage: String? {
        if let rcError = self as? RCError {
            switch rcError {
            case .businessFailure(let info):
                return info.displayMessage
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
