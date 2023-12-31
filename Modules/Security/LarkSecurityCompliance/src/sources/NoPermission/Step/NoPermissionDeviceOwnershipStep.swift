//
//  NoPermissionDeviceOwnershipStep.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/28.
//

import Foundation
import EENavigator
import RxSwift
import LarkContainer

final class NoPermissionDeviceOwnershipStep: NoPermissionBaseStep {

    private var isDeviceApplyOpen = false
    required init(resolver: UserResolver, context: NoPermissionStepContext) throws {
        try super.init(resolver: resolver, context: context)
        let getDeviceApplySwitch = http.getDeviceApplySwitch()
            .map { $0.data.isOpen }
            .retry(2)
            .catchErrorJustReturn(false)
        context.rx.observe(GetDeviceInfoResp.self, "deviceInfo")
            .filter({ $0 != nil })
            .flatMapLatest({ resp -> Observable<Bool> in
                return getDeviceApplySwitch
                    .map { $0 && resp?.ownership == .unknown }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                self?.isDeviceApplyOpen = value
                self?.updateUI.onNext(())
            })
            .disposed(by: bag)
    }

    override func next() {
        guard let viewModel = try? DeviceStatusViewModel(resolver: userResolver, isLimited: true),
              let from = context.from else { return }
        let controller = DeviceStatusViewController(viewModel: viewModel)
        navigator.push(controller, from: from)
    }

    // MARK: - UI

    override var nextTitle: String { I18N.Lark_Conditions_DeviceApply }
    override var detailTitle: String { I18N.Lark_Conditions_DeviceBelonging }
    override var detailSubtitle: String { isDeviceApplyOpen ? I18N.Lark_Conditions_Details : I18N.Lark_Conditions_Personal }
    override var emptyDetail: String { I18N.Lark_Conditions_DeviceUnsure }

    override var nextHidden: Bool { !isDeviceApplyOpen }
    override var reasonDetailHidden: Bool { false }
    override var refreshTop: NoPermissionLayout.Refresh {
        .init(top: isDeviceApplyOpen ? 16 : 24, align: isDeviceApplyOpen ? .next : .detail)
    }
    override var nextTop: NoPermissionLayout.Next { .init(top: 24, align: .detail) }
}
