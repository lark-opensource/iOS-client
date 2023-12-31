//
//  AllFeedsDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/10.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB

protocol AllFeedsDependency {
    /// 是否显示新引导
    func needShowNewGuide(guideKey: String) -> Bool

    // 是否显示主导航免打扰badge
    var tabMuteBadgeObservable: Observable<Bool> { get }

    var showMute: Bool { get }
    func getAllBadge() -> Observable<Feed_V1_GetAllBadgeResponse>
}
