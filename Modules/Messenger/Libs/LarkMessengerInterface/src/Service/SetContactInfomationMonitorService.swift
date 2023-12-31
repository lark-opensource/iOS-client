//
//  SetContactInfomationMonitorService.swift
//  LarkMessengerInterface
//
//  Created by bytedance on 2020/11/5.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import LarkSDKInterface

/// Monitor提供的服务类型
public enum MonitorServiceType: String {
    // 屏蔽状态改变
    case blockStatusChangeService = "blockStatusService"
}

public protocol SetContactInfomationMonitorService: AnyObject {

    // 设置屏蔽用户
    func setUserBlockAuthWith(blockUserID: String, isBlock: Bool) -> Observable<SetupBlockUserResponse>

    // 获取屏蔽状态
    func getUserBlockAuthority(userId: String, strategy: SyncDataStrategy?) -> Observable<Contact_V2_GetUserBlockStatusResponse>

    // 删除联系人
    func deleContact(userId: String) -> Observable<Void>

    // 注册消息通知 主线程回调
    func registerObserver(_ obj: AnyObject, method: Selector, serverType: MonitorServiceType)
    // 移除观察者
    func removeObserver(_ obj: AnyObject, serverType: MonitorServiceType)
    func removeObserver(_ obj: AnyObject)

    func getUserIdFromNotObjet(_ not: Any?) -> String?
    func getUserBlockStatusFromNotObjet(_ not: Any?) -> Bool?
}
