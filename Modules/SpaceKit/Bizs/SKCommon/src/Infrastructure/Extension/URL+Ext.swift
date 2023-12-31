//
//  URL+Ext.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/15.
//

import SKFoundation
import LarkStorage
import SKInfra

extension URL: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == URL {

    func changeSchemeTo(_ schemeStr: String) -> URL {
        guard var urlComponent = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            return base
        }
        urlComponent.scheme = schemeStr
        guard let newURL = urlComponent.url else {
            return base
        }
        return newURL
    }

    var avoidNoDefaultScheme: URL? {
        guard base.scheme == nil else {
            return base
        }
        return URL(string: "http://" + base.absoluteString)
    }

    var isDocHistoryUrl: Bool {
        guard base.fragment == "history" else {
            return false
        }
        return true
    }

    //申诉的标识
    var isAppealUrl: Bool {
        guard base.fragment == "appeal" else {
            return false
        }
        return true
    }

    // 是否为文档 block 锚链，在本文档里直接跳转
    var isFragmentADocBlock: Bool {
        guard base.fragment != nil else { return false }
        return !isDocHistoryUrl && !isAppealUrl
    }

    /// 是否为评论锚链
    var isCommentAnchorLink: (isCommentAnchor: Bool, commentId: String) {
        let components = URLComponents(string: base.absoluteString)
        let sceneItem = components?.queryItems?.first(where: { return $0.name == "comment_anchor" && $0.value == "true" })
        let commentItem = components?.queryItems?.first(where: { return $0.name == "comment_id" })
        return (isCommentAnchor: sceneItem != nil, commentId: commentItem?.value ?? "")
    }
    
    var isDocComponentUrl: Bool {
        let sceneId = self.queryParams?[RouterDefine.sceneId] ?? self.queryParams?[RouterDefine.docAppId]
        if let sceneId = sceneId, !sceneId.isEmpty {
            return true
        }
        return false
    }

    //从群tab打开的文档
    var isGroupTabUrl: Bool {
        let from: [String: String]? = fetchQuery()
        return from?["from"] == FromSource.groupTab.rawValue
    }

    // 是否是用wiki打开的docs链接
    var isWikiDocURL: Bool {
        guard DocsUrlUtil.getFileToken(from: base, with: .wiki) != nil else {
            return false
        }
        return true
    }
    var queryParams: [String: String]? {
        guard let query = base.query else { return nil }
        var queryStrings = [String: String]()
        for pair in query.components(separatedBy: "&") {
            let kvMapping = pair.components(separatedBy: "=")
            if kvMapping.count < 2 { continue }
            let key = kvMapping[0]
            let value = kvMapping[1].replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? ""
            queryStrings[key] = value
        }
        return queryStrings
    }

    @available(*, deprecated, message: "abandoned，please use addEncodeQuery()")
    func addQuery(parameters: [String: String]) -> URL {
        /// 准备去掉，后续直接使用addEncodeQuery方法
        return addEncodeQuery(parameters: parameters)
    }
    
    /// 对Url进行追加参数拼接
    /// - Parameters:
    ///   - parameters: 需要拼接的参数
    ///   - addPercentEncoding: 参数是否需要编码，默认 ture，
    ///     ⚠️ 注意：如果传入为false，如果parameters有特殊字符或者中文，操作写入的是percentEncodedQueryItems，没有编码会导致崩溃
    /// - Returns: 拼接好的URL
    /// - 参考文档：https://bytedance.sg.feishu.cn/docx/doxlg19MjGuobkmWV8wR0QNPJif
    func addEncodeQuery(parameters: [String: String], addPercentEncoding: Bool = true) -> URL {
        guard var urlComponents = URLComponents(url: base, resolvingAgainstBaseURL: false), !parameters.isEmpty else {
            DocsLogger.info("addEncodeQuery base error")
            return base
        }
        
        var encodeParameters = parameters
        if addPercentEncoding {
            // 对 parameters进行编码
            encodeParameters = encodeQueryParameters(parameters: parameters)
        }
        
        // 只增加原来没有的 query
        let additionalQueryString = encodeParameters.filter { (key, _) -> Bool in
            return !(urlComponents.percentEncodedQueryItems?.contains { $0.name == key } ?? false)
        }.map { "\($0)=\($1)" }.joined(separator: "&")
        guard !additionalQueryString.isEmpty else {
            // 没有额外query
            return base
        }
        let currentQuery = urlComponents.percentEncodedQuery.map { $0 + "&" } ?? ""
        urlComponents.percentEncodedQuery = currentQuery + additionalQueryString
        return urlComponents.url ?? base
    }

    @available(*, deprecated, message: "abandoned，please use addOrChangeEncodeQuery()")
    func addOrChangeQuery(parameters: [String: String]) -> URL {
        
        /// 后续直接使用addOrChangeEncodeQuery方法
        return addOrChangeEncodeQuery(parameters: parameters)
    }
    
    /// 对Url进行替换或添加参数拼接
    /// - Parameters:
    ///   - parameters: 需要拼接的参数
    ///   - addPercentEncoding: 参数是否需要编码，默认 ture，
    ///     ⚠️ 注意：如果传入为false，如果parameters有特殊字符或者中文，操作写入的是percentEncodedQueryItems，没有编码会导致崩溃
    /// - Returns: 拼接好的URL
    /// - 参考文档：https://bytedance.sg.feishu.cn/docx/doxlg19MjGuobkmWV8wR0QNPJif
    func addOrChangeEncodeQuery(parameters: [String: String], addPercentEncoding: Bool = true) -> URL {
        guard var urlComponents = URLComponents(url: base, resolvingAgainstBaseURL: false), !parameters.isEmpty else {
            DocsLogger.info("addOrChangeEncodeQuery base error")
            return base
        }
        
        var encodeParameters = parameters
        if addPercentEncoding {
            // 对 parameters进行编码
            encodeParameters = encodeQueryParameters(parameters: parameters)
        }
        
        let modifiedQueryItems: [URLQueryItem] = {
            var items: [URLQueryItem] = urlComponents.percentEncodedQueryItems ?? []
            encodeParameters.forEach({ (key, value) in
                let item = URLQueryItem(name: key, value: value)
                items.removeAll { $0.name == key }
                items.append(item)
            })
            return items
        }()
        urlComponents.percentEncodedQueryItems = modifiedQueryItems
        return urlComponents.url ?? base
        
    }

    func fetchQuery() -> [String: String]? {
        guard let query = base.query else { return nil }
        let queryStrs = query.components(separatedBy: "&")
        var result: [String: String] = [:]
        queryStrs.forEach { (queryStr) in
            if queryStr.contains("=") {
                let list = queryStr.components(separatedBy: "=")
                if let key = list.first?.urlDecoded(), let value = list.last?.urlDecoded() {
                    result[key] = value
                }
            }
        }
        if result.count == 0 { return nil }
        return result
    }
    
    // 对query参数进行 encode
    func encodeQueryParameters(parameters: [String: String]) -> [String: String] {
        guard !parameters.isEmpty else {
            return parameters
        }
        var encodeRes = [String: String]()
        parameters.forEach({ (key, value) in
            encodeRes[key.urlEncoded()] = value.urlEncoded()
        })
        return encodeRes
    }
    
    func deleteQuery(key: String) -> URL {
        guard
            var urlComponents = URLComponents(url: base, resolvingAgainstBaseURL: false)
            else { return base }
        let modifiedQueryItems: [URLQueryItem] = {
            var items: [URLQueryItem] = urlComponents.queryItems ?? []
            items.removeAll(where: { $0.name == key })
            return items
        }()
        urlComponents.queryItems = modifiedQueryItems
        return urlComponents.url ?? base
    }

    func safeDeleteQuery(key: String) -> URL {
        guard
            var urlComponents = URLComponents(url: base, resolvingAgainstBaseURL: false)
            else { return base }
        let modifiedQueryItems: [URLQueryItem] = {
            var items: [URLQueryItem] = urlComponents.percentEncodedQueryItems ?? []
            items.removeAll(where: { $0.name == key })
            return items
        }()
        urlComponents.percentEncodedQueryItems = modifiedQueryItems
        return urlComponents.url ?? base
    }
    
    func urlByResolvingApplicationDirectory(baseDir: String = AbsPath.library.absoluteString) -> URL {
        let oldPath = base.path
        let baseDirComponents = baseDir.components(separatedBy: "/")
        var oldPathComponents = oldPath.components(separatedBy: "/")
        
        // base dir not changed
        if oldPath.hasPrefix(baseDir) {
            return self.base
        }
        
        // cur dir is shorter then base dir
        if oldPathComponents.count < baseDirComponents.count {
            return self.base
        }
        
        for (index, value) in baseDirComponents.enumerated() {
            oldPathComponents[index] = value
        }
        let newPath = oldPathComponents.joined(separator: "/")
        return URL(fileURLWithPath: newPath)
    }
    
    var isEmail: Bool {
        var emailAddressRegex: String
        if let regex = SettingConfig.emailValidateRegular?["email_reg"] as? String {
            emailAddressRegex = regex
        } else {
            emailAddressRegex = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        }
        return base.absoluteString.isMatch(for: emailAddressRegex)
    }
}
