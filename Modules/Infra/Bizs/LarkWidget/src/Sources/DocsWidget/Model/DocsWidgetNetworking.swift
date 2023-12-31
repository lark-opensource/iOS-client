//
//  DocsWidgetNetworking.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/17.
//

import Foundation
import LarkHTTP
import LarkExtensionServices
import UIKit
import SwiftUI

public struct DocsWidgetNetworking {

    public enum APIError: Error {
        case httpError(err: Error)
        case bussinessError(code: Int, msg: String)
        case parseError(err: Error)
        case unknownError
    }

    @UserDefaultEncoded(key: WidgetDataKeys.docsWidgetConfig, default: .default)
    static var docsWidgetConfig: DocsWidgetConfig

    static func makeGetRequest<T: Codable>(url: String,
                                           params: [String: Codable]? = nil,
                                           headers: [String: String]? = nil,
                                           onFailure: @escaping (APIError) -> Void,
                                           onSuccess: @escaping (T) -> Void) {
        #if DEBUG
        NSLog("--->>> make https request. URL:\(url), params: \(params), headers: \(headers)")
        #endif
        HTTP.GET(url, parameters: params, headers: headers) { res in
            #if DEBUG
            NSLog("--->>> get https response: \(res.description)")
            #endif
            // 网络请求失败（Request Error）
            if let err = res.error {
                ExtensionLogger.logger.error("[Docs Widget] Request network error: \(err)")
                onFailure(.httpError(err: err))
                return
            }
            // 网络请求成功，解析业务码（Businiess Error）
            if let resJson = try? JSONSerialization.jsonObject(with: res.data, options: []) as? [String: Any], let code = resJson["code"] as? Int, code != 0 {
                let errorMsg = resJson["msg"] as? String ?? "Unknown bussiness error"
                ExtensionLogger.logger.error("[Docs Widget] Request bussiness error: code\(code), \(errorMsg). desc: \(res.description)")
                onFailure(.bussinessError(code: code, msg: errorMsg))
                return
            }
            // 解析有效 Payload（Format Error）
            do {
                let result = try JSONDecoder().decode(T.self, from: res.data)
                ExtensionLogger.logger.info("[Docs Widget] Request succeed with valid payload.")
                onSuccess(result)
            } catch {
                ExtensionLogger.logger.error("[Docs Widget] Request failed with invalid payload: \(error). desc: \(res.description)")
                onFailure(.parseError(err: error))
            }
        }
    }

    static func getSessionHeader() -> [String: String] {
        var header: [String: String] = [
            "X-Request-ID": String.randomStr(len: 40),
            "doc-platform": "Lark",
            "doc-os": UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        ]
        if let version = docsWidgetConfig.appVersion {
            header["doc-version-name"] = version
        }
        if let session = ExtensionAccountService.currentAccountSession {
            header["Cookie"] = "session=\(session)"
        } else {
            ExtensionLogger.logger.error("[Docs Widget] failed to get login session.")
        }
        return header
    }
}

extension DocsWidgetNetworking {

    // MARK: 请求 Drive 域名

    public static func getDriveDomain(completion: @escaping (String?, APIError?) -> Void) {
        ExtensionLogger.logger.info("[Docs Widget] Request drive domain.")
        let url = docsWidgetConfig.getDriveApiURL
        makeGetRequest(url: url, onFailure: { error in
            completion(nil, error)
        }, onSuccess: { (result: DocsDomainResponse) in
            completion(result.data.driveDomain, nil)
        })
    }

    // MARK: 请求文档列表

    /// 请求文档列表
    /// - Parameters:
    ///   - type: 列表种类：最近、收藏、快速访问
    ///   - nums: 最大文档数量
    ///   - completion: 请求完成回调
    public static func requestDocsList(ofType type: DocsListType,
                                       nums: Int,
                                       completion: @escaping ([DocItem]?, APIError?) -> Void) {
        ExtensionLogger.logger.info("[Docs Widget] Request doc list with type: \(type.name).")
        let url = docsWidgetConfig.getDocsListURL(withType: type)
        var header = getSessionHeader()
        header["Content-Type"] = "application/x-www-form-urlencoded"
        makeGetRequest(url: url,
                    params: ["length": nums],
                    headers: header,
                    onFailure: { error in
            completion(nil, error)
        }, onSuccess: { (result: DocListResponse) in
            completion(result.data.docItems, nil)
        })
    }

    // MARK: 请求最新文档信息

    /// 获取最新的文档信息
    /// - Parameters:
    ///   - docItem: 文档实例
    ///   - completion: 请求完成回调
    public static func updateDocInfo(_ docItem: DocItem,
                                     completion: @escaping (DocItem?, APIError?) -> Void) {
        ExtensionLogger.logger.info("[Docs Widget] update doc info for \(docItem.title.desensitized()).")
        if docItem.type != 22 {
            // 对于非 docx 文档，请求最新文档信息，更新文档名称
            ExtensionLogger.logger.info("[Docs Widget] request doc info for type != 22.")
            let url = docsWidgetConfig.getDocInfoURL
            let header = getSessionHeader()
            makeGetRequest(url: url,
                        params: ["token": docItem.token, "type": docItem.type],
                        headers: header,
                        onFailure: { error in
                switch error {
                case .bussinessError:
                    // 业务错误（如文档已删除）不返回原来的 docItem
                    completion(nil, error)
                default:
                    // 非业务错误（如网络问题）仍返回原来的 docItem
                    completion(docItem, error)
                }
            }, onSuccess: { (result: DocInfoResponse) in
                var newDocItem = docItem
                newDocItem.title = result.data.title
                newDocItem.url = result.data.url
                completion(newDocItem, nil)
            })
        } else {
            // 对于 docx 类型文档，请求文档封面图，更新文档名称、封面
            ExtensionLogger.logger.info("[Docs Widget] request doc cover for type == 22.")
            let url = docsWidgetConfig.getDocCoverURL
            var header = getSessionHeader()
            // 添加此 User-Agent 绕过 CSRF 检查
            header["User-Agent"] = "lark/widget"
            HTTP.POST(url,
                      parameters: ["page_id": docItem.token, "ids": [docItem.token]],
                      headers: header,
                      requestSerializer: JSONParameterSerializer()) { res in
                if let err = res.error {
                    ExtensionLogger.logger.error("[Docs Widget] Request network error: \(err)")
                    completion(docItem, .httpError(err: err))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(DocCoverResponse.self, from: res.data)
                    var newDocItem = docItem
                    newDocItem.cover = result.data.getCover(docItem.token)
                    if let title = result.data.getTitle(docItem.title) {
                        newDocItem.title = title
                    }
                    ExtensionLogger.logger.info("[Docs Widget] Request succeed with valid payload.")
                    completion(newDocItem, nil)
                } catch {
                    ExtensionLogger.logger.error("[Docs Widget] Request failed with invalid payload: \(error). desc: \(res.description)")
                    completion(nil, .parseError(err: error))
                }
            }
        }
    }

    // MARK: 下载文档封面图

    /// 下载文档图片
    /// - Parameters:
    ///   - docItem: 文档实例
    ///   - completion: 请求完成回调
    public static func downloadCoverImage(for docItem: DocItem, completion: @escaping (UIImage?, APIError?) -> Void) {
        guard let coverToken = docItem.cover else {
            completion(nil, nil)
            return
        }
        let url = docsWidgetConfig.getImageDownloadURL(withImageToken: coverToken)
        let params: [String: Any] = ["width": 360, "height": 360, "policy": "near"]
        let header = getSessionHeader()
        HTTP.GET(url, parameters: params, headers: header) { response in
            if let image = UIImage(data: response.data) {
                ExtensionLogger.logger.info("[Docs Widget] Download cover image succeed.")
                completion(image, nil)
            } else {
                ExtensionLogger.logger.error("[Docs Widget] Download cover image failed, detail: \(response.description)")
                if let error = response.error {
                    completion(nil, .httpError(err: error))
                } else {
                    completion(nil, .unknownError)
                }
            }
        }
    }
}
