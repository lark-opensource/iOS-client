//
//  ByteViewCalendarNavigator.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/21.
//

import Foundation
import ByteViewCommon
import EENavigator
import LarkContainer
import LarkNavigator
import LarkSetting
import LarkAppLinkSDK

public struct OpenCalendarLiveByLinkBody: CodablePlainBody {
    public static let path: String = "/client/livestudio/open"
    public static let pattern: String = "/\(path)"

    public let source: Source
    public let action: Action
    public let id: String
    public let no: String?

    public init(source: Source, action: Action, id: String, no: String?) {
        self.source = source
        self.action = action
        self.id = id
        self.no = no
    }

    public enum Source: String, Codable {
        case calendar
        case interview
        case live
    }

    public enum Action: String, Codable {
        case join
        case start_live
    }
}

class OpenCalendarLiveByLinkHandler: UserTypedRouterHandler {
    func handle(_ body: OpenCalendarLiveByLinkBody, req: EENavigator.Request, res: Response) {
        do {
            let resolver = self.userResolver
            let fg = try resolver.resolve(assert: FeatureGatingService.self)
            // 日历直播拦截页面是否显示升级按钮
            let showUpgrade = fg.staticFeatureGatingValue(with: "byteview.meeting.ios.live.tab")
            let onUpgrade: (UIViewController) -> Void = {
                if let dependency = try? resolver.resolve(assert: ByteViewCalendarDependency.self) {
                    dependency.gotoUpgrade(from: $0)
                }
            }
            res.end(resource: CalendarLiveInterceptionViewController(showUpgrade: showUpgrade, onUpgrade: onUpgrade))
        } catch {
            res.end(error: error)
        }
    }
}

final class OpenCalendarLiveLinkHandler {
    private static let logger = Logger.getLogger("AppLink")

    func handle(appLink: AppLink) {
        guard let from = appLink.context?.from() else {
            Self.logger.error("applink.context.from is nil")
            return
        }
        let queryParameters = appLink.url.queryParameters
        Self.logger.info("handle applink queryParameters = \(queryParameters)")

        let source = queryParameters["source"]
        let action = queryParameters["action"]
        let id = queryParameters["id"]
        let no = queryParameters["no"]
        guard let s = source, let sourceParam = OpenCalendarLiveByLinkBody.Source(rawValue: s),
              let a = action, let actionParam = OpenCalendarLiveByLinkBody.Action(rawValue: a),
              let idParam = id else {
            Self.logger.error("handle applink error by unsupported param: source = \(String(describing: source)), action = \(String(describing: action)), id = \(String(describing: id))")
            return
        }

        let body = OpenCalendarLiveByLinkBody(source: sourceParam, action: actionParam, id: idParam, no: no)
        Container.shared.getCurrentUserResolver().navigator.push(body: body, from: from)
    }
}
