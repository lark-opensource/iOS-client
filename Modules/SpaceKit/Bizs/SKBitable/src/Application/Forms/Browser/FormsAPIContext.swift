import LKCommonsLogging
import OPFoundation
import WebBrowser

// 开放平台历史债务，代码层面还没把应用身份完全和 API 剥离开，但不影响调用
public final class FormsAPIContext: NSObject, OPAPIContextProtocol {
    
    static let logger = Logger.formsWebLog(FormsAPIContext.self, category: "FormsAPIContext")
    
    weak var browser: WebBrowser?
    
    public init(browser: WebBrowser) {
        super.init()
        Self.logger.info("FormsAPIContext init")
        self.browser = browser
    }
    
    deinit {
        Self.logger.info("FormsAPIContext deinit")
    }
    
    public var uniqueID: OPAppUniqueID = OPAppUniqueID(
        appID: "", // 开放平台历史债务，API 框架还没能完全和应用关系以及业务解耦
        identifier: nil,
        versionType: .current,
        appType: .webApp
    )
    
    public var session: String = ""
    
    public var controller: UIViewController? {
        browser
    }
    
    public func fireEvent(
        event: String,
        sourceID: Int,
        data: [AnyHashable : Any]?
    ) -> Bool {
        false
    }
    
}
