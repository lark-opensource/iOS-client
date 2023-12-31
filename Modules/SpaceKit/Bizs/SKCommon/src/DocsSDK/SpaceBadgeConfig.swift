//
//  SpaceBadgeConfig.swift
//  SKCommon
//
//  Created by Weston Wu on 2020/12/17.
//

import Foundation
import RxSwift
import RxRelay

public protocol SpaceBadgeConfig {
    var badgeVisableUpdated: Observable<Bool> { get }
    func cleanBadge()
}

// 占位用，不显示tab小红点
public final class SpaceEmptyBadgeConfig: SpaceBadgeConfig {
    public var badgeVisableUpdated: Observable<Bool> { .just(false) }
    public func cleanBadge() {}
    public init() {}
}
