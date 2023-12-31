//
//  SpaceMoreItemChecker.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/4.
//

import Foundation
import RxSwift
import RxRelay
import SKResource
import SKFoundation
import SpaceInterface

public typealias FileDeletedChecker = FolderDeletedChecker

public final class FolderDeletedChecker: RxChecker {
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<Bool>(value: false)
    public var checkedValue: Bool { false }

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    public init(input: Observable<Bool>) {
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: Bool, checkedValue: Bool) -> Bool {
        // 被删除，则需要隐藏、禁用
        !input
    }
}

public final class FolderComplaintChecker: RxChecker {
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<Bool>(value: false)
    public var checkedValue: Bool { false }

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    public init(input: Observable<Bool>) {
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: Bool, checkedValue: Bool) -> Bool {
        // 被封禁，则需要隐藏、禁用
        !input
    }
}

public final class DriveFileSizeChecker: RxChecker {
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<Int64?>(value: nil)
    public let checkedValue: Int64?

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    // sizeLimit 传 nil 或小于 0 表示不限制大小
    public init(input: Observable<Int64?>, sizeLimit: Int64?) {
        checkedValue = sizeLimit
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: Int64?, checkedValue: Int64?) -> Bool {
        // 没拉到返回 false
        guard let fileSize = input else { return false }
        // size 不能为 0
        guard fileSize != 0 else { return false }
        guard let sizeLimit = checkedValue else {
            // 没有设置 sizeLimit
            return true
        }
        return fileSize < sizeLimit
    }
}

public final class BizChecker: HiddenChecker, EnableChecker {
    public var isHidden: Bool {
        !checker()
    }

    public var isEnabled: Bool {
        checker()
    }

    public let disableReason: String

    private let checker: () -> Bool

    public init(disableReason: String, staticChecker: Bool) {
        self.disableReason = disableReason
        self.checker = { staticChecker }
    }

    public init(disableReason: String, dynamicChecker: @escaping () -> Bool) {
        self.disableReason = disableReason
        self.checker = dynamicChecker
    }
}

public final class RxBizChecker: RxChecker {
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<Bool>(value: false)
    public let checkedValue = true

    public let disableReason: String

    public init(disableReason: String, input: Observable<Bool>) {
        self.disableReason = disableReason
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: Bool, checkedValue: Bool) -> Bool {
        input == checkedValue
    }
}

public final class SecretLevelChecker: RxChecker {
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<SecretLevel?>(value: nil)
    public let checkedValue: Void

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    public init(input: Observable<SecretLevel?>) {
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: SecretLevel?, checkedValue: Void) -> Bool {
        return input != nil
    }
}
