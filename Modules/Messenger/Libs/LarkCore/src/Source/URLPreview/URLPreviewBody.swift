//
//  URLPreviewBody.swift
//  LarkCore
//
//  Created by 袁平 on 2021/5/6.
//

import Foundation
import EENavigator
import LarkNavigator
import TangramService
import UniverseDesignToast
import LarkEMM
import LarkSensitivityControl

struct URLPreviewBody: CodableBody {
    private static let prefix = "//client/core/copy"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: prefix, type: .path)
    }

    public var _url: URL {
        return URL(string: Self.prefix) ?? .init(fileURLWithPath: "")
    }

    public init() {}
}

final class URLPreviewHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { URLPreview.userScopeCompatibleMode }

    func handle(_ body: URLPreviewBody, req: EENavigator.Request, res: Response) throws {
        if let copy = req.parameters["value"] as? String {
            let config = PasteboardConfig(token: Token("LARK-PSDA-url_preview_copy_handler"))
            do {
                try SCPasteboard.generalUnsafe(config).string = copy
                if let view = req.from.fromViewController?.view {
                    UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_JssdkCopySuccess, on: view)
                }
            } catch {
                // 复制失败兜底逻辑
                if let view = req.from.fromViewController?.view {
                    UDToast.showFailure(with: BundleI18n.LarkCore.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
                }
            }
        }
        res.end(resource: EmptyResource())
    }
}
