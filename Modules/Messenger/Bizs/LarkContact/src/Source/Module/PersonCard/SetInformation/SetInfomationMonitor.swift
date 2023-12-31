//
//  SetInfomationMonitor.swift
//  LarkContact
//
//  Created by bytedance on 2020/11/2.
//

import Foundation
import UIKit
import LarkMessengerInterface
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import LarkSDKInterface
import LarkContainer

final class SetInfomationMonitor: SetContactInfomationMonitorService, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var externalContactsAPI: ExternalContactsAPI?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    // 设置屏蔽用户
    func setUserBlockAuthWith(blockUserID: String, isBlock: Bool) -> Observable<SetupBlockUserResponse> {
        guard let chatterAPI = self.chatterAPI else { return .just(SetupBlockUserResponse()) }
        return chatterAPI.setupBlockUserRequest(blockUserID: blockUserID, isBlock: isBlock)
            .do(onNext: {_ in
                // 在主线程发送通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(MonitorServiceType.blockStatusChangeService.rawValue), object: ["userID": blockUserID, "blockStauts": isBlock])
                }
        })
    }

    // 获取屏蔽状态
    func getUserBlockAuthority(userId: String, strategy: SyncDataStrategy?) -> Observable<Contact_V2_GetUserBlockStatusResponse> {
        guard let chatterAPI = self.chatterAPI else { return .just(Contact_V2_GetUserBlockStatusResponse()) }
        return chatterAPI.fetchUserBlockStatusRequest(userId: userId, strategy: strategy)
    }

    // 删除联系人
    func deleContact(userId: String) -> Observable<Void> {
        guard let externalContactsAPI = self.externalContactsAPI else { return .just(Void()) }
        return externalContactsAPI.deleteContact(userId: userId)
    }

    func getUserIdFromNotObjet(_ not: Any?) -> String? {
        guard let info = not as? [String: Any] else {
            return nil
        }

        if let userID = info["userID"] as? String {
            return userID
        }
        return nil
    }

    func getUserBlockStatusFromNotObjet(_ not: Any?) -> Bool? {

        guard let info = not as? [String: Any] else {
            return nil
        }
        if let blockStauts = info["blockStauts"] as? Bool {
            return blockStauts
        }
        return nil
    }

    func registerObserver(_ obj: AnyObject, method: Selector, serverType: MonitorServiceType) {
        NotificationCenter.default.addObserver(obj, selector: method, name: Notification.Name(serverType.rawValue), object: nil)
    }

    func removeObserver(_ obj: AnyObject, serverType: MonitorServiceType) {
        NotificationCenter.default.removeObserver(obj, name: Notification.Name(serverType.rawValue), object: nil)
    }
    func removeObserver(_ obj: AnyObject) {
        // 删除无用的元素
        NotificationCenter.default.removeObserver(obj)
    }

}
