//
//  NoPermissionDeviceCredibilityStep.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/28.
//

import Foundation
import RxSwift

final class NoPermissionDeviceCredibilityStep: NoPermissionBaseStep {

    // MARK: - UI

    override var nextTitle: String { return "" }
    override var detailTitle: String { I18N.Lark_Conditions_DeviceStatus }
    override var detailSubtitle: String { I18N.Lark_Conditions_Credit }
    override var emptyDetail: String { I18N.Lark_Conditions_DeviceStatusNo }

    override var nextHidden: Bool { return true }
    override var reasonDetailHidden: Bool { return false }
    override var refreshTop: NoPermissionLayout.Refresh { .init(top: 24, align: .detail) }
    override var nextTop: NoPermissionLayout.Next { .init(top: 24, align: .detail) }

}
