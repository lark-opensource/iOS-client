//
//  V3InputCredentailViewModelProtocol.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/3/12.
//

import Foundation
import RxSwift

struct BottomAction: OptionSet, Codable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = BottomAction([])
    public static let enterpriseLogin = BottomAction(rawValue: 1)
    public static let joinTeam = BottomAction(rawValue: 1 << 1)
    public static let both = BottomAction(rawValue: 3)
}

protocol V3InputCredentailViewModelProtocol {
    var title: String { get }

    var subtitle: String { get }

    var processTip: NSAttributedString { get }

    var canChangeMethod: Bool { get }

    var needQRLogin: Bool { get }

    var switchButtonText: String { get }

    var pageName: String { get }

    var needPolicyCheckbox: Bool { get }

    var needCIdpView: Bool { get }

    var needBIdpView: Bool { get }

    var needBottomView: Bool { get }

    var needRegisterView: Bool { get }

    var supportLoginMethods: [SuiteLoginMethod] { get }

    var enableDirectOpenIDPPage: Bool { get }

    var bottomActions: BottomAction { get }

    // 是否需要显示一键登录
    var needOnekeyLogin: Bool { get }

    var needSubtitle: Bool { get }

    // 提示富文本
    var needProcessTipLabel: Bool { get }

    var needLocaleButton: Bool { get }

    var needKeepLoginTip: Bool { get }

    var keepLoginText: NSAttributedString { get }

    func cleanTokenIfNeeded()

    func revertEnvIfNeeded()

    func handleSwitchAction() -> Observable<Void>
}
