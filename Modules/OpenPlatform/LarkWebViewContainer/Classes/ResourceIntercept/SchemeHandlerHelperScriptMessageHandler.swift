import ECOInfra
import LKCommonsLogging
import WebKit
final class SchemeHandlerHelperScriptMessageHandler: NSObject, WKScriptMessageHandler {
    static let logger = Logger.lkwlog(SchemeHandlerHelperScriptMessageHandler.self, category: "SchemeHandlerHelperScriptMessageHandler")
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard JSONSerialization.isValidJSONObject(message.body) else {
            Self.logger.error("message.body is not vaild json object")
            return
        }
        let fixRequestMessage: FixRequestMessage
        do {
            fixRequestMessage = try JSONDecoder().decode(FixRequestMessage.self, from: try JSONSerialization.data(withJSONObject: message.body))
        } catch {
            Self.logger.error("build fixRequest message error", error: error)
            return
        }
        guard fixRequestMessage.apiName == "fixRequest" else {
            Self.logger.error("fixRequestMessage.apiName is not fixRequest")
            return
        }
        FixRequestManager.shared.setFixRequestData(with: fixRequestMessage.data.id, fixRequestData: fixRequestMessage.data)
        do {
            let jsStr = try buildCallBackJavaScriptString(
                callbackID: fixRequestMessage.callbackID,
                params: [
                    "id": fixRequestMessage.data.id
                ]
            )
            guard let webView = message.webView else {
                return
            }
            webView.evaluateJavaScript(jsStr)
        } catch {
            Self.logger.error("fixRequestMessage.apiName is not fixRequest")
            return
        }
    }
    private func defaultBuildAPIMessage(with body: Any) throws -> APIMessage {
        guard let messageBody = body as? [AnyHashable: Any] else {
            throw OPError.error(monitorCode: BridgeMonitorCode.buildApiMessageFailed, message: "invaild jsmessage body, is not [AnyHashable: Any]")
        }
        guard let apiName = messageBody[APIMessageKey.apiName.rawValue] as? String else {
            throw OPError.error(monitorCode: BridgeMonitorCode.buildApiMessageFailed, message: "invaild jsmessage body, apiName invaild")
        }
        return APIMessage(
            apiName: apiName,
            data: messageBody[APIMessageKey.data.rawValue] as? [String: Any] ?? [String: Any](),
            callbackID: messageBody[APIMessageKey.callbackID.rawValue] as? String,
            extra: messageBody[APIMessageKey.extra.rawValue] as? [AnyHashable: Any]
        )
    }
    private func buildCallBackJavaScriptString(
        callbackID: String,
        params: [AnyHashable: Any]
    ) throws -> String {
        let finalMap: [AnyHashable: Any] = [
            APIMessageKey.callbackID.rawValue: callbackID,
            APIMessageKey.data.rawValue: params,
            APIMessageKey.callbackType.rawValue: CallBackType.success.rawValue
        ]
        guard JSONSerialization.isValidJSONObject(finalMap) else {
            let e = OPError.error(monitorCode: BridgeMonitorCode.buildJsStringFailed)
            assertionFailure(e.description)
            throw e
        }
        let data = try JSONSerialization.data(withJSONObject: finalMap)
        let str = String(data: data, encoding: .utf8) ?? ""
        let jsStr = "SchemeHandlerHelper.callback(\(str))"
        return jsStr
    }
}
