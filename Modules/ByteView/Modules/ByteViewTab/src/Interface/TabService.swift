//
//  ByteViewDependencies.swift
//  ByteViewDependency
//
//  Created by kiri on 2021/7/1.
//

import Foundation
import UIKit
import ByteViewCommon
import RxSwift
import ByteViewNetwork

public final class TabService {
    public static let shared = TabService()
    private init() {}

    public func createTabViewController(dependency: TabDependency) -> ByteViewBaseTabViewController {
        _ = TabService.loadGenericTypes
        Util.setup(dependency.global)
        return MeetTabViewController(viewModel: MeetTabListViewModel(dependency: dependency))
    }

    public func createBadgeService(userId: String, httpClient: HttpClient) -> TabBadgeService {
        TabBadgeServiceImpl(userId: userId, httpClient: httpClient)
    }

    /// 会议历史页面加载完毕后尝试滚动至 meetingID
    @RwAtomic
    public var scrollToHistoryID = ReplaySubject<String>.create(bufferSize: 1)

    @RwAtomic
    public var openMeetingID = ReplaySubject<(String, Bool)>.create(bufferSize: 1)

    private static let loadGenericTypes: Void = {
        // 初始化泛型缓存，防止崩溃
        // https://t.wtturl.cn/rwFAFxV/
        let testObj: Any = NSObject()
        _ = testObj as? TabMeetingGrootSession
        _ = testObj as? TabListGrootSession
        _ = testObj as? TabUserGrootSession
        return Void()
    }()
}
