//
//  NoPermissionStep.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import UIKit

final class NoPermissionStepContext: NSObject {
    let model: NoPermissionRustActionModel
    weak var from: ViewModelCoordinator?
    @objc dynamic var deviceInfo: GetDeviceInfoResp?

    init(model: NoPermissionRustActionModel, from: ViewModelCoordinator?) {
        self.model = model
        self.from = from
        super.init()
    }

    func getStepType(_ action: NoPermissionRustActionModel.Action) -> NoPermissionStep.Type? {
        switch action {
        case .mfa:
            return NoPermissionMFAStep.self
        case .deviceOwnership:
            return NoPermissionDeviceOwnershipStep.self
        case .deviceCredibility:
            return NoPermissionDeviceCredibilityStep.self
        case .network:
            return NoPermissionIPRuleStep.self
        case .fileblock, .dlp, .ttBlock, .pointDowngrade, .universalFallback:
            return nil
        case .unknown:
            return nil
        }
    }

}

// swiftlint:disable nesting
enum NoPermissionLayout {
    struct Refresh {
        enum Align {
            case detail
            case next
        }

        let top: CGFloat
        let align: Align
    }

    struct Next {
        enum Align {
            case empty
            case detail
        }

        let top: CGFloat
        let align: Align
    }
}
// swiftlint:enable nesting
protocol NoPermissionStepUI {
    var nextTitle: String { get }
    var emptyDetail: String { get }
    var detailTitle: String { get }
    var detailSubtitle: String { get }

    var nextHidden: Bool { get }
    var reasonDetailHidden: Bool { get }
    var refreshTop: NoPermissionLayout.Refresh { get }
    var nextTop: NoPermissionLayout.Next { get }

}

protocol NoPermissionStep: NoPermissionStepUI {
    var http: DeviceManagerAPI { get }
    var updateUI: PublishSubject<Void> { get }
    var context: NoPermissionStepContext { get }
    init(resolver: UserResolver, context: NoPermissionStepContext) throws
    func next()

    var viewDidAppear: PublishSubject<Void> { get }

    var nextButtonLoading: PublishSubject<Bool> { get }
    var refreshWithAnimationFromStep: PublishSubject<Void> { get }

    var retryButtonClicked: PublishSubject<Void> { get }
}

extension NoPermissionStep {
    func refresh() -> Observable<Bool> {
        return self.http.ping()
            .map { $0.code == 0 }
            .catchErrorJustReturn(false)
    }
}
