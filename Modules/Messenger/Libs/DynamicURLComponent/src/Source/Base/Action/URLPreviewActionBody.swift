//
//  URLPreviewActionBody.swift
//  LarkCore
//
//  Created by 袁平 on 2021/5/6.
//

import Foundation
import LarkModel
import EENavigator
import LarkNavigator
import TangramService
import LKCommonsLogging

public struct URLPreviewActionBody: CodableBody {
    public static let actionIDKey: String = "actionID"
    public static let stateIDKey: String = "stateID"
    public static let dependencyKey: String = "componentActionDependency"
    public static let entityKey: String = "entityKey"

    private static let prefix = "//client/preview/action"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: prefix, type: .path)
    }

    public var _url: URL {
        return URL(string: Self.prefix) ?? .init(fileURLWithPath: "")
    }

    public init() {}
}

final class URLPreviewActionHandler: UserTypedRouterHandler {
    static let logger = Logger.log(URLPreviewActionHandler.self, category: "LarkCore.URLPreviewActionHandler")
    static func compatibleMode() -> Bool { URLPreview.userScopeCompatibleMode }

    func handle(_ body: URLPreviewActionBody, req: EENavigator.Request, res: Response) throws {
        let actionID = req.parameters[URLPreviewActionBody.actionIDKey] as? String
        let stateID = req.context[URLPreviewActionBody.stateIDKey] as? String
        let dependency = req.context[URLPreviewActionBody.dependencyKey] as? URLCardDependency
        let entity = req.context[URLPreviewActionBody.entityKey] as? URLPreviewEntity
        guard let actionID = actionID, let stateID = stateID, let dependency = dependency else {
            assertionFailure("invalidate params")
            Self.logger.error("invalidate params, actionID = \(actionID) -> stateID = \(stateID)")
            return
        }
        guard let action = entity?.previewBody?.states[stateID]?.actions[actionID] else {
            Self.logger.error("none action, actionID = \(actionID) -> stateID = \(stateID)")
            return
        }
        ComponentActionRegistry.handleAction(entity: entity, action: action, actionID: actionID, dependency: dependency, completion: nil)
        res.end(resource: EmptyResource())
    }
}
