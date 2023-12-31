//
//  TemplateDataProvider+Search.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/9/29.
//  


import Foundation
import RxSwift
import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKInfra
extension TemplateDataProvider {
    /// 搜索模板
    /// - Parameters:
    ///   - keyword: 搜索词
    ///   - offset: 分页偏移量
    ///   - docsType: 模板文档类型
    ///   - docxEnable: 是否搜索docx，否则搜索doc
    ///   - tabType: 搜索哪个tab下的模板
    ///   - userRecommend: 是否考虑用户历史使用
    ///   - buffer: 回传给服务端的字段，搜索第一页时传空字符串
    /// - Returns: 搜索结果Observable
    public func searchTemplates(
        keyword: String? = nil,
        offset: Int = 0,
        docsType: DocsType? = nil,
        docxEnable: Bool = false,
        tabType: TemplateMainType? = nil,
        userRecommend: Bool = false,
        buffer: String = ""
    ) -> Observable<PageModel<TemplateModel>> {
        var params = [String: Any]()
        if let docsType = docsType {
            params["obj_type"] = docsType.rawValue
        }
        params["offset"] = offset
        params["page_count"] = 30
        params["keyword"] = keyword
        params["buffer"] = buffer
        if let tabType = tabType {
            var source = "0"
            switch tabType {
            case .gallery:
                source = "1"
            case .custom:
                source = "2"
            case .business:
                source = "3"
            }
            params["source"] = source
        }
        params["docx_template"] = docxEnable ? 1 : 0
        params["user_recommend"] = userRecommend ? 1 : 0
        params["ecology"] = true // 是否开启生态模板
        if self.shouldUseNewForm() {
            params["version"] = 5
        }
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.searchTemplate,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (json) -> Observable<PageModel<TemplateModel>> in
                guard let json = json,
                    let dataStr = json["data"].rawString(),
                    let data = dataStr.data(using: .utf8) else {
                        spaceAssertionFailure("parse data error")
                        return .error(TemplateError.parseDataError)
                }
                var users: [String: TemplateSharer] = [:]
                if let usersStr = json["data"]["authors"].rawString(), let usersData = usersStr.data(using: .utf8) {
                    do {
                        users = try JSONDecoder().decode([String: TemplateSharer].self, from: usersData)
                    } catch {
                        DocsLogger.info("parse template sharer data error or data is nil")
                    }
                }
                do {
                    let model: PageModel<TemplateModel> = try JSONDecoder().decode(PageModel<TemplateModel>.self, from: data)
                    if let templates = model.data {
                        TemplateDataProvider.bindTemplateSharer(users: users, to: templates)
                    }
                    return .just(model)
                } catch {
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }
    
    private static func bindTemplateSharer(users: [String: TemplateSharer],
                                           to templates: [TemplateModel]) {
        guard !users.isEmpty else { return }
        
        templates.forEach { (templateModel) in
            if let uId = templateModel.fromUserId, !uId.isEmpty,
               let userInfo = users[uId] {
                templateModel.sharerInfo = userInfo
            }
        }
    }
}
