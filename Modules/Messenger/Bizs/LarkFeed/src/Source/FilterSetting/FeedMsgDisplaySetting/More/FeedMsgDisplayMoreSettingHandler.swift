//
//  FeedMsgDisplayMoreSettingHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/29.
//

import Foundation
import Swinject
import EENavigator
import LarkNavigator
import RxSwift

public struct FeedMsgDisplayMoreSettingBody: PlainBody {
    public static let pattern = "//client/feed/msgDisplayMoreSetting"
    let currentSelectedItemsMap: [Int64: FeedMsgDisplayFilterItem]?
    let selectObservable = PublishSubject<[Int64: FeedMsgDisplayFilterItem]>()
    init(currentSelectedItemsMap: [Int64: FeedMsgDisplayFilterItem]?) {
        self.currentSelectedItemsMap = currentSelectedItemsMap
    }
}

final class FeedMsgDisplayMoreSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: FeedMsgDisplayMoreSettingBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let labelVM = try resolver.resolve(assert: LabelMainListViewModel.self)
        let dependency = FeedMsgDisplayMoreSettingDependencyImpl(labelViewModel: labelVM,
                                                                 currentSelectedItemsMap: body.currentSelectedItemsMap,
                                                                 selectObservable: body.selectObservable)
        let vm = FeedMsgDisplayMoreSettingViewModel(userResolver: resolver, dependency: dependency)
        let vc = FeedMsgDisplayMoreSettingViewController(viewModel: vm)
        res.end(resource: vc)
    }
}
