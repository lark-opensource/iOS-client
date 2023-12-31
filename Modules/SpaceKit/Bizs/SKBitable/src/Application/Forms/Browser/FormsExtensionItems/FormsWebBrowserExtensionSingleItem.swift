import ECOProbe
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkWebViewContainer
import LKCommonsLogging
import WebBrowser

final public class FormsWebBrowserExtensionSingleItem: WebBrowserExtensionSingleItemProtocol {
    
    static let logger = Logger.formsWebLog(FormsWebBrowserExtensionSingleItem.self, category: "FormsWebBrowserExtensionSingleItem")
    
    public init() {
        Self.logger.info("FormsWebBrowserExtensionSingleItem init")
    }
    
    deinit {
        Self.logger.info("FormsWebBrowserExtensionSingleItem deinit")
    }
    
    public lazy var callAPIDelegate: WebBrowserCallAPIProtocol? = FormsWebBrowserCallAPI()
    
}

final public class FormsWebBrowserCallAPI: WebBrowserCallAPIProtocol {
    
    static let logger = Logger.formsWebLog(FormsWebBrowserCallAPI.self, category: "FormsWebBrowserCallAPI")
    
    public init() {
        Self.logger.info("FormsWebBrowserCallAPI init")
    }
    
    deinit {
        Self.logger.info("FormsWebBrowserCallAPI deinit")
    }
    
    lazy var pm = OpenPluginManager(
        bizDomain: .openPlatform,
        bizType: .webApp,
        bizScene: "" // 开放平台历史债务，API 框架还没能完全和应用关系以及业务解耦
    )
    
    public func recieveAPICall(
        webBrowser: WebBrowser,
        message: LarkWebViewContainer.APIMessage,
        callback: LarkWebViewContainer.APICallbackProtocol
    ) {
        
        Self.logger.info("FormsWebBrowserCallAPI recieveAPICall, apiName is \(message.apiName)")
        
        // 由于非技术原因，目前这里先维持
        let additionalInfo: [AnyHashable: Any] = [
            "gadgetContext": FormsAPIContext(browser: webBrowser)
        ]
        let context = OpenAPIContext(
            trace: OPTraceService
                .default()
                .generateTrace(),
            dispatcher: pm,
            additionalInfo: additionalInfo
        )
        
        pm
            .asyncCall(
                apiName: message.apiName,
                params: message.data,
                canUseInternalAPI: true,
                context: context
            ) { response in
                
                switch response {
                    
                case let .failure(error: error):
                    
                    var data = error.additionalInfo
                    data["errMsg"] = "\(error.outerMessage ?? error.code.errMsg) \(data["errMsg"] ?? "")"
                    if data["errCode"] == nil {
                        data["errCode"] = error.outerCode ?? error.code.rawValue
                    }
                    data.merge(error.errnoInfo, uniquingKeysWith: {$1})
                    
                    if let data = data as? [String: Any] {
                        callback.callbackFailure(param: data)
                    } else {
                        callback.callbackFailure()
                    }
                    
                case let .success(data: result):
                    
                    if let res = result?.toJSONDict() as? [String: Any] {
                        callback.callbackSuccess(param: res)
                    } else {
                        callback.callbackSuccess()
                    }
                    
                case let .continue(event: event, data: data):
                    assertionFailure("should not enter here")
                    
                }
                
            }
    }
    
}
