import WebKit
extension URLRequest {
    mutating public func setwk(cookies: [HTTPCookie]) {
        if let urlHost = url?.host?.lowercased() {
            let validCookies = cookies.filter { $0.rfc_265_validFor(host: urlHost) }
            let headerFields = HTTPCookie.requestHeaderFields(with: validCookies)
            if let cookieString = headerFields["Cookie"] {
                setValue(cookieString, forHTTPHeaderField: "Cookie")
            }
        }
    }
    mutating func tryFixRequest() {
        if let u = url, u.hasResourceID() {
            let resourceIDAndURL = u.parseURLResourceID()
            if let resourceID = resourceIDAndURL.0 {
                if httpMethod != "GET", httpMethod != "OPTIONS", httpMethod != "HEAD", let fixRequestData = FixRequestManager.shared.fixRequestData(with: resourceID) {
                    if let headers = fixRequestData.headers {
                        for header in headers {
                            let method = header.method ?? .replace
                            switch method {
                            case .replace:
                                setValue(header.value, forHTTPHeaderField: header.key)
                            case .append:
                                addValue(header.value, forHTTPHeaderField: header.key)
                            case .delete:
                                allHTTPHeaderFields?[header.key] = nil
                            }
                        }
                    }
                    if let base64Body = fixRequestData.base64Body, let bodyData = base64Body.base64ByJSToData() {
                        httpBody = bodyData
                    }
                }
                url = resourceIDAndURL.1
            }
        }
    }
}
