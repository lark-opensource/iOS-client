//
//  FeedMsgDisplaySettingHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/22.
//

import Foundation
import Swinject
import EENavigator
import LarkNavigator
import RxSwift

public struct FeedMsgDisplaySettingBody: PlainBody {
    public static let pattern = "//client/feed/msgDisplaySetting"
    let filterName: String
    let currentItem: FeedMsgDisplayFilterItem
    let selectObservable = PublishSubject<FeedMsgDisplayFilterItem>()
    init(filterName: String, currentItem: FeedMsgDisplayFilterItem) {
        self.filterName = filterName
        self.currentItem = currentItem
    }
}

final class FeedMsgDisplaySettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: FeedMsgDisplaySettingBody, req: EENavigator.Request, res: Response) throws {
        let dependency = FeedMsgDisplaySettingDependencyImpl(userResolver: userResolver,
                                                             filterName: body.filterName,
                                                             currentItem: body.currentItem,
                                                             selectObservable: body.selectObservable)
        let vm = FeedMsgDisplaySettingViewModel(userResolver: userResolver, dependency: dependency)
        let vc = FeedMsgDisplaySettingViewController(viewModel: vm)
        res.end(resource: vc)
    }
}
