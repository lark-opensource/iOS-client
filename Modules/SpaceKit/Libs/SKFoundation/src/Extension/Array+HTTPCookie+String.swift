import Foundation

extension Array where Element: HTTPCookie {
    public var cookieString: String {
        return self.map({ (cookie) -> String in
            return "\(cookie.name)=\(cookie.value)"
        }).joined(separator: ";")
    }
}
