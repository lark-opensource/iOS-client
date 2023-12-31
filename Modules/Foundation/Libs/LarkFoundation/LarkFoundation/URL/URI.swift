//
//  URI.swift
//  LarkFoundation
//
//  Created by qihongye on 2020/1/15.
//

import Foundation

struct URI {
    /* the URI scheme */
    var schema = NULL_URICharPtr
    /* opaque part */
    var opaque = NULL_URICharPtr
    /* the authority part */
    var authority = NULL_URICharPtr
    /* the server part */
    var server = NULL_URICharPtr
    /* the user part */
    var user = NULL_URICharPtr
    /* the port number */
    var port: Int32 = -1
    /* the path string */
    var path = NULL_URICharPtr
    /* the query string (deprecated - use with caution) */
    var query = NULL_URICharPtr
    /* the fragment identifier */
    var fragment = NULL_URICharPtr
    /* parsing potentially unclean URI */
    var cleanup = 1

    init() { }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    @inline(__always)
    func validURI() -> URICharPtr {
        var uriPtr = NULL_URICharPtr

        if !isNullURICharPtr(schema) {
            /// schema + :
            uriPtr += schema + Letter.colon
        } else {
            /// https, fix https://meego.feishu.cn/larksuite/issue/detail/12767723, default use https is more safty.
            uriPtr += [104, 116, 116, 112, 115, Letter.colon] // nolint: magic number
        }
        if !isNullURICharPtr(opaque) {
            for char in opaque {
                if isReserved(char) || isUnreserved(char) {
                    uriPtr += char
                } else {
                    uriPtr += encodeURI(char)
                }
            }
        } else {
            if !isNullURICharPtr(server) || port == -1 {
                /// urlPtr + //
                uriPtr += [Letter.slash, Letter.slash]

                if !isNullURICharPtr(user) {
                    for char in user {
                        if isUnreserved(char) ||
                            char == Letter.semicolon || char == Letter.colon ||
                            char == Letter.apersand || char == Letter.equals ||
                            char == Letter.plus || char == Letter.dollar ||
                            char == Letter.comma {
                            uriPtr += char
                        } else {
                            uriPtr += encodeURI(char)
                        }
                    }
                    /// uriPtr + @
                    uriPtr += Letter.at
                }
                if !isNullURICharPtr(server) {
                    uriPtr += server
                    if port > 0 {
                        /// uriPtr + : + port
                        uriPtr += Letter.colon + "\(port)"
                    }
                }
            } else if !isNullURICharPtr(authority) {
                /// uriPtr + //
                uriPtr += [Letter.slash, Letter.slash]
                for char in authority {
                    if isUnreserved(char) ||
                        char == Letter.dollar || char == Letter.comma || char == Letter.semicolon ||
                        char == Letter.colon || char == Letter.at || char == Letter.apersand ||
                        char == Letter.equals || char == Letter.plus {
                        uriPtr += char
                    } else {
                        uriPtr += encodeURI(char)
                    }
                }
            }
            if !isNullURICharPtr(path) {
                var curIdx = 0
                /**
                 * the colon in file:///d: should not be escaped or
                 * Windows accesses fail later.
                 */
                if path.count > 2 && !isNullURICharPtr(schema) &&
                    path[0] == Letter.slash && isAlpha(path[1]) && path[2] == Letter.colon &&
                    schema == "file" {
                    uriPtr += path.suffix(3)
                    curIdx = 3
                }
                for i in curIdx..<path.count {
                    let char = path[i]
                    if isUnreserved(char) || char == Letter.slash ||
                        char == Letter.semicolon || char == Letter.at || char == Letter.apersand ||
                        char == Letter.equals || char == Letter.plus || char == Letter.dollar ||
                        char == Letter.comma {
                        uriPtr += char
                    } else {
                        uriPtr += encodeURI(char)
                    }
                }
            }
            if !isNullURICharPtr(query) {
                /// uriPtr + ?
                uriPtr += Letter.question
                var isAfterEqual = false
                for char in query {
                    if isUnreserved(char) || isReserved(char) {
                        if isAfterEqual {
                            /// Query string after `=` need to repalce `+` to `space`(%20).
                            if char == Letter.plus {
                                uriPtr += [Letter.percent, Letter.num2, Letter.num0]
                            } else {
                                uriPtr += char
                            }
                        } else {
                            uriPtr += char
                        }
                        if !isAfterEqual, char == Letter.equals {
                            isAfterEqual = true
                        }
                    } else {
                        uriPtr += encodeURI(char)
                    }
                }
            }
        }
        if !isNullURICharPtr(fragment) {
            /// uriPtr + #
            uriPtr += Letter.number
            for char in fragment {
                if isUnreserved(char) || isReserved(char) {
                    uriPtr += char
                } else {
                    uriPtr += encodeURI(char)
                }
            }
        }

        return uriPtr
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length
}

enum ParseResult {
    case ok(URI)
    case error(URIError)
}

/**
 * parseURI:
 * @ptr:  the URI string to analyze
 *
 * Parse an URI based on RFC 3986
 *
 * URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]
 *
 * Returns ParseResult
 */
@inline(__always)
func parseURI(_ ptr: URICharPtr) -> ParseResult {
    if isNullURICharPtr(ptr) {
        return .error(.nullInputURIString)
    }
    var uri = URI()
    if let error = parse3986URIReference(&uri, ptr) {
        return .error(error)
    }
    return .ok(uri)
}

/**
 * parse3986URIReference:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 *
 * Parse an URI reference string and fills in the appropriate fields
 * of the @uri structure
 *
 * URI-reference = URI / relative-ref
 *
 * Returns URIError or NULL
 */
@inline(__always)
func parse3986URIReference(_ uri: inout URI, _ str: URICharPtr) -> URIError? {
    if prse3986URI(&uri, str) != nil {
        uri = URI()
        if let err = parse3986RelativeRef(&uri, str) {
            uri = URI()
            return err
        }
    }
    return nil
}

/**
 * parse3986URI:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 *
 * Parse an URI string and fills in the appropriate fields
 * of the @uri structure
 *
 * scheme ":" hier-part [ "?" query ] [ "#" fragment ]
 *
 * Returns 0 or the error code
 */
@inline(__always)
func prse3986URI(_ uri: inout URI, _ str: URICharPtr) -> URIError? {
    var idx = 0
    if let error = parse3986Schema(&uri, str, &idx) {
        return error
    }
    if str.get(idx) != Letter.colon {
        return .parseError("After schema is not \(Letter.colon).")
    }
    idx += 1
    if let error = parse3986HierPart(&uri, str, &idx) {
        return error
    }
    if str.get(idx) == Letter.question {
        idx += 1
        if let error = parse3986Query(&uri, str, &idx) {
            return error
        }
    }
    if str.get(idx) == Letter.number {
        idx += 1
        if let error = parse3986Fragment(&uri, str, &idx) {
            return error
        }
    }
    if idx < str.endIndex {
        return .parseError("Some characters at end of str that are not parse as fragment.")
    }
    return nil
}

/**
 * parse3986RelativeRef:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 *
 * Parse an URI string and fills in the appropriate fields
 * of the @uri structure
 *
 * relative-ref  = relative-part [ "?" query ] [ "#" fragment ]
 * relative-part = "//" authority path-abempty
 *               / path-absolute
 *               / path-noscheme
 *               / path-empty
 *
 * Returns URIError or NULL
 */
@inline(__always)
func parse3986RelativeRef(_ uri: inout URI, _ str: URICharPtr) -> URIError? {
    var idx = 0
    if str.get(idx) == Letter.slash && str.get(idx + 1) == Letter.slash {
        idx += 2
        if let error = parse3986Authority(&uri, str, &idx) {
            return error
        }
        if let error = parse3986PathAbEmpty(&uri, str, &idx) {
            return error
        }
    } else if str.get(idx) == Letter.slash {
        if let error = parse3986PathAbsolute(&uri, str, &idx) {
            return error
        }
    } else if isPChar(str, idx) {
        if let error = parse3986PathNoScheme(&uri, str, &idx) {
            return error
        }
    } else {
        /// path-empty is effectively empty
        uri.path = NULL_URICharPtr
    }
    if str.get(idx) == Letter.question {
        idx += 1
        if let error = parse3986Query(&uri, str, &idx) {
            return error
        }
    }
    if str.get(idx) == Letter.number {
        idx += 1
        if let error = parse3986Fragment(&uri, str, &idx) {
            return error
        }
    }
    if str.get(idx) != nil {
        uri = URI()
        return .parseError("RelativeRef is not end with nil.")
    }
    return nil
}

/**
 * parse3986Scheme:
 * @uri:  pointer to an URI structure
 * @str:  pointer to the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse an URI scheme
 *
 * ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
 *
 * Returns URIError or NULL
 */
func parse3986Schema(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    if idx >= str.endIndex {
        return .parseOutOfBounds("Schema")
    }
    var curIdx = idx
    var cur = str[curIdx]
    if !isAlpha(str[curIdx]) {
        return .parseError("Schema's first charactor if not alpha: \(cur).")
    }
    curIdx += 1
    if curIdx >= str.endIndex {
        return .parseOutOfBounds("Schema")
    }
    cur = str[curIdx]
    while isAlpha(cur) || isDigit(cur) ||
        cur == Letter.plus || cur == Letter.minus || cur == Letter.dot {
            curIdx += 1
            if curIdx >= str.endIndex {
                break
            }
            cur = str[curIdx]
    }
    curIdx = min(curIdx, str.endIndex)
    uri.schema = Array(str[idx..<curIdx])
    idx = curIdx

    return nil
}
/**
 * parse3986Query:
 * @uri:  pointer to an URI structure
 * @str:  pointer to the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse the query part of an URI
 *
 * query = *uric
 *
 * Returns URIError or NULL
 */
func parse3986Query(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var query = NULL_URICharPtr
    var curIdx = idx
    var cur = str.get(curIdx)
    while cur != nil && cur != Letter.number {
        let prevIdx = curIdx
        while isPChar(str, curIdx) || cur == Letter.slash || cur == Letter.question ||
            (uri.cleanup & 1 != 0 && isUnwise(cur)) {
            cur = next(str, &curIdx)
        }
        if curIdx <= str.endIndex, curIdx > prevIdx {
            query += Array(str[prevIdx..<curIdx])
        }
        if cur != nil && cur != Letter.number {
            query += uriUnescape(str, curIdx, 1)
            curIdx += 1
            cur = str.get(curIdx)
        }
    }
    if uri.cleanup & 2 != 0 {
        uri.query = query
    } else {
        uri.query = uriUnescape(query, 0, query.count)
    }
    idx = min(curIdx, str.endIndex)

    return nil
}

/**
 * parse3986Fragment:
 * @uri:  pointer to an URI structure
 * @str:  pointer to the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse the query part of an URI
 *
 * fragment      = *( pchar / "/" / "?" )
 * NOTE: the strict syntax as defined by 3986 does not allow '[' and ']'
 *       in the fragment identifier but this is used very broadly for
 *       xpointer scheme selection, so we are allowing it here to not break
 *       for example all the DocBook processing chains.
 *       Try to fix invalid char.
 *
 * Returns URIError or NULL *
 */
func parse3986Fragment(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    var fragment = NULL_URICharPtr
    while let cur = str.get(curIdx) {
        let prevIdx = curIdx
        while isPChar(str, curIdx) || cur == Letter.slash || cur == Letter.question ||
            cur == Letter.bracketsL || cur == Letter.bracketsR ||
            (uri.cleanup & 1 != 0 && isUnwise(cur)) {
            if next(str, &curIdx) == nil {
                break
            }
        }
        if curIdx <= str.endIndex, curIdx > prevIdx {
            fragment += Array(str[prevIdx..<curIdx])
        }
        /// try to fix inavalid char.
        if str.get(curIdx) != nil {
            fragment += uriUnescape(str, curIdx, 1)
            curIdx += 1
        }
    }
    curIdx = min(curIdx, str.endIndex)
    if uri.cleanup & 2 != 0 {
        uri.fragment = fragment
    } else {
        uri.fragment = uriUnescape(fragment, 0, fragment.count)
    }
    idx = curIdx

    return nil
}

/**
 * parse3986Authority:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse an authority part and fills in the appropriate fields
 * of the @uri structure
 *
 * authority     = [ userinfo "@" ] host [ ":" port ]
 *
 * Returns URLError or NULL
 */
func parse3986Authority(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    if parse3986Userinfo(&uri, str, &curIdx) != nil || str.get(curIdx) != Letter.at {
        curIdx = idx
    } else {
        curIdx += 1
    }
    if let error = parse3986Host(&uri, str, &curIdx) {
        return error
    }
    if str.get(curIdx) == Letter.colon {
        curIdx += 1
        if let error = parse3986Port(&uri, str, &curIdx) {
            return error
        }
    }
    idx = curIdx
    return nil
}

/**
 * parse3986Userinfo:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse an user informations part and fills in the appropriate fields
 * of the @uri structure
 *
 * userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
 *
 * Returns URIError or NULL
 */
func parse3986Userinfo(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    if idx >= str.endIndex {
        return .parseOutOfBounds("UserInfo")
    }
    var curIdx = idx
    var cur = str[curIdx]
    while isUnreserved(cur) || isPCTEncoded(str, curIdx) ||
        isSubDelim(cur) || cur == Letter.colon {
        // swiftlint:disable identifier_name
        if let _cur = next(str, &curIdx) {
            cur = _cur
        } else {
            break
        }
        // swiftlint:enable identifier_name

    }
    curIdx = min(curIdx, str.endIndex)
    if curIdx > idx, cur == Letter.at {
        if uri.cleanup & 2 != 0 {
            uri.user = Array(str[idx..<curIdx])
        } else {
            uri.user = uriUnescape(str, idx, curIdx - idx)
        }
        idx = curIdx
        return nil
    }
    return .parseError("After userinfo is not \(Letter.at).")
}

/**
 * parse3986Host:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse an host part and fills in the appropriate fields
 * of the @uri structure
 *
 * host          = IP-literal / IPv4address / reg-name
 * IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"
 * IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
 * reg-name      = *( unreserved / pct-encoded / sub-delims )
 *
 * Returns URIError or NULL
 */
func parse3986Host(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    enum State {
        case found
        case notIPv4
        case normal
    }
    var curIdx = idx
    var state: State = .normal
    while true {
        switch state {
        case .normal:
            /**
             * IPv6 and future adressing scheme are enclosed between brackets
             */
            if str.get(curIdx) == Letter.bracketsL {
                if curIdx + 1 >= str.endIndex {
                    return .parseError("Host parse start with \(Letter.bracketsL) but not end with \(Letter.bracketsR)")
                }
                curIdx += 1
                for i in curIdx..<str.endIndex {
                    curIdx = i
                    if str.get(curIdx) == Letter.bracketsR {
                        state = .found
                        curIdx += 1
                        break
                    }
                }
                if state == .found {
                    continue
                }
                return .parseError("Host parse start with \(Letter.bracketsL) but not end with \(Letter.bracketsR)")
            }
            /**
             * try to parse IPv4
             */
            if let cur = str.get(curIdx), isDigit(cur) {
                if parse3986DecOctet(str, &curIdx) != nil {
                    state = .notIPv4
                    continue
                }
                if str.get(curIdx) != Letter.dot {
                    state = .notIPv4
                    continue
                }
                curIdx += 1
                if parse3986DecOctet(str, &curIdx) != nil {
                    state = .notIPv4
                    continue
                }
                if str.get(curIdx) != Letter.dot {
                    state = .notIPv4
                    continue
                }
                curIdx += 1
                if parse3986DecOctet(str, &curIdx) != nil {
                    state = .notIPv4
                    continue
                }
                if str.get(curIdx) != Letter.dot {
                    state = .notIPv4
                    continue
                }
                curIdx += 1
                if parse3986DecOctet(str, &curIdx) != nil {
                    state = .notIPv4
                    continue
                }
                state = .found
                continue
            }
            fallthrough
        case .notIPv4:
            curIdx = idx
            /**
             * then this should be a hostname which can be empty
             */
            var cur = str.get(curIdx)!
            while isUnreserved(cur) || isPCTEncoded(str, curIdx) || isSubDelim(cur) {
                // swiftlint:disable identifier_name
                if let _cur = next(str, &curIdx) {
                    cur = _cur
                } else {
                    break
                }
                // swiftlint:enable identifier_name
            }
            fallthrough
        case .found:
            curIdx = min(curIdx, str.endIndex)
            if curIdx > idx {
                if uri.cleanup & 2 != 0 {
                    uri.server = Array(str[idx..<curIdx])
                } else {
                    uri.server = uriUnescape(str, idx, curIdx - idx)
                }
            } else {
                uri.server = NULL_URICharPtr
            }
            idx = curIdx
            return nil
        }
    }
}

/**
 * parse3986DecOctet:
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 *
 *    dec-octet     = DIGIT                 ; 0-9
 *                  / %x31-39 DIGIT         ; 10-99
 *                  / "1" 2DIGIT            ; 100-199
 *                  / "2" %x30-34 DIGIT     ; 200-249
 *                  / "25" %x30-35          ; 250-255
 *
 * Skip a dec-octet.
 *
 * Returns URIError or NULL
 */
func parse3986DecOctet(_ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    guard let cur = str.get(curIdx) else {
        return .parseOutOfBounds("DecOctet")
    }
    if !isDigit(cur) {
        return .parseError("At start of parseDecOctet is not a digit: \(cur)")
    }
    if curIdx + 1 < str.endIndex, !isDigit(str[curIdx + 1]) {
        curIdx += 1
    } else if curIdx + 2 < str.endIndex {
        if cur != Letter.num0 && isDigit(str[curIdx + 1]) && !isDigit(str[curIdx + 2]) {
            curIdx += 2
        } else if cur == Letter.num1 && isDigit(str[curIdx + 1]) && isDigit(str[curIdx + 2]) {
            curIdx += 3
        } else if cur == Letter.num2 && str[curIdx + 1] >= Letter.num0 &&
            str[curIdx + 1] <= Letter.num4 && isDigit(str[curIdx + 2]) {
            curIdx += 3
        } else if cur == Letter.num2 && str[curIdx + 1] == Letter.num5 &&
            str[curIdx + 2] >= Letter.num0 && str[curIdx + 1] <= Letter.num5 {
            curIdx += 3
        } else {
            return .parseError("parseDecOctet invalid.")
        }
    } else {
        return .parseError("parseDecOctet invalid.")
    }
    idx = curIdx
    return nil
}

/**
 * parse3986Port:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 *
 * Parse a port part and fills in the appropriate fields
 * of the @uri structure
 *
 * port          = *DIGIT
 *
 * Returns URIError or NULL
 */
func parse3986Port(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var port: Int32 = 0
    var curIdx = idx
    guard var cur = str.get(curIdx) else {
        return .parseOutOfBounds("Port")
    }
    if isDigit(cur) {
        while isDigit(cur) {
            port = port * 10 + Int32(cur - Letter.num0)
            curIdx += 1
            // swiftlint:disable identifier_name
            if let _cur = str.get(curIdx) {
                cur = _cur
            } else {
                break
            }
            // swiftlint:enable identifier_name
        }
        uri.port = port & Int32(UInt16.max)
        idx = curIdx
        return nil
    }
    uri.port = -1
    return .parseError("Port is not a digit: \(cur)")
}

/**
 * xmlParse3986PathAbEmpty:
 * @uri:  pointer to an URI structure
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 * Parse an path absolute or empty and fills in the appropriate fields
 * of the @uri structure
 *
 * path-abempty  = *( "/" segment )
 *
 * Returns URIError or NULL
 */
func parse3986PathAbEmpty(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    var path = NULL_URICharPtr
    var cur = str.get(curIdx)
    if cur != Letter.slash {
        return nil
    }
    path += Letter.slash
    curIdx += 1
    cur = str.get(curIdx)
    while cur != nil && cur != Letter.question && cur != Letter.number {
        let prevIdx = curIdx
        if let error = parse3986Segment(str, &curIdx, 0, true) {
            return error
        }
        if curIdx <= str.endIndex, curIdx > prevIdx {
            path += Array(str[prevIdx..<curIdx])
        }
        cur = str.get(curIdx)
        /// deal with invalid char
        if cur == Letter.slash {
            path += Letter.slash
            curIdx += 1
            cur = str.get(curIdx)
        } else if cur != nil, cur != Letter.question, cur != Letter.number {
            path += uriUnescape(str, curIdx, 1)
            curIdx += 1
            cur = str.get(curIdx)
        }
    }
    curIdx = min(curIdx, str.endIndex)
    uri.path = path
    idx = curIdx
    return nil
}

/**
 * parse3986Segment:
 * @str:  the string to analyze
 * @idx:  pointer to str current index
 * @forbid: an optional forbidden character
 * @empty: allow an empty segment
 *
 * Parse a segment and fills in the appropriate fields
 * of the @uri structure
 *
 * segment       = *pchar
 * segment-nz    = 1*pchar
 * segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
 *               ; non-zero-length segment without any colon ":"
 *
 * Returns URIError or NULL
 */
func parse3986Segment(_ str: URICharPtr, _ idx: inout Int, _ forbid: URIChar, _ empty: Bool) -> URIError? {
    var curIdx = idx
    if !isPChar(str, curIdx) {
        if empty {
            return nil
        }
        return .parseError("Segment error without allow empty segment.")
    }
    while isPChar(str, curIdx) && str.get(curIdx) != forbid {
        if next(str, &curIdx) == nil {
            break
        }
    }
    idx = curIdx
    return nil
}

/**
 * parse3986PathAbsolute
 * @uri:  pointer to an URI structure
 * @idx:  pointer to str current index
 * @str:  the string to analyze
 *
 * Parse an path absolute and fills in the appropriate fields
 * of the @uri structure
 *
 * path-absolute = "/" [ segment-nz *( "/" segment ) ]
 *
 * Returns URIError or NULL
 */
func parse3986PathAbsolute(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    if str.get(curIdx) != Letter.slash {
        return .parseError("PathAbsolute is not start with \(Letter.slash).")
    }
    curIdx += 1
    if parse3986Segment(str, &curIdx, 0, false) == nil {
        while str.get(curIdx) == Letter.slash {
            curIdx += 1
            if let error = parse3986Segment(str, &curIdx, 0, true) {
                return error
            }
        }
    }
    curIdx = min(str.endIndex, curIdx)
    if curIdx > idx {
        if uri.cleanup & 2 != 0 {
            uri.path = Array(str[idx..<curIdx])
        } else {
            uri.path = uriUnescape(str, idx, curIdx - idx)
        }
    }
    idx = curIdx
    return nil
}

/**
 * parse3986PathNoScheme:
 * @uri:  pointer to an URI structure
 * @idx:  pointer to str current index
 * @str:  the string to analyze
 *
 * Parse an path which is not a scheme and fills in the appropriate fields
 * of the @uri structure
 *
 * path-noscheme = segment-nz-nc *( "/" segment )
 *
 * Returns URIError or NULL
 */
func parse3986PathNoScheme(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var path = NULL_URICharPtr
    var curIdx = idx
    if let error = parse3986Segment(str, &curIdx, Letter.colon, false) {
        return error
    }
    while str.get(curIdx) == Letter.slash {
        curIdx += 1
    }
    if idx < curIdx {
        path += Array(str[idx..<curIdx])
    }
    while let cur = str.get(curIdx) {
        if cur == Letter.question || cur == Letter.number {
            break
        }
        let prevIdx = curIdx
        if let error = parse3986Segment(str, &curIdx, 0, true) {
            return error
        }
        if curIdx > prevIdx {
            path += Array(str[prevIdx..<curIdx])
        }
        if let cur = str.get(curIdx) {
            if cur == Letter.slash {
                path += Letter.slash
            } else if cur != Letter.question, cur != Letter.number {
                path += uriUnescape(str, curIdx, 1)
            }
            curIdx += 1
        }
    }
    uri.path = path
    idx = min(curIdx, str.endIndex)
    return nil
}

/**
 * parse3986HierPart:
 * @uri:  pointer to an URI structure
 * @idx:  pointer to str current index
 * @str:  the string to analyze
 *
 * Parse an hierarchical part and fills in the appropriate fields
 * of the @uri structure
 *
 * hier-part     = "//" authority path-abempty
 *                / path-absolute
 *                / path-rootless
 *                / path-empty
 *
 * Returns URIError or NULL
 */
func parse3986HierPart(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    if str.get(curIdx) == Letter.slash && str.get(curIdx + 1) == Letter.slash {
        curIdx += 2
        if let error = parse3986Authority(&uri, str, &curIdx) {
            return error
        }
        if isNullURICharPtr(uri.server) {
            uri.port = -1
        }
        if let error = parse3986PathAbEmpty(&uri, str, &curIdx) {
            return error
        }
        idx = curIdx
        return nil
    }
    if str.get(curIdx) == Letter.slash {
        if let error = parse3986PathAbsolute(&uri, str, &curIdx) {
            return error
        }
    } else if isPChar(str, curIdx) {
        if let error = parse3986PathRootless(&uri, str, &curIdx) {
            return error
        }
    } else {
        /// path-empty is effectively empty
        uri.path = NULL_URICharPtr
    }
    idx = curIdx
    return nil
}

/**
 * parse3986PathRootless:
 * @uri:  pointer to an URI structure
 * @idx:  pointer to str current index
 * @str:  the string to analyze
 *
 * Parse an path without root and fills in the appropriate fields
 * of the @uri structure
 *
 * path-rootless = segment-nz *( "/" segment )
 *
 * Returns URIError or NULL
 */
func parse3986PathRootless(_ uri: inout URI, _ str: URICharPtr, _ idx: inout Int) -> URIError? {
    var curIdx = idx
    if let error = parse3986Segment(str, &curIdx, 0, false) {
        return error
    }
    while str.get(curIdx) == Letter.slash {
        curIdx += 1
        if let error = parse3986Segment(str, &curIdx, 0, true) {
            return error
        }
    }
    curIdx = min(curIdx, str.endIndex)
    if curIdx > idx {
        if uri.cleanup & 2 != 0 {
            uri.path = Array(str[idx..<curIdx])
        } else {
            uri.path = uriUnescape(str, idx, curIdx - idx)
        }
    }
    idx = curIdx
    return nil
}
