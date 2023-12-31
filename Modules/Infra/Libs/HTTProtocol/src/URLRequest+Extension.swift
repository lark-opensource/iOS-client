//
//  URLRequest+Extension.swift
//  HTTProtocol
//
//  Created by SolaWing on 2019/7/17.
//

import Foundation

extension URLRequest {
    // swiftlint:disable:next missing_docs
    public func canonicalHTTPRequest() -> URLRequest {
        guard let url = self.url, let finalURL = url.canonical() else {
            return self
        }

        var request = self
        request.url = finalURL

        // canonical mainDocumentURL
        if let mainDocumentURL = self.mainDocumentURL {
            if url == mainDocumentURL {
                request.mainDocumentURL = finalURL
            } else if let mainDocumentURL = mainDocumentURL.canonical(allowNonHTTP: true) {
                request.mainDocumentURL = mainDocumentURL
            }
        }
        request.canonicalizeHttpHeader()
        return request
    }
    private mutating func canonicalizeHttpHeader() {
        if let method = self.httpMethod?.uppercased() {
            self.httpMethod = method // method use UPPER case version
            if
                method == "POST"
                    && self.value(forHTTPHeaderField: "Content-Type") == nil
                    && (self.httpBody != nil || self.httpBodyStream != nil)
            { // default POST contentType if none
                self.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
            // 尽量加上Content-Length, 虽然URLSession只会传stream
            if let body = self.httpBody, self.value(forHTTPHeaderField: "Content-Length") == nil, !body.isEmpty {
                self.setValue(body.count.description, forHTTPHeaderField: "Content-Length")
            }
        }
        if self.value(forHTTPHeaderField: "Accept") == nil { // default Accept header
            self.setValue("*/*", forHTTPHeaderField: "Accept")
        }
        // rust现在只支持gzip, 忽略其它设置
        self.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        if self.value(forHTTPHeaderField: "Accept-Language") == nil {
            // default Accept-Language header.
            self.setValue(Locale.preferredLanguages.first ?? "en-us", forHTTPHeaderField: "Accept-Language")
        }
    }
}
