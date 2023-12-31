//
//  URL.swift
//  LarkCompatible
//
//  Created by qihongye on 2020/1/10.
//

import Foundation

/**
 * RFC reference
 * https://tools.ietf.org/html/rfc2396
 * Implemation reference
 * https://github.com/chromium/chromium/blob/b14132f4626815ce550b423c6bb56e60d39b8919/third_party/libxml/src/uri.c
 */
// swiftlint:disable identifier_name
private let MAX_URI_LENGTH = 1024 * 1024
// swiftlint:enable identifier_name

public enum URIError: Error {
    case outOfMaxLength
    case createUTF8StringFailed
    case createURLFailed
    case nullInputURIString
    case parseOutOfBounds(String)
    case parseError(String)

    var localizedDescription: String {
        switch self {
        case .outOfMaxLength:
            return "Out of max uri length(\(MAX_URI_LENGTH))"
        case .createUTF8StringFailed:
            return "Can not create utf8 string from uint8 array."
        case .createURLFailed:
            return "Invalid input url string, can not create URL from string."
        case .nullInputURIString:
            return "Input uri string is null."
        case .parseOutOfBounds(let method):
            return "Index out of string bounds when parse\(method)"
        case .parseError(let err):
            return "Parse uri error: {\(err)}"
        }
    }
}

extension URL {
    /// forceCreateURL
    ///   create URL object anyway.
    /// - Parameter string: url string
    ///   Returns URL: swift URL object
    ///   throws URIError
    ///   Performance about 4 times as much as URL.init(string:) cost
    public static func forceCreateURL(string: String) throws -> URL {
        if let url = URL(string: string) {
            return url
        }
        return try createURL3986(string: string)
    }

    public static func createURL3986(string: String) throws -> URL {
           let uriPtr = createURIPtr(decodeURI(string: string))
           if uriPtr.count > MAX_URI_LENGTH {
               throw URIError.outOfMaxLength
           }
           switch parseURI(uriPtr) {
           case .error(let error):
               throw error
           case .ok(let uri):
               guard let urlStr = String(bytes: uri.validURI(), encoding: .utf8) else {
                   throw URIError.createUTF8StringFailed
               }
               guard let url = URL(string: urlStr) else {
                   throw URIError.createURLFailed
               }
               return url
           }
    }

    /// decodeURI
    /// process more than one times uri encoding string.
    /// decodeURI("%253A%25F0%259F%2598%2584%25E5%2593%2588%25E3%2582%258D%25E3%2583%25AD") == "😄哈ろロ"
    /// - Parameter string: url string with uri encoding, such as %25%25, %253A%25F0%259F%2598%2584%25E5%2593%2588%25E3%2582%258D%25E3%2583%25AD
    ///   Returns url string with uri decoding
    public static func decodeURI(string: String) -> String {
        let uriPtr = createURIPtr(string)
        let unescape = uriUnescape(uriPtr, 0, uriPtr.count)
        return String(bytes: unescape, encoding: .utf8) ?? string
    }
}

@inline(__always)
func createURIPtr(_ str: String) -> URICharPtr {
    return Array(str.utf8)
}
