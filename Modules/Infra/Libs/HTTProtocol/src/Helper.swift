//
//  Helper.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/11/25.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation

#if DEBUG
let dataFormatter: DateFormatter = {
    let v = DateFormatter()
    v.dateFormat = "MM-dd HH:mm:ss.SSSS"
    return v
}()
#endif

@inline(__always)
func debug(
    _ message: @autoclosure () -> String? = "",
    file: StaticString = #fileID,
    line: Int = #line,
    function: StaticString = #function
) {
    #if DEBUG
    if !HTTProtocol.shouldShowDebugMessage { return }
    let threadno = Thread.current
    print( "\(dataFormatter.string(from: Date())) [\(threadno)]\(file):\(line) \(function) ==> \(message() ?? "")" )
    #endif
}

func reflect<T>(_ obj: T) -> String {
    var v = ""
    dump(obj, to: &v)
    return v
}

func dump(request: URLRequest?) -> String {
    if let request = request {
        return "\((request.url?.absoluteString, request.httpMethod, request.allHTTPHeaderFields))"
    }
    return "no request"
}

extension HTTPURLResponse {
    /// return value of WWW-Authenticate field
    public final var wwwAuthenticate: String? {
        // 苹果标准化为Www-Authenticate, 和标准名其实不一样。有潜在兼容问题。
        // 另外原本OC提供的Dictionary是支持无视大小写的, 转换成Swift的字典丢失了这个能力
        return (self.allHeaderFields as NSDictionary)["Www-Authenticate"] as? String
    }
    /// get value for caseless header field
    public final func headerString(field: String) -> String? {
        /// NOTE: 直接as NSDictionary没有转换，会使用底层的insensitive dict..
        /// 但是如果前面类型是optional的，或者用了as?, 就会有转换，丢失大小写不敏感的特性..
        return (self.allHeaderFields as NSDictionary)[field] as? String
    }
}

extension URL {
    /// return http port for this URL
    public var defaultPort: Int? {
        if let port = self.port { return port }
        // return scheme default port
        // https://en.wikipedia.org/wiki/Port_(computer_networking)
        switch self.scheme {
        case "http": return 80
        case "https": return 443
        default: return nil
        }
    }
    /// return new redirect URL base on this url and location field
    public func redirect(to location: String?) -> URL? {
        // [RFC 7231, section 7.1.2: Location](https://tools.ietf.org/html/rfc7231#section-7.1.2)
        //
        // escaping all illegal chars to guarentee a valid URL. legal chars left untouched
        // allowed chars: https://tools.ietf.org/html/rfc3986#section-2.2
        // gen-delims  = ":" / "/" / "?" / "#" / "[" / "]" / "@"
        // sub-delims  = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
        // unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
        // escaping-char = "%"
        //
        // URL should contains only the privous chars, and escaping all others

        // [print CharacterSet](https://stackoverflow.com/questions/15741631/nsarray-from-nscharacterset/15741737#15741737) // swiftlint:disable:this all
        var urlAllowed: CharacterSet {
            var v = CharacterSet.urlQueryAllowed
            v.insert(charactersIn: ":/?#[]@!$&'()*+,;=-._~%")
            return v
        }
        // 系统会escape一些非法字符, 比如中文, 来保证URL有效。否则创建URL返回nil
        guard var location = location?.addingPercentEncoding(withAllowedCharacters: urlAllowed) else { return nil }
        // 另外根据规范原URL中的fragment, 但apple连Location中的fragment都不保留... 这里我们选择符合规范
        // 进一步测试发现(iOS11-13)，多次重定向时，apple是按第一次请求的fragment判断处理，而不管当前request的fragment是什么。
        // FireFox和Chromium则是继承当前请求的fragment..
        if let frag = self.fragment, location.lastIndex(of: "#") == nil {
            location.append("#" as Character); location.append(frag)
        }
        return URL(string: location, relativeTo: self)
    }
    func canonicalURLComponents(allowNonHTTP: Bool = false) -> URLComponents? {
        // [Normalization and Comparison](https://tools.ietf.org/html/rfc3986#section-6)
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }
        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            assert(allowNonHTTP, "only canonicalize http URL")
            return nil
        }
        components.scheme = scheme // scheme should be lowercased
        if let host = components.host, !host.isEmpty {
            components.host = host.lowercased() // host should be lowercased
        } else {
            components.host = "localhost" // empty host default to localhost
        }
        if components.path.isEmpty { components.path = "/" } // empty path should be `/`
        // default port should be removed
        if components.port == 80 && scheme == "http" { components.port = nil }
        if components.port == 443 && scheme == "https" { components.port = nil }
        return components
    }
    func canonical(allowNonHTTP: Bool = false) -> URL? {
        guard let components = canonicalURLComponents(allowNonHTTP: allowNonHTTP) else { return nil }
        guard let finalURL = components.url else {
            assertionFailure("get url from \(components) shouldn't fail")
            return nil
        }
        return finalURL
    }
}

extension Date {
    /// convert http GMT Date String to Date
    ///
    /// - Parameters:
    ///   - date: date like `Tue, 18 Dec 2018 13:42:57 GMT`
    /// - Returns: Date if success
    public init?(GMT date: String?) {
        guard let date = date?.withCString({ date in
            "%a, %d %b %Y %T %Z".withCString { format -> Date? in
                var dateTime = tm()
                guard strptime_l(date, format, &dateTime, nil) != nil else { return nil }
                return Date(timeIntervalSince1970: TimeInterval(mktime(&dateTime)))
            }
        }) else { return nil }
        self = date
    }
    /// Convert Date to http GMT Date String
    /// - Returns: date like `Tue, 18 Dec 2018 13:42:57 GMT`
    public func toGMT() -> String {
        return "%a, %d %b %Y %T GMT".withCString { format in
            var time = time_t(self.timeIntervalSince1970)
            var dateTime = tm(); gmtime_r(&time, &dateTime)
            let buf = UnsafeMutablePointer<Int8>.allocate(capacity: 30) // fixed size date format
            let v = strftime_l(buf, 30, format, &dateTime, nil)
            assert(v != 0)
            // bytes not need the final null char
            return String(bytesNoCopy: buf, length: 29, encoding: .utf8, freeWhenDone: true) ?? {
                #if DEBUG || ALPHA
                fatalError("unexpected")
                #else
                return ""
                #endif
            }()
        }
    }
}

/// global function namespace
public enum HTTProtocol {
    #if DEBUG
    /// 是否打印详细的http请求日志
    public static var shouldShowDebugMessage = false
    #endif
    /// 输出结构化的Authenticate Challenge数据
    ///
    /// 如果字符串结构不正确，输出前面能解析成功的
    public typealias AuthChallenge = (scheme: String, [String: String])
    public static func extract(authenticate: String?) -> [AuthChallenge] { // swiftlint:disable:this all
        // [WWW-Authenticate](https://tools.ietf.org/html/rfc7235#section-4.1)
        // WWW-Authenticate 可能包含多个scheme, 也可能多个参数
        // scheme和参数key都是大小写不敏感的
        // eg:
        // WWW-Authenticate: Newauth realm="apps", type=1,
        // title="Login to \"apps\"", Basic realm="simple"

        guard let unicode = authenticate?.unicodeScalars  else { return [] }
        let spaces = CharacterSet.whitespacesAndNewlines
        var (it, end) = (unicode.startIndex, unicode.endIndex)

        func skipSpace() {
            while it != end {
                if !spaces.contains(unicode[it]) { return }
                unicode.formIndex(after: &it)
            }
        }
        /// get word until double quote. if no pair quote, return nil and stop at end
        ///
        /// 苹果的实现中没有对转义字符unescape, 因此这里也只是保证配对的quote就行
        /// it start with quote
        /// it will stop at next double quote or end if error
        func quotedWord() -> String? {
            assert(unicode[it] == "\"")
            unicode.formIndex(after: &it)
            let start = it
            while it != end {
                switch unicode[it] {
                case "\\": _ = unicode.formIndex(&it, offsetBy: 2, limitedBy: end) // 转义下一个字符, 忽略
                case "\"":
                    return String(unicode[start..<it])
                default: unicode.formIndex(after: &it)
                }
            }
            return nil // 没遇到quote异常
        }
        enum Token {
            case word(String)
            case equal, comma
        }
        func genTokens() -> [Token] {
            var tokens = [Token]()
            loop: repeat {
                skipSpace()
                if it == end { break loop }

                current: switch unicode[it] {
                case "=": tokens.append(.equal)
                case ",": tokens.append(.comma)
                case "\"":
                    if let word = quotedWord() {
                        tokens.append(.word(word))
                    } else {
                        break loop // end without pair quote exception. currently return previous tokens
                    }
                default: // treat as word begin
                    let wordBegin = it; unicode.formIndex(after: &it)
                    let genWord = { tokens.append(.word(String(unicode[wordBegin..<it]))) }
                    while it != end {
                        let char = unicode[it]
                        if spaces.contains(char) { genWord(); break current }
                        switch char {
                        case "=": genWord(); tokens.append(.equal); break current
                        case ",": genWord(); tokens.append(.comma); break current
                        default:
                            unicode.formIndex(after: &it)
                        }
                    }
                    genWord()
                    break loop // it end
                }
                unicode.formIndex(after: &it) // cosume current iter
            } while it != end
            return tokens
        }

        let tokens = genTokens()
        // first must be a scheme word
        guard case .word(let word)? = tokens.first else { return [] }
        var authArray = [AuthChallenge]()
        var current: AuthChallenge = (word.lowercased(), [:]) // case insensitive, use lowercase version
        var i = 1
        func token(at: Int) -> Token? {
            if at < tokens.endIndex { return tokens[at] }
            return nil
        }
        end: while i != tokens.count {
            switch tokens[i] {
            case .word(let word):
                switch token(at: i + 1) {
                case .equal?:
                    if case .word(let val)? = token(at: i + 2) {
                        current.1[word.lowercased()] = val // key=value
                        i += 3
                    } else {
                        current.1[word.lowercased()] = "" // key="", empty key value
                        i += 2
                    }
                    if case .comma? = token(at: i) {
                        i += 1
                    } else {
                        // after key=value, should have a `,` to sep next item.
                        // or if end, the `,` can be omitted
                        break end
                    }
                case .word?, .comma?, nil: // scheme (word | ,): create a new scheme
                    authArray.append(current)
                    current = (word.lowercased(), [:])
                    i += 1
                }
            case .equal: break end // unexpected equal
            case .comma: i += 1 // multiple ,,, is allowed, simplily ignore it
            }
        }
        authArray.append(current)
        return authArray
    }
}
