import ECOProbe
import LarkWebViewContainer
import LKCommonsLogging
import WebBrowser

// Forms SDK 对接方多，按照不同类型代码做个 log 区分

private let formsWebLogLogCategoryPrefix = "formsWeb."

private let formsBaseLogLogCategoryPrefix = "formsBase."

private let formsSDKLogLogCategoryPrefix = "formsSDK."

extension Logger {
    
    public class func formsWebLog(_ type: Any, category: String = "") -> Log {
        webBrowserLog(type, category: formsWebLogLogCategoryPrefix + category)
    }
    
    public class func formsBaseLog(_ type: Any, category: String = "") -> Log {
        lkwlog(type, category: formsBaseLogLogCategoryPrefix + category)
    }
    
    public class func formsSDKLog(_ type: Any, category: String = "") -> Log {
        oplog(type, category: formsSDKLogLogCategoryPrefix + category)
    }
    
}
