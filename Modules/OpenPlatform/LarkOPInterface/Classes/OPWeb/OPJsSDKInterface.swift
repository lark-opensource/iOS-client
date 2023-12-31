//  code from yinhao@bytedance.com
@objc
public protocol OPJsSDKImplProtocol {
    // TODO: 这里要改造成 uniqueID
    var appId: String { get }
    var url: String { get }
    var authSession: String { get }
    var authModel: AnyObject? { get }
    var authStorage: AnyObject? { get }
    func evaluateJavaScript(script: String, completion: ((Any?, Error?) -> Void)?)
    func callbackConfig(response: [AnyHashable: Any], webTrace: OPTrace)
}
