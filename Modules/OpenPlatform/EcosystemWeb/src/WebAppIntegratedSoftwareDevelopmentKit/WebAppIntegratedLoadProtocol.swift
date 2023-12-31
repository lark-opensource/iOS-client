import WebBrowser
@available(*, deprecated, message: "use fetchWebAppBrowser")
public protocol WebAppIntegratedLoadProtocol: AnyObject {
    /// Invoked when web applocation start load .
    /// - Parameters:
    ///  - browser: he browser invoking the delegate method.
    ///  - appID: web app id.
    func webAppIntegratedDidStartLoad(browser: WebBrowser, appID: String)
    /// Invoked when web applocation finish load .
    /// - Parameters:
    ///  - browser: he browser invoking the delegate method.
    ///  - appID: web app id.
    func webAppIntegratedDidFinishLoad(browser: WebBrowser, appID: String)
    /// Invoked when web app load failed.
    /// - Parameters:
    ///  - browser: he browser invoking the delegate method.
    ///  - error: The error that occurred.
    func webAppIntegratedDidFailLoad(browser: WebBrowser, error: Error)
}

public extension WebAppIntegratedLoadProtocol {
    func webAppIntegratedDidStartLoad(browser: WebBrowser, appID: String) {}
    func webAppIntegratedDidFinishLoad(browser: WebBrowser, appID: String) {}
    func webAppIntegratedDidFailLoad(browser: WebBrowser, error: Error) {}
}
