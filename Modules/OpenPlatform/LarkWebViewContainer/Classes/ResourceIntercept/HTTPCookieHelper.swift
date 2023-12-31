import Foundation
extension HTTPCookie {
    public func rfc_265_validFor(host: String) -> Bool {
        guard domain.hasPrefix(".") else { return host == domain }
        return host == domain.dropFirst() || host.hasSuffix(domain)
    }
}
