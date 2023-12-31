import WebKit
private var globalSchemes = Set<String>()
extension WKWebView {
    static private var changed = false
    static func schemeHandlerSupport(schemes: Set<String>) {
        globalSchemes = globalSchemes.union(schemes)
        if !changed {
            switchHandlesURLSchemeMethod()
            changed = true
        }
    }
    private static func switchHandlesURLSchemeMethod() {
        if
            case let cls = WKWebView.self,
            let m1 = class_getClassMethod(cls, NSSelectorFromString("handlesURLScheme:")),
            let m2 = class_getClassMethod(cls, #selector(WKWebView.changedHandlesURLScheme(urlScheme:)))
        {
            method_exchangeImplementations(m1, m2)
        }
    }
    @objc dynamic private static func changedHandlesURLScheme(urlScheme: String) -> Bool {
        if globalSchemes.contains(urlScheme) { return false }
        return self.changedHandlesURLScheme(urlScheme: urlScheme)
    }
}
