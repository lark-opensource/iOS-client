import Foundation

extension NSMutableURLRequest {
    /// 同步 HTTPCookieStorage 的 Cookie 到 NSMutableURLRequest 中
    func syncRequestCookie() {
        guard let url = url else { return }
        guard let cookieArray = HTTPCookieStorage.shared.cookies(for: url) else { return }
        let headerFields = HTTPCookie.requestHeaderFields(with: cookieArray)
        guard let cookieString = headerFields["Cookie"] else { return }
        setValue(cookieString, forHTTPHeaderField: "Cookie")
    }
}
