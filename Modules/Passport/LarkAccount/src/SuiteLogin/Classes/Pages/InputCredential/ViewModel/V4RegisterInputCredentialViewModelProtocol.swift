//
//  V4RegisterInputCredentialViewModelProtocol.swift
//  LarkAccount
//
//  Created by au on 2021/6/15.
//

import Foundation
import LarkAccountInterface
import RxSwift
import RxCocoa

protocol V4RegisterInputCredentialViewModelProtocol {

    var flowType: String { get }

    var userCenterInfo: V4UserOperationCenterInfo? { get }

    var title: String { get }

    var subtitle: String { get }

    var namePlaceholder: String { get }

    var nextButtonTitle: String { get }

    var processTip: NSAttributedString { get }

    var canChangeMethod: Bool { get }

    var needQRLogin: Bool { get }

    var switchButtonText: String { get }

    var pageName: String { get }

    var needPolicyCheckbox: Bool { get }

    var needBottomView: Bool { get }

    var needJoinMeetingView: Bool { get }

    var bottomActions: BottomAction { get }

    // 是否需要显示一键登录
    var needOneKeyLogin: Bool { get }

    var needSubtitle: Bool { get }

    // 提示富文本
    var needProcessTipLabel: Bool { get }

    var needLocaleButton: Bool { get }

    var needKeepLoginTip: Bool { get }

    var keepLoginText: NSAttributedString { get }

    var credentialInputList: [V4CredentialInputInfo] { get }

    var topCountryList: [String] { get }

    var allowRegionList: [String] { get }
    
    var blockRegionList: [String] { get }

    var joinTeamInFeishu: Bool { get }

    var tenantUnitDomain: String? { get }

    var regionCodeValid: BehaviorRelay<Bool> { get }

    func cleanTokenIfNeeded()

    func revertEnvIfNeeded()

    func handleSwitchAction() -> Observable<Void>

    var tenantBrand: TenantBrand? { get }
}
