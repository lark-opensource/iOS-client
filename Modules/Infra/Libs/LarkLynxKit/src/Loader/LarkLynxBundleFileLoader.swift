//
//  LarkLynxBundleFileLoader.swift
//  LarkLynxKit
//
//  Created by Weston Wu on 2023/4/3.
//

import Foundation

/// 读取 Bundle 下解压好的 template
/// bundle.bundleURL + basePath + templatePath
public struct LarkLynxBundleFileLoader: LarkLynxResourceLoader {
    // 从哪一个 bundle 内读取文件
    public let bundle: Bundle
    // 相对bundle根路径的起点
    public let basePath: String?

    public let version: String?

    public let loaderID: String

    public enum LoadError: Error {
        case invalidURL
    }

    // TODO: 改造成 Lark 统一存储的路径数据类型？
    public init(bundle: Bundle, basePath: String?, version: String?) {
        self.bundle = bundle
        self.basePath = basePath
        self.version = version
        loaderID = "BundleFileLoader - \(bundle.bundleIdentifier ?? "unknown")"
    }

    public func load(templatePath: String, completion: @escaping LoaderCompletion) {
        // TODO: 补充 log
        let baseURL = {
            if let basePath {
                return URL(string: basePath, relativeTo: bundle.bundleURL)
            }
            return bundle.bundleURL
        }()

        guard let templateURL = URL(string: templatePath, relativeTo: baseURL) else {
            completion(.failure(LoadError.invalidURL))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: templateURL)
                let template = LarkLynxTemplateInfo(templateData: data,
                                                    // TODO: 确认下Bundle全路径有没有敏感信息？
                                                    filePath: templateURL.absoluteString,
                                                    version: version,
                                                    loaderID: loaderID)
                DispatchQueue.main.async {
                    completion(.success(template))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
