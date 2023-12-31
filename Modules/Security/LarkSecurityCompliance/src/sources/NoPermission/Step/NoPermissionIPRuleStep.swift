//
//  NoPermissionIPRuleStep.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/28.
//

import Foundation
import RxSwift

final class NoPermissionIPRuleStep: NoPermissionBaseStep {

    // MARK: - UI

    override var nextTitle: String { "" }
    override var detailTitle: String { I18N.Lark_Conditions_TryNow }
    override var detailSubtitle: String { I18N.Lark_Conditions_OnceEdited }
    override var emptyDetail: String { I18N.Lark_Conditions_Internet }

    override var nextHidden: Bool { true }
    override var reasonDetailHidden: Bool { false }
    override var refreshTop: NoPermissionLayout.Refresh { .init(top: 24, align: .detail) }
    override var nextTop: NoPermissionLayout.Next { .init(top: 24, align: .detail) }

}
