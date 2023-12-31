//
//  FeedFilterSettingHandler.swift
//  LarkFeed
//
//  Created by kangsiwan on 2020/12/25.
//

import UIKit
import Foundation
import LarkMessengerInterface
import Swinject
import LarkUIKit
import EENavigator
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface
import LarkOpenFeed
import LarkNavigator

final class FeedFilterSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: FeedFilterSettingBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver

        let addMuteGroupEnable = try resolver.resolve(assert: FeedMuteConfigService.self).addMuteGroupEnable()
        let fixedVM = try resolver.resolve(assert: FilterFixedViewModel.self)
        let labelVM = try resolver.resolve(assert: LabelMainListViewModel.self)
        let dependency = try FilterSettingDependencyImpl(resolver: resolver,
                                                     showCommonlyFilters: fixedVM.filterSetting?.mobileShowEnable ?? false,
                                                     highlight: body.highlight,
                                                     showMoreSetsItem: (body.source == .fromFeed),
                                                     addMuteGroupEnable: addMuteGroupEnable,
                                                     labelVM: labelVM)
        let vc: BaseUIViewController
        if body.showMuteFilterSetting {
            vc = FeedFilterSettingViewController(viewModel: FeedFilterSettingViewModel(dependency: dependency))
        } else {
            vc = FeedFilterSortViewController(viewModel: FilterSortViewModel(dependency: dependency))
        }
        res.end(resource: vc)
        FeedTeaTrack.trackFilterEditView(source: body.source.rawValue)
    }
}
