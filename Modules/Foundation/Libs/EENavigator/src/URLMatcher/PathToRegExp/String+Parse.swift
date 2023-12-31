//
//  String+Parse.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/7.
//

import Foundation

private struct Regex {
    fileprivate static let escapeRegex = (try? NSRegularExpression(pattern: "([.+*?=^!:${}()[\\\\]|\\/])"))

    fileprivate static let escapeGroupRegex = (try? NSRegularExpression(pattern: "([=!:$\\/()])"))

    fileprivate static let pathRegex = (try? NSRegularExpression(pattern: [
        // Match escaped characters that would otherwise appear in future matches.
        // This allows the user to escape special characters that won't transform.
        "(\\\\.)",
        // Match Express-style parameters and un-named parameters with a prefix
        // and optional suffixes. Matches appear as:
        //
        // "/:test(\\d+)?" => ["/", "test", "\d+", undefined, "?", undefined]
        // "/route(\\d+)"  => [undefined, undefined, undefined, "\d+", undefined, undefined]
        // "/*"            => ["/", undefined, undefined, undefined, undefined, "*"]
        "([\\/.])?(?:(?:\\:(\\w+)(?:\\(((?:\\\\.|[^()])+)\\))?|\\(((?:\\\\.|[^()])+)\\))([+*?])?|(\\*))"
    ].joined(separator: "|")))
}

extension String {
    // swiftlint:disable function_body_length
    func parse() -> [Token] {
        var tokens: [Token] = []
        var key = 0
        var index = 0
        var path = ""

        let match: [NSTextCheckingResult]
        if let regex = Regex.pathRegex {
            match = regex.matches(in: self, range: NSRange(startIndex..., in: self))
        } else {
            match = []
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #endif
        }

        for res in match {
            let matchStr = self.substr(at: res.range(at: 0))

            let offset = res.range.lowerBound
            path += self.substr(at: NSRange(location: index, length: offset - index)) ?? ""
            index = offset + (matchStr?.count ?? 0)

            let escaped = self.substr(at: res.range(at: 1))

            // Ignore already escaped sequences.
            if let escaped = escaped {
                let one = escaped.index(escaped.startIndex, offsetBy: 1)
                let end = escaped.index(one, offsetBy: 1)
                path += escaped[one ..< end]
                continue
            }

            // Push the current path onto the tokens.
            if !path.isEmpty {
                tokens.append(.simple(token: path))
                path = ""
            }

            let prefix = self.substr(at: res.range(at: 2))
            let name = self.substr(at: res.range(at: 3))
            let capture = self.substr(at: res.range(at: 4))
            let group = self.substr(at: res.range(at: 5))
            let suffix = self.substr(at: res.range(at: 6))
            let asterisk = self.substr(at: res.range(at: 7))

            let repeating = suffix == "+" || suffix == "*"
            let optional = suffix == "?" || suffix == "*"
            let delimiter = prefix ?? "/"
            let pattern = capture ?? group ?? asterisk.map { _ in ".*" } ?? "[^" + delimiter + "]+?"

            let patternEscaped = pattern.escapeGroup()
            let tokenName: TokenId
            if let name = name.map({ TokenId.literal(name: $0) }) {
                tokenName = name
            } else {
                tokenName = .ordinal(index: key)
                key += 1
            }

            tokens.append(
                .complex(
                    tokenId: tokenName,
                    prefix: prefix ?? "",
                    delimeter: delimiter,
                    optional: optional,
                    repeating: repeating,
                    pattern: patternEscaped
                )
            )
        }

        // Match any characters still remaining.
        if index < self.count {
            path += NSString(string: self).substring(from: index)
        }

        // If the path exists, push it onto the end.
        if !path.isEmpty {
            tokens.append(.simple(token: path))
        }

        return tokens
    }

    func escaped() -> String {
        guard let regex = Regex.escapeRegex else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            return self
            #endif
        }
        let range = NSRange(self.startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, range: range, withTemplate: "\\\\$1")
    }

    func escapeGroup() -> String {
        guard let regex = Regex.escapeGroupRegex else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            return self
            #endif
        }
        let range = NSRange(self.startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, range: range, withTemplate: "\\\\$1")
    }

    private func substr(at range: NSRange) -> String? {
        if range.location != NSNotFound {
            return NSString(string: self).substring(with: range)
        }
        return nil
    }
}

func tokensToRegExp(tokens: [Token], options: Options = .default) -> (NSRegularExpression?, [String]) {
    var route = "^"
    var keys: [String] = []

    let end = options.contains(.end)
    let strict = options.contains(.strict)

    let endsWith = "$"
    let delimiter = "/"
    let delimiters = [".", "/"]
    var isEndDelimited = tokens.isEmpty

    tokens.enumerated().forEach { (idx, token) in
        switch token {
        case .simple(let token):
            route += token.escaped()
            let lastChar = String(token.suffix(from: token.index(before: token.endIndex)))
            isEndDelimited = idx == tokens.count - 1 && delimiters.contains(lastChar)
        case .complex(let tokenId, let prefix, let delimeter, let optional, let repeating, let pattern):
            let capture = repeating
                ? "?(:" + pattern + ")(?:" + delimeter.escaped() + "(?:" + pattern + "))*"
                : pattern

            switch tokenId {
            case .literal(let name):
                keys.append(name)
            case .ordinal: break
            }

            if optional {
                route += "(?:" + prefix.escaped() + "(" + capture + "))?"
            } else {
                route += prefix.escaped() + "(" + capture + ")"
            }
        }
    }

    if end {
        if !strict {
            route += "(?:" + delimiter + ")?"
        }
        route += endsWith
    } else {
        if !strict {
            route += "(?:" + delimiter + "(?=" + endsWith + "))?"
        }
        if !isEndDelimited {
            route += "(?=" + delimiter + "|" + endsWith + ")"
        }
    }

    return (try? NSRegularExpression(pattern: route), keys)
}
