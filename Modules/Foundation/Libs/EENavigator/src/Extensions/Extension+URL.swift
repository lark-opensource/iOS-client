//
//  Extension+URL.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import Foundation

extension URL {
    public var withoutQueryAndFragment: String {
        guard var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self.absoluteString
        }

        components.query = nil
        components.fragment = nil

        return components.string ?? ""
    }

    var schemeAndHostLowercased: URL {
        if self.scheme != nil && self.host == nil {
            return self
        }

        guard var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        components.host = components.host?.lowercased()
        components.scheme = components.scheme?.lowercased()

        return components.url ?? self
    }

    public var queryParameters: [String: String] {
        // example result:
        //   query: name=lwl&age=12
        //   output: ["name": "lwl", "age": "12"]
        guard let components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems else { return [:] }

        var items: [String: String] = [:]

        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value?.removingPercentEncoding
        }

        return items
    }

    var identifier: String {
        guard var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self.absoluteString
        }
        components.queryItems = nil
        components.fragment = nil
        return components.url?.absoluteString ?? self.absoluteString
    }

    /// Add a query parameter
    ///
    /// - Parameters:
    ///   - name: query name
    ///   - value: query value, nil for remove
    ///   - forceNew: if queryItems already has item with this name, use the new value or not
    /// - Returns: new url
    public func append(name: String, value: String, forceNew: Bool = true) -> URL {
        return self.append(parameters: [name: value], forceNew: forceNew)
    }

    /// Remove a query parameter
    ///
    /// - Parameter name: name of the query parameter
    /// - Returns: new url
    public func remove(name: String) -> URL {
        return self.remove(names: [name])
    }

    /// Add query parameters
    ///
    /// - Parameters:
    ///   - parameters: query parameters
    ///   - forceNew: if queryItems already has the same item, use the new item or not
    /// - Returns: new url
    public func append(parameters: [String: String], forceNew: Bool = true) -> URL {
        guard !parameters.isEmpty,
            var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var items = components.queryItems ?? []
        parameters.forEach { (name, value) in
            let index = items.firstIndex(where: { $0.name == name })
            if forceNew {
                if let index = index {
                    items.remove(at: index)
                }
                items.append(URLQueryItem(name: name, value: value))
            } else if index == nil {
                items.append(URLQueryItem(name: name, value: value))
            }
        }

        if items.isEmpty {
            components.queryItems = nil
        } else {
            components.queryItems = items
        }

        return components.url ?? self
    }

    /// Remove query parameters
    ///
    /// - Parameter names: names of query parameters
    /// - Returns: new url
    public func remove(names: [String]) -> URL {
        guard !names.isEmpty,
            var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
                return self
        }

        let items = components.queryItems?
            .filter { !names.contains($0.name) }
        components.queryItems = items

        return components.url ?? self
    }

    /// Add or remove the fragment
    ///
    /// - Parameters:
    ///   - fragment: fragment
    ///   - forceNew: if the url already has fragment, use the new fragment or not
    /// - Returns: new url
    public func append(fragment: String?, forceNew: Bool = true) -> URL {
        guard let fragment = fragment,
            var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        if !forceNew, components.fragment != nil {
            return self
        }

        components.fragment = fragment
        return components.url ?? self
    }

    /// Remove the fragment
    ///
    /// - Returns: new url
    public func removeFragment() -> URL {
        guard var components = SafeURLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        components.fragment = nil
        return components.url ?? self
    }

    /// Remove the scheme
    ///
    /// - Returns: new url
    func removeScheme() -> URL {
        guard let sch = scheme, !sch.isEmpty else {
            return self
        }
        var fixedString = absoluteString
        fixedString.removeFirst(sch.count)
        if fixedString.starts(with: ":") {
            fixedString.removeFirst()
        }
        return URL(string: fixedString) ?? self
    }
}

extension URL {
    var logInfo: String { absoluteString.base64 }
}
