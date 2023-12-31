//
//  TemplateDataProvider.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/17.
//
// swiftlint:disable file_length

import RxSwift
import RxCocoa
import SKFoundation
import SwiftyJSON
import SKUIKit
import SKResource
import Foundation
import SpaceInterface
import SKInfra

public final class TemplateDataProvider {
    static let pageSize: Int = 30
    let platform = "mobile"
    let parseDataQueue = DispatchQueue(label: "ccm.template.parse",
                                       qos: .default,
                                       attributes: .concurrent)
    let timeout: Double = 20.0     // 单次请求20s超时，DocsRequest有3次重试逻辑
    public var templateSource: String?
    public init() {}
}
// 模板接口文档：https://bytedance.feishu.cn/docs/doccnFyf8pA7xm2hE2P44ZgkV8c#
extension TemplateDataProvider: TemplateCenterNetworkAPI {
    public func fetchGalleryCategories(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> Observable<GalleryTemplateCategoriesInfo> {
        var params: [String: Any] = [
            "platform": "mobile",
            "template_collection": 1,
            "version": 4,
            "user_recommend": userRecommend ? 1 : 0,
            "docx_template": docxEnable ? 1 : 0,
            "ecology": true // 是否开启生态模板
        ]
        if self.shouldUseNewForm() {
            params["version"] = 5
        }
        if let docsType = docsType?.rawValue {
            params["obj_type"] = docsType
        }
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getSystemTemplateV2,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (json) -> Observable<GalleryTemplateCategoriesInfo> in
                guard let json = json,
                      let data = json["data"].rawString()?.data(using: .utf8) else {
                        spaceAssertionFailure("parse data error")
                        return .error(TemplateError.parseDataError)
                }

                do {
                    var categoriesInfo = try JSONDecoder().decode(GalleryTemplateCategoriesInfo.self, from: data)
                    let tmplMetaDict = categoriesInfo.tmplMetaDict?.compactMapValues({ tpl in
                        var template = tpl
                        template.templateSource = self.templateSource
                        return template
                    })
                    categoriesInfo.tmplMetaDict = tmplMetaDict
                    return .just(categoriesInfo)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }
    
    public func shouldUseNewForm() -> Bool {
        return self.templateSource == TemplateCenterTracker.TemplateSource.lark_survey.rawValue || self.templateSource == TemplateCenterTracker.TemplateSource.baseHomepageLarkSurvey.rawValue || self.templateSource == TemplateCenterTracker.TemplateSource.spaceHomepageLarkSurvey.rawValue || self.templateSource == TemplateCenterTracker.TemplateSource.wikiHomepageLarkSurvey.rawValue
    }

    public func fetchTemplates(of categoryId: String,
                               at page: Int,
                               pageSize: Int?,
                               docsType: DocsType?,
                               docxEnable: Bool) -> Observable<TemplateCenterViewModel.CategoryPageInfo> {
        var params: [String: Any] = [
            "version": 4,
            "platform": "mobile",
            "template_collection": 1,
            "docx_template": docxEnable ? 1 : 0,
            "category_id": categoryId,
            "page_size": pageSize ?? Self.pageSize,
            "page_number": page,
            "ecology": true // 是否开启生态模板
        ]
        if let docsType = docsType?.rawValue {
            params["obj_type"] = docsType
        }
        if self.shouldUseNewForm() {
            params["version"] = 5
        }
        DocsLogger.info("start fetchTemplates of categoryId:\(categoryId) at:\(page)", component: LogComponents.template)
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getCategoryTemplateList,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (json) -> Observable<TemplateCenterViewModel.CategoryPageInfo> in
                guard let json = json,
                    let templateListStr = json["data"]["template_list"].rawString(),
                    let templateListData = templateListStr.data(using: .utf8) else {
                        spaceAssertionFailure("parse data error")
                        DocsLogger.info("parse templateListStr data error", component: LogComponents.template)
                        return .error(TemplateError.parseDataError)
                }
                do {
                    let templateList = try JSONDecoder().decode([TemplateModel].self, from: templateListData)
                    let tpls = templateList.map {
                        $0.templateSource = self.templateSource
                        return $0
                    }
                    let hasMore = json["data"]["has_more"].boolValue
                    let pageInfo = TemplateCenterViewModel.CategoryPageInfo(categoryId: categoryId, templates: tpls, pageIndex: page, hasMore: hasMore)
                    return .just(pageInfo)
                } catch {
                    DocsLogger.info("parse data error \(error)", component: LogComponents.template)
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    //    "data_type":1,               // optional    不传默认全部  1:我的模版   2:与我共享
    //    "obj_type":,                 // optional    不传默认全部类型
    //    "page_count":10,             // optional
    //    "share_index":"0"            // required    与我分享最后一个模板的index，由后端带回
    //    "search_key": ""             // optional    不传则默认全部内容
    public func fetchCustomTemplates(objType: Int?,
                                     dataType: Int?,
                                     index: String,
                                     searchKey: String? = nil) -> Observable<CustomTemplates> {
        var params: [String: Any] = ["data_type": dataType ?? 0,
                                     "obj_type": objType ?? 0,
                                     "page_count": Self.pageSize,
                                     "share_index": index]
        if let searchKey = searchKey, !searchKey.isEmpty {
            params["search_key"] = searchKey
        }
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getCustomTemplate,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (json) -> Observable<CustomTemplates> in
                guard let json = json,
                    let categories = json["data"].rawString(),
                    let data = categories.data(using: .utf8) else {
                        spaceAssertionFailure("parse data error")
                        return .error(TemplateError.parseDataError)
                }
                do {
                    var model = try JSONDecoder().decode(CustomTemplates.self, from: data)
                    model.addCustomTag()
                    // 将user信息赋值给对应的share template
                    model = TemplateDataProvider.bindTemplateSharer(model)

                    return .just(model)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    public func fetchBusinessTemplates(objType: Int?, searchKey: String? = nil) -> Observable<BusinessTemplates> {
        var params = [String: Any]()
        if let objType = objType {
            params["obj_type"] = objType
        }
        if let searchKey = searchKey, !searchKey.isEmpty {
            params["search_key"] = searchKey
        }
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getBusinessTemplate,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (json) -> Observable<BusinessTemplates> in
                guard let json = json,
                    let categories = json["data"]["categories"].rawString(),
                    let data = categories.data(using: .utf8) else {
                        spaceAssertionFailure("parse data error")
                        return .error(TemplateError.parseDataError)
                }
                var users: [String: TemplateSharer] = [:]
                if let usersStr = json["data"]["users"].rawString(), let usersData = usersStr.data(using: .utf8) {
                    do {
                        users = try JSONDecoder().decode([String: TemplateSharer].self, from: usersData)
                    } catch {
                        DocsLogger.info("parse template sharer data error or data is nil")
                    }
                }
                do {
                    var model = try JSONDecoder().decode(BusinessTemplates.self, from: data)
                    let categories = model.compactMap { category in
                        let tpls = category.templates.compactMap { template in
                            var tpl = template
                            tpl.templateSource = self.templateSource
                            return tpl
                        }
                        var cate = category
                        cate.templates = tpls
                        return cate
                    }
                    model = TemplateDataProvider.bindTemplateSharer(users: users, to: categories)
                    return .just(model)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    public func fetchSuggestionTemplate() -> Observable<[TemplateModel]> {
        var params = [
            "platform": "mobile",
            "scene": "new_entry",
            "version": "4"
        ]
        if LKFeatureGating.templateDocXEnable {
            params["docx_template"] = "1"
        }
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getRecommendTemplateList,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .do(onNext: { (_) in
                TemplateCenterTracker.reportSuggestedTemplateRequestResult(success: true)
            }, onError: { (error) in
                TemplateCenterTracker.reportSuggestedTemplateRequestResult(success: false, errorMsg: "\(error)")
            })
            .flatMap {[weak self] (result) -> Observable<[TemplateModel]> in
                guard let self = self else { return .never() }
                if let result = result,
                   let dataString = result["data"]["templates"].rawString(),
                   let data = dataString.data(using: .utf8) {
                    do {
                        var models = try JSONDecoder().decode([TemplateModel].self, from: data)
                        models = models.map {
                            $0.templateSource = self.templateSource
                            return $0
                        }
                        self.setSuggestionTemplates(models)
                        return .just(models)
                    } catch {
                        DocsLogger.info("cannot parse getRecommendTemplateList \(error)")
                        spaceAssertionFailure("cannot parse getRecommendTemplateList \(error)")
                        return .error(TemplateError.parseDataError)
                    }
                } else {
                    spaceAssertionFailure("cannot parse getRecommendTemplateList")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    private static func bindTemplateSharer(_ customTemplates: CustomTemplates) -> CustomTemplates {
        guard !customTemplates.share.isEmpty, !customTemplates.users.isEmpty else { return customTemplates }
        customTemplates.share.forEach { (templateModel) in
            if let uId = templateModel.fromUserId, !uId.isEmpty,
               let userInfo = customTemplates.users[uId] {
                templateModel.sharerInfo = userInfo
            }
        }
        return customTemplates
    }

    private static func bindTemplateSharer(users: [String: TemplateSharer],
                                           to templateCategories: [TemplateCategory]) -> [TemplateCategory] {
        guard !users.isEmpty else { return templateCategories }

        templateCategories.forEach { (cate) in
            cate.templates.forEach { (templateModel) in
                if let uId = templateModel.fromUserId, !uId.isEmpty,
                   let userInfo = users[uId] {
                    templateModel.sharerInfo = userInfo
                }
            }
        }
        return templateCategories
    }

    public func fetchSearchRecommend() -> Observable<[TemplateSearchRecommend]> {
        let params = ["search_scene_id": "1"] // 第一版，这个id先写死成1，为系统推荐类型
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getTemplasteSearchKeyRecommend,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (result) -> Observable<[TemplateSearchRecommend]> in
                if let result = result,
                   let array = result["data"]["recommend_keys"].array {
                    var res = [TemplateSearchRecommend]()
                    array.forEach { (json) in
                        if let str = json.rawString(), !str.isEmpty {
                            let recommend = TemplateSearchRecommend(name: str)
                            res.append(recommend)
                        }
                    }
                    return .just(res)
                } else {
                    spaceAssertionFailure("cannot parse getRecommendTemplateList")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    public func fetchTemplateBanner() -> Observable<[TemplateBanner]> {
        let platform = SKDisplay.pad ? "pad" : "mobile"
        // 第一版，只有一个场景，后续新增再改接口，但目前看规划和业务特性不会，应该不会有新的场景
        let params: [String: Any] = [
            "scene": "tc",
            "platform": platform,
            "template_collection": 1
        ]
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getTemplateCenterBanner,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (result) -> Observable<[TemplateBanner]> in
                guard let json = result,
                    let categories = json["data"]["banners"].rawString(),
                    let data = categories.data(using: .utf8) else {
                        spaceAssertionFailure("parse data error")
                        return .error(TemplateError.parseDataError)
                }
                do {
                    let model = try JSONDecoder().decode([TemplateBanner].self, from: data)

                    return .just(model)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    public func fetchTemplateTheme(topicID: Int, docType: DocsType?) -> Observable<TemplateThemeResult> {
        let platform = SKDisplay.pad ? "pad" : "mobile"
        var params: [String: Any] = ["topic_id": "\(topicID)", "platform": platform]
        if let type = docType, type != .unknownDefaultType {
            params["obj_type"] = type.rawValue
        }
        if LKFeatureGating.templateDocXEnable {
            params["docx_template"] = 1
        }
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getThemeTemplateList,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (result) -> Observable<TemplateThemeResult> in
                guard let json = result,
                    let templatesDict = json["data"]["templates"].dictionary else {
                        spaceAssertionFailure("parse data error")
                        return .error(TemplateError.parseDataError)
                }
                var tempalteBanner: TemplateBanner?
                if let banner = json["data"]["banner"].rawString(), let bannerData = banner.data(using: .utf8) {
                    do {
                        tempalteBanner = try JSONDecoder().decode(TemplateBanner.self, from: bannerData)
                    } catch {
                        DocsLogger.info("banner data is nil in topic template list page")
                    }
                }

                do {
                    var templateList = [TemplateModel]()
                    let keys = templatesDict.keys.map { (key) -> Int in
                        return Int(key) ?? DocsType.doc.rawValue
                    }.sorted()

                    for typeKey in keys {
                        if let templates = templatesDict["\(typeKey)"]?.rawString(), let data = templates.data(using: .utf8) {
                            let list = try JSONDecoder().decode([TemplateModel].self, from: data)
                            templateList.append(contentsOf: list)
                        } else {
                            spaceAssertionFailure("parse data error")
                        }
                    }
                    if templateList.isEmpty {
                        return .error(TemplateError.themeNoData)
                    }
                    let model = TemplateThemeResult(templateBanner: tempalteBanner, templates: templateList)
                    return .just(model)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    public func fetchTemplateCollection(id: String) -> Observable<TemplateCollection> {
        let params = ["collection_id": id]
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.getTemplateCollection,
                     params: params,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (json) -> Observable<TemplateCollection> in
                guard let json = json,
                      let str = json["data"].rawString(),
                      let data = str.data(using: .utf8) else {
                    return .error(TemplateError.parseDataError)
                }
                do {
                    var collection = try JSONDecoder().decode(TemplateCollection.self, from: data)
                    let tpls = collection.templates.map {
                        $0.templateSource = self.templateSource
                        return $0
                    }
                    collection.templates = tpls
                    return .just(collection)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }

    public func deleteDIYTemplate(templateToken: String, objType: Int) -> Observable<(JSON?)> {
        let params: [String: Any] = ["obj_type": objType, "obj_token": templateToken]

        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.deleteDiyTemplate,
                     params: params,
                     method: .POST,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
    }

    public func saveTemplateCollection(collectionId: String, parentFolderToken: String, folderVersion: Int) -> Observable<(TemplateCollectionSaveResult)> {
        let params: [String: Any] = [
            "collection_id": collectionId,
            "parent_folder_token": parentFolderToken,
            "space_version": folderVersion
        ]
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.useTemplateCollection,
                     params: params,
                     method: .POST,
                     callbackQueue: parseDataQueue,
                     timeout: 60)
            .flatMap { (json) -> Observable<TemplateCollectionSaveResult> in
                guard let json = json,
                      let str = json["data"].rawString(),
                      let data = str.data(using: .utf8) else {
                    return .error(TemplateError.parseDataError)
                }
                do {
                    let result = try JSONDecoder().decode(TemplateCollectionSaveResult.self, from: data)
                    return .just(result)
                } catch {
                    DocsLogger.info("parse data error \(error)")
                    spaceAssertionFailure("parse data error \(error)")
                    return .error(TemplateError.parseDataError)
                }
            }
    }
}

extension TemplateDataProvider: TemplateCenterCacheAPI {
    private func galleryCategoriesKey(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> String {
        let objType = docsType?.rawValue ?? 0
        return "ccm.bytedance.template" + "\(objType),\(docxEnable),\(userRecommend)"
    }
    private func businessKey(_ type: FilterItem.FilterType) -> String { "ccm.bytedance.template.business" + String(type.rawValue) }
    private func customKey(_ type: FilterItem.FilterType) -> String { "ccm.bytedance.template.custom" + String(type.rawValue) }
    private func filterTypeKey(_ type: TemplateMainType) -> String { "ccm.bytedance.template.filter" + String(type.rawValue) }
    private var suggestionKey: String { "ccm.bytedance.template.suggestion" }
    private func topicThemeResultKey(topicId: Int) -> String { "ccm.bytedance.template.topicThemeResult" + "\(topicId)" }
    private func categoryPageKey(categoryId: String, page: Int, pageSize: Int?, docsType: DocsType?, docxEnable: Bool) -> String  {
        let objType = docsType?.rawValue ?? 0
        let pageSize = pageSize ?? -1
        return "ccm.bytedance.template.category \(categoryId),\(page),\(pageSize),\(objType),\(docxEnable)"
    }

    public func setGalleryCategories(_ categories: GalleryTemplateCategoriesInfo, docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) {
        let key = galleryCategoriesKey(docsType: docsType, docxEnable: docxEnable, userRecommend: userRecommend)
        set(key: key, value: categories)
    }

    public func setCustomTemplates(_ type: FilterItem.FilterType, _ templates: CustomTemplates) {
        set(key: customKey(type), value: templates)
    }

    public func deleteAllCustomTemplates() {
        let docsTypes: [FilterItem.FilterType] = [.all, .doc, .sheet, .bitable, .mindnote]
        let keys = docsTypes.map({ customKey($0) })
        keys.forEach({ remove(key: $0) })
    }

    public func setBusinessTemplates(_ type: FilterItem.FilterType, _ templates: BusinessTemplates) {
        set(key: businessKey(type), value: templates)
    }

    public func deleteAllBusinessTemplates() {
        let docsTypes: [FilterItem.FilterType] = [.all, .doc, .sheet, .bitable, .mindnote]
        let keys = docsTypes.map({ businessKey($0) })
        keys.forEach({ remove(key: $0) })
    }

    public func setFilterType(_ mainType: TemplateMainType, type: FilterItem.FilterType) {
        let dict = ["data": type.rawValue]
        set(key: filterTypeKey(mainType), value: dict)
    }

    public func setSuggestionTemplates(_ templates: [TemplateModel]) {
        set(key: suggestionKey, value: templates)
    }

    public func setTopicTemplatesResult(_ templateThemeResult: TemplateThemeResult, for topicId: Int) {
        set(key: topicThemeResultKey(topicId: topicId), value: templateThemeResult)
    }
    
    public func setCategoryPageInfo(_ pageInfo: TemplateCenterViewModel.CategoryPageInfo, for pageSize: Int?, docsType: DocsType?, docxEnable: Bool) {
        let key = categoryPageKey(categoryId: pageInfo.categoryId,
                                  page: pageInfo.pageIndex,
                                  pageSize: pageSize,
                                  docsType: docsType,
                                  docxEnable: docxEnable)
        set(key: key, value: pageInfo)
    }

    private func set<T: Encodable>(key: String, value: T) {
        let uid = User.current.info?.userID ?? ""
        let cacheKey = key + uid
        DispatchQueue.global().async {
            do {
                let data = try JSONEncoder().encode(value)
                CacheService.normalCache.set(object: data, forKey: cacheKey)
                DocsLogger.info("📖📖📖template cache save success. key: \(key)")
            } catch let error {
                DocsLogger.info("template cache save error:\(error.localizedDescription)")
                spaceAssertionFailure("📖📖📖template cache save error:\(error.localizedDescription)")
            }
        }
    }

    public func getGalleryCategories(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> Observable<GalleryTemplateCategoriesInfo> {
        let key = galleryCategoriesKey(docsType: docsType, docxEnable: docxEnable, userRecommend: userRecommend)
        return cache(key: key)
    }

    public func getCustomTemplates(filteredType: FilterItem.FilterType) -> Observable<CustomTemplates> {
        get(key: customKey(filteredType))
    }

    public func getBusinessTemplates(filteredType: FilterItem.FilterType) -> Observable<BusinessTemplates> {
        get(key: businessKey(filteredType))
    }

    public func getSuggestionTemplates() -> Observable<[TemplateModel]> {
        get(key: suggestionKey)
    }

    public func getTopicTemplatesResult(for bannerId: Int) -> Observable<TemplateThemeResult> {
        get(key: topicThemeResultKey(topicId: bannerId))
    }
    
    public func getCategoryPageInfo(of categoryId: String, at page: Int, pageSize: Int?, docsType: DocsType?, docxEnable: Bool) -> Observable<TemplateCenterViewModel.CategoryPageInfo> {
        let key = categoryPageKey(categoryId: categoryId,
                                  page: page,
                                  pageSize: pageSize,
                                  docsType: docsType,
                                  docxEnable: docxEnable)
        return get(key: key)
    }

    private func get<T: Decodable>(key: String) -> Observable<T> {
        let uid = User.current.info?.userID ?? ""
        let cacheKey = key + uid
        return Observable<T>.create { observer -> Disposable in
            DispatchQueue.global().async {
                guard let data: Data = CacheService.normalCache.object(forKey: cacheKey) else {
                    DocsLogger.info("no template cache. key: \(key)", component: LogComponents.template)
                    return
                }
                if data.isEmpty {
                    DocsLogger.info("template cache isEmpty. key: \(key)", component: LogComponents.template)
                    return
                }
                do {
                    let model = try JSONDecoder().decode(T.self, from: data)
                    DocsLogger.info("📖📖📖template cache get success. key: \(key)", component: LogComponents.template)
                    observer.onNext(model)
                } catch {
                    DocsLogger.info("template cache get error \(error), key: \(key)", component: LogComponents.template)
                    spaceAssertionFailure("📖📖📖template cache get error \(error), key: \(key)")
                }
            }
            return Disposables.create()
        }
    }
    private func remove(key: String) {
        let uid = User.current.info?.userID ?? ""
        let cacheKey = key + uid
        DispatchQueue.global().async {
            CacheService.normalCache.removeObject(forKey: cacheKey)
        }
    }

    private func cache<T: Decodable>(key: String) -> Observable<T> {
        let uid = User.current.info?.userID ?? ""
        let cacheKey = key + uid
        return Observable<T>.create { observer -> Disposable in
            DispatchQueue.global().async {
                guard let data: Data = CacheService.normalCache.object(forKey: cacheKey), !data.isEmpty else {
                    DocsLogger.info("no template cache. key: \(key)", component: LogComponents.template)
                    observer.onError(TemplateError.getCacheError)
                    return
                }
                do {
                    let model = try JSONDecoder().decode(T.self, from: data)
                    DocsLogger.info("📖📖📖template cache get success. key: \(key)", component: LogComponents.template)
                    observer.onNext(model)
                    observer.onCompleted()
                } catch {
                    DocsLogger.info("template cache get error \(error), key: \(key)", component: LogComponents.template)
                    spaceAssertionFailure("📖📖📖template cache get error \(error), key: \(key)")
                    observer.onError(TemplateError.getCacheError)
                }
            }
            return Disposables.create()
        }
    }
}
