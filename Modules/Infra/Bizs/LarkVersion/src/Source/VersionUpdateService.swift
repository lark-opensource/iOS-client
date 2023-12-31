//
//  VersionUpdateService.swift
//  LarkVersion
//
//  Created by 姚启灏 on 2018/9/7.
//

import Foundation
import RxSwift

/// 触发版本更新检查的 Trigger
public struct VersionCheckTrigger {
    public enum Source: String {
        case feedDidAppear
    }

    public var observable: Observable<Void>
    public var source: Source

    public init(observable: Observable<Void>, source: Source) {
        self.observable = observable
        self.source = source
    }
}

public protocol VersionUpdateService {
    var shouldUpdate: Bool { get }
    var isShouldUpdate: BehaviorSubject<Bool> { get }
    var shouldNoticeNewVerison: BehaviorSubject<Bool> { get }

    func getCurrentVersionNotes() -> Observable<String>
    func updateLark()
    func tryToCleanUpNotice()

    func setup()

    /// 新增版本检查的 Trigger
    func addCheckTrigger(_ trigger: VersionCheckTrigger)
}
