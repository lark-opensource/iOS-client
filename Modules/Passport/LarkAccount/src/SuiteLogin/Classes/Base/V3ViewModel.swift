//
//  V3ViewModel.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/23.
//

import Foundation
import LKCommonsLogging
import RxSwift
import LarkContainer

class V3ViewModel {

    static let logger = Logger.plog(V3ViewModel.self, category: "SuiteLogin.V3ViewModel")

    // MARK: server step

    let step: String
    let stepInfo: ServerInfo
    @Provider var service: V3LoginService
    var passportEventBus: PassportEventBusProtocol { LoginPassportEventBus.shared }
    var additionalInfo: Codable?
    let context: UniContextProtocol

    /// current track path https://bytedance.feishu.cn/docs/doccntF307vMkCamErsvVhSJ7ub#cO3O8O
    var trackPath: String {
        guard let track = additionalInfo as? V3TrackPathProtocol else {
            return TrackConst.defaultPath
        }
        return track.path
    }

    init(
        step: String,
        stepInfo: ServerInfo,
        context: UniContextProtocol
    ) {
        self.step = step
        self.stepInfo = stepInfo
        self.context = context
    }

    // MARK: Common
    func post(
        event: String,
        stepInfo: [String: Any]? = nil,
        additionalInfo: Codable? = nil,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler
        ) {
        passportEventBus.post(
            event: event,
            context: V3RawLoginContext(stepInfo: stepInfo, additionalInfo: additionalInfo, context: context),
            success: success,
            error: error)
    }

    func post(
        event: String,
        serverInfo: Codable?,
        additionalInfo: Codable? = nil,
        context: UniContext? = nil,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler
    ) {
        passportEventBus.post(
            event: event,
            context: V3LoginContext(serverInfo: serverInfo, additionalInfo: additionalInfo, context: context),
            success: success,
            error: error
        )
    }

    /// only KA-R use
    static func post(
        event: String,
        stepInfo: [String: Any]?,
        additionalInfo: Codable?,
        context: UniContextProtocol,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler
    ) {
        LoginPassportEventBus.shared.post(
            event: event,
            context: V3RawLoginContext(stepInfo: stepInfo, additionalInfo: additionalInfo, context: context),
            success: success,
            error: error
        )
    }

    func clickClose() { }
}

extension V3ViewModel {
    func attributedString(
        for subtitle: String?,
        _ foregroundColor: UIColor = UIColor.ud.textCaption,
        _ font: UIFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    ) -> NSAttributedString {
        Self.attributedString(for: subtitle, foregroundColor, font)
    }

    static func attributedString(
        for subtitle: String?,
        _ foregroundColor: UIColor = UIColor.ud.textCaption,
        _ font: UIFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    ) -> NSAttributedString {
        if let subtitle = subtitle {
            return subtitle.html2Attributed(font: font, forgroundColor: foregroundColor)
        }
        return NSAttributedString(string: "")
    }
}
