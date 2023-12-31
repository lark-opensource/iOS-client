//
//  URL+Cookie.swift
//
//  Created by Songwen Ding on 2017/11/30.
//

import Foundation

extension URL {
    func cookiePreperties(value: String, forName name: String) -> [HTTPCookiePropertyKey: Any] {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .path: "/", // self.path,
            .expires: Date(timeIntervalSinceNow: 24 * 60 * 60 * 365),
            .originURL: self,
            // .maximumAge
            // .discard
            .version: "0"
            // .comment
            ] as [HTTPCookiePropertyKey: Any]
        if let host = self.host { properties[.domain] = host }
        if let port = self.port { properties[.port] = port }
        return properties
    }

    func cookie(value: String, forName name: String) -> HTTPCookie? {
        let properties = self.cookiePreperties(value: value, forName: name)
        return HTTPCookie(properties: properties)
    }
}
