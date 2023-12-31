//
//  AIDependency.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2020/11/2.
//

import UIKit
import Foundation
import LarkMessengerInterface
import RxSwift
import LarkTab
import EENavigator
import LarkNavigation
import LarkContainer

public typealias AIDependency = AICalendarDependency & OCRDependency

public protocol AICalendarDependency {

    /// Smart Reply中一键约会，跳转到日历界面
    /// - Parameters:
    ///   - chatId:    会话id
    ///   - startDate: 约会开始时间
    ///   - endDate:   约会结束时间
    ///   - duration:  会议时长
    ///   - atList:    at的人的列表
    ///   - timeGrain  时间粒度, ex: second, minute, hour, day
    ///   - pushParam: pushParam
    func smartActionPushToCalendar(chatId: String,
                                   startDate: Date?,
                                   endDate: Date?,
                                   useCount: Int,
                                   isMeeting: Bool,
                                   isAtAll: Bool,
                                   atList: [String]?,
                                   timeGrain: String?,
                                   pushParam: PushParam)
}

public protocol OCRDependency {
    var userResolver: UserResolver { get }
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<(String, String, Bool)>
}

extension OCRDependency {
    func pushDocUrl(url: URL, from: UIViewController) {
        userResolver.navigator.switchTab(Tab.doc.url, from: from, animated: false) { _ in
            guard let realFrom = (RootNavigationController.shared.viewControllers.first as? UITabBarController)?.selectedViewController else {
                return
            }
            userResolver.navigator.push(url, from: realFrom)
        }
    }
}
