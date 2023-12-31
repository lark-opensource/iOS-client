//
//  TemplateCenterViewModel.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/16.
//
// swiftlint:disable type_body_length file_length

import RxSwift
import RxCocoa
import SKFoundation
import SKResource
import SwiftyJSON
import LarkReleaseConfig
import Foundation
import SpaceInterface
import LarkSetting

typealias Categories = [TemplateCenterViewModel.Category]
public typealias BusinessTemplates = [TemplateCategory]

// network
public protocol TemplateCenterNetworkAPI {
    func fetchGalleryCategories(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> Observable<GalleryTemplateCategoriesInfo>
    func fetchTemplates(of categoryId: String, at page: Int, pageSize: Int?, docsType: DocsType?, docxEnable: Bool) -> Observable<TemplateCenterViewModel.CategoryPageInfo>
    func fetchCustomTemplates(objType: Int?, dataType: Int?, index: String, searchKey: String?) -> Observable<CustomTemplates>
    func fetchBusinessTemplates(objType: Int?, searchKey: String?) -> Observable<BusinessTemplates>
    func fetchSuggestionTemplate() -> Observable<[TemplateModel]>
    func fetchSearchRecommend() -> Observable<[TemplateSearchRecommend]>
    func fetchTemplateBanner() -> Observable<[TemplateBanner]>
    func fetchTemplateTheme(topicID: Int, docType: DocsType?) -> Observable<TemplateThemeResult>
    func deleteDIYTemplate(templateToken: String, objType: Int) -> Observable<(JSON?)>
    func fetchTemplateCollection(id: String) -> Observable<TemplateCollection>
    func searchTemplates(
        keyword: String?,
        offset: Int,
        docsType: DocsType?,
        docxEnable: Bool,
        tabType: TemplateMainType?,
        userRecommend: Bool,
        buffer: String) -> Observable<PageModel<TemplateModel>>
    func saveTemplateCollection(collectionId: String, parentFolderToken: String, folderVersion: Int) -> Observable<(TemplateCollectionSaveResult)>
    func deleteAllCustomTemplates()
    func deleteAllBusinessTemplates()
}

// cache
public protocol TemplateCenterCacheAPI {
    func setGalleryCategories(_ categories: GalleryTemplateCategoriesInfo, docsType: DocsType?, docxEnable: Bool, userRecommend: Bool)
    func setCustomTemplates(_ type: FilterItem.FilterType, _ templates: CustomTemplates)
    func setBusinessTemplates(_ type: FilterItem.FilterType, _ templates: BusinessTemplates)
    func setFilterType(_ mainType: TemplateMainType, type: FilterItem.FilterType)
    func setSuggestionTemplates(_ templates: [TemplateModel])
    func setTopicTemplatesResult(_ templateThemeResult: TemplateThemeResult, for topic: Int)
    func setCategoryPageInfo(_ pageInfo: TemplateCenterViewModel.CategoryPageInfo, for pageSize: Int?, docsType: DocsType?, docxEnable: Bool)

    func getGalleryCategories(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> Observable<GalleryTemplateCategoriesInfo>
    func getCustomTemplates(filteredType: FilterItem.FilterType) -> Observable<CustomTemplates>
    func getBusinessTemplates(filteredType: FilterItem.FilterType) -> Observable<BusinessTemplates>
    func getSuggestionTemplates() -> Observable<[TemplateModel]>
    func getTopicTemplatesResult(for topic: Int) -> Observable<TemplateThemeResult>
    func getCategoryPageInfo(of categoryId: String, at page: Int, pageSize: Int?, docsType: DocsType?, docxEnable: Bool) -> Observable<TemplateCenterViewModel.CategoryPageInfo>
}

public final class TemplateCenterViewModel {
    // Input
    struct InputBridge {
        let cacheAPI: TemplateCenterCacheAPI

        // load more custom templates
        let loadMoreCustomTemplates = PublishSubject<Void>()

        // filter gallery templates by FilterItem.FilterType, default value is nil, means no filter
        let galleryFilterType = BehaviorRelay<FilterItem.FilterType>(value: .all)

        // filter custom templates by FilterItem.FilterType, default value is nil, means no filter
        let customFilterType = BehaviorRelay<FilterItem.FilterType>(value: .all)

        // filter business templates by FilterItem.FilterType, default value is nil, means no filter
        let businessFilterType = BehaviorRelay<FilterItem.FilterType>(value: .all)

        // present filter view
        let showFilterView = PublishSubject<TemplateMainType>()

        // delete no permission template from screen and update cache
        let deleteNoPermissionTemplate = PublishSubject<(mainType: TemplateMainType, objToken: String)>()
        
        // fetch all template banner data
        let initTemplateBanner = PublishSubject<Void>()
        
        let loadPageForCategory = PublishSubject<(String, Int)>()
        
        let forceRefreshCustomTemplates = PublishSubject<Void>()
        
        let forceRefreshBusinessTemplates = PublishSubject<Void>()
    }
    lazy var input: InputBridge = { InputBridge(cacheAPI: self.cacheAPI) }()

    var docxEnable = false
    var createBlankDocs = false

    private let serialQueue = SerialDispatchQueueScheduler(internalSerialQueueName: "ccm.bytedance.template.viewmodel")

    // Output
    lazy var galleryCategoryUpdated: Observable<Event<Categories>> = {
        // try to get data from cache firstly
        // when request callback, update the data in cache
        let getDataSequence: Observable<Event<Categories>> = input
            .galleryFilterType
            .skip(1)
            .flatMap({[weak self] (filterType) -> Observable<Event<Categories>> in
                guard let self = self else { return .never() }
                let docsType = self.docsType(from: filterType)
                let createBlankDocs = self.createBlankDocs
                let localData = self.cacheAPI.getGalleryCategories(
                    docsType: docsType,
                    docxEnable: self.docxEnable,
                    userRecommend: createBlankDocs
                ).catchError { _ -> Observable<GalleryTemplateCategoriesInfo> in
                    return createBlankDocs && filterType != .all ? .just(GalleryTemplateCategoriesInfo()) : .never()
                }
                let networkData = self.networkAPI.fetchGalleryCategories(
                    docsType: docsType,
                    docxEnable: self.docxEnable,
                    userRecommend: self.createBlankDocs
                )
                .do(onNext: { [weak self] (categories) in
                    guard let self = self else { return }
                    DocsLogger.info("📖📖📖 fetch gallery templates frome network success, begin save locally")
                    self.cacheAPI.setGalleryCategories(categories, docsType: docsType, docxEnable: self.docxEnable, userRecommend: self.createBlankDocs)
                })
                return Observable.merge(localData, networkData)
                .observeOn(self.serialQueue)
                    .map({ return Self.galleryCategories(from: $0, templateSource: self.templateSource) })
                .do(onNext: { [weak self] (galleryCategories) in
                    self?.galleryCategories = galleryCategories
                })
                .materialize()
                .filter { [weak self] (event) -> Bool in
                    guard let self = self else { return false }
                    switch event {
                    case .next:
                        return true
                    case .completed, .error:
                        // 有缓存，不处理网络错误
                        return self.galleryCategories.isEmpty
                    @unknown default:
                        fatalError("unknown default")
                    }
                }
            })
        return getDataSequence
            .observeOn(serialQueue)
            .map { [weak self] (event) -> Event<Categories> in
                guard let self = self else { return .completed }
                let filterType = self.input.galleryFilterType.value
                return self.insertCreateBlankDocsIfNeed(event: event, filterType: filterType)
            }
            .observeOn(MainScheduler.instance).share()
    }()
    
    lazy var galleryCategoryTemplatesUpdate: Observable<CategoryPageInfo> = {
        input.loadPageForCategory
            .flatMap { [weak self] (categoryId, pageIndex) -> Observable<CategoryPageInfo> in
                guard let self = self else { return .never() }
                return self.networkAPI.fetchTemplates(
                    of: categoryId,
                    at: pageIndex,
                    pageSize: nil,
                    docsType: self.docsType(from: self.input.galleryFilterType.value),
                    docxEnable: self.docxEnable
                )
            }
            .observeOn(MainScheduler.instance)
    }()

    lazy var customTemplatesUpdated: Observable<Event<Categories>> = {
        // filter or init logic
        // get data from cache first
        // then get the server's data, update UI
        // then update the cache
        let filteredSequence = input.customFilterType
            .skip(1)
            .flatMap {[weak self] (filteredType) -> Observable<Event<CustomTemplates>> in
                guard let self = self else { return .never() }
                let rawValue = FilterItem.convertType(filterType: filteredType).first?.rawValue
                return Observable.merge(
                    self.cacheAPI.getCustomTemplates(filteredType: filteredType),
                    self.networkAPI.fetchCustomTemplates(
                        objType: rawValue,
                        dataType: nil,
                        index: "0",
                        searchKey: nil
                    )
                    .do(onNext: {[weak self] (customTemplates) in
                        DocsLogger.info("📖📖📖 fetch custom templates frome network success, FilterType is \(filteredType.rawValue), begin save locally")
                        self?.cacheAPI.setCustomTemplates(filteredType, customTemplates)
                    })
                )
                    .observeOn(self.serialQueue)
                    .do(onNext: {[weak self] (dataSource) in
                        self?.customDataSource = dataSource
                    })
                    .materialize()
            }

        // load more logic
        let loadMoreSequence = input.loadMoreCustomTemplates
            .flatMap {[weak self] _ -> Observable<Event<CustomTemplates>> in
                guard let self = self else { return .never() }
                let docsType = FilterItem.convertType(filterType: self.input.customFilterType.value).first?.rawValue
                return self.networkAPI
                    .fetchCustomTemplates(
                        objType: docsType,
                        dataType: 2,
                        index: self.customDataSource.shareIndex,
                        searchKey: nil
                    )
                    .observeOn(self.serialQueue)
                    .map({ (moreDataSource) -> CustomTemplates in
                        var newDataSource = self.customDataSource.customTemplates(byAppendingMore: moreDataSource)
                        self.customDataSource = newDataSource
                        DocsLogger.info("📖📖📖custom load more success, hasmore: \(moreDataSource.hasMore)")
                        return newDataSource
                    })
                    .materialize()
            }

        // delete no permission
        let deleteSequence = input
            .deleteNoPermissionTemplate
            .observeOn(self.serialQueue)
            .flatMap {[weak self] (type, objToken) -> Observable<Event<CustomTemplates>> in
                guard let self = self, type == .custom else { return .never() }
                self.customDataSource = self.customDataSource.customTemplates(byRemoveObjToken: objToken)
                self.cacheAPI.setCustomTemplates(self.input.customFilterType.value, self.customDataSource)
                return .just(.next(self.customDataSource))
            }

        return Observable
            .merge(filteredSequence,
                   loadMoreSequence,
                   deleteSequence)
            .observeOn(self.serialQueue)
            .map({[weak self] (event) -> Event<Categories> in
                guard let self = self else { return .completed }
                switch event {
                case .next(let customTemplates):
                    if customTemplates.isEmpty && self.input.customFilterType.value == .all {
                        DocsLogger.info("custom template no data")
                        return .error(TemplateError.customNoData)
                    }
                    return .next(Self.customCategories(from: customTemplates))
                case .error(let error):
                    return .error(error)
                case .completed:
                    return .completed
                @unknown default:
                    spaceAssertionFailure("unknown default")
                    return .completed
                }
            })
            .observeOn(MainScheduler.instance)
            .share()
    }()

    lazy var businessTemplatesUpdated: Observable<Event<Categories>> = {
        // try to get data from cache firstly
        // when request callback, update the data in cache
        let getDataSequence = input
            .businessFilterType
            .skip(1)
            .flatMap({ [weak self] filteredType -> Observable<Event<Categories>> in
                guard let self = self else { return .never() }
                let rawValue = FilterItem.convertType(filterType: filteredType).first?.rawValue
                return Observable.merge(
                    self.cacheAPI.getBusinessTemplates(filteredType: filteredType),
                    self.networkAPI.fetchBusinessTemplates(objType: rawValue, searchKey: nil)
                        .do(onNext: { [weak self] (categories) in
                            guard let self = self else { return }
                            DocsLogger.info("📖📖📖 fetch business templates frome network success, begin save locally")
                            self.cacheAPI.setBusinessTemplates(filteredType, categories)
                        })
                )
                    .observeOn(self.serialQueue)
                    .map({ Self.businessCategories(from: $0) })
                    .do(onNext: { [weak self] in self?.businessCategories = $0 })
                    .materialize()
                    .map({
                        if case let .next(businessTemplates) = $0,
                           Self.isEmptyOf(businessTemplates: businessTemplates) {
                            DocsLogger.info("business template no data")
                            if self.input.businessFilterType.value == .all {
                                return .error(TemplateError.businessNoData)
                            }
                            return .error(TemplateError.filterTypeNoData)
                        }
                        return $0
                    })
                    .filter { (event) -> Bool in
                        if case .next = event {
                            return true
                        }
                        // 有缓存，不处理网络错误
                        return Self.isEmptyOf(businessTemplates: self.businessCategories)
                    }
            })
        return getDataSequence.observeOn(MainScheduler.instance).share()
    }()
    
    lazy var templateBannerUpdated: Observable<Event<[TemplateBanner]>> = {
        let getDataSequence = input.initTemplateBanner
            .flatMap({[weak self] _ -> Observable<[TemplateBanner]> in
                guard let self = self else { return .just([]) }
                return self.networkAPI.fetchTemplateBanner()
            })
            
        // filter by docsType
        let filterSequence = input.galleryFilterType

        return Observable
            .combineLatest(getDataSequence, filterSequence)
            .observeOn(self.serialQueue)
            .do(onNext: { [weak self] in self?.templateBanners = $0.0 })
            .map { [weak self] (_, filteredType) -> Event<[TemplateBanner]> in
                guard let self = self else { return .completed }
                let filteredData = self.filterTemplateBanner(filteredType: filteredType)
                return .next(filteredData)
            }
            .observeOn(MainScheduler.instance)
            .share()
    }()

    lazy var showFilterView: Observable<[FilterItem]> = {
        return input.showFilterView.map {[weak self] (mainType) -> [FilterItem] in
            guard let self = self else { return [] }
            return self.getItems(by: self.filterType(of: mainType))
        }
    }()

    // depandency
    private let networkAPI: TemplateCenterNetworkAPI
    private let cacheAPI: TemplateCenterCacheAPI
    private let shouldCacheFilter: Bool

    // dataSource
    // update safely
    private(set) var galleryCategories: [Category] = []
    private(set) var customDataSource: CustomTemplates = .empty
    private(set) var businessCategories: [Category] = []
    private(set) var templateBanners: [TemplateBanner] = []

    private(set) var filterTypes: [FilterItem.FilterType] = [.all, .doc, .sheet, .mindnote]
    private let bag = DisposeBag()
    public var templateSource: String?

    public init(depandency: ( networkAPI: TemplateCenterNetworkAPI, cacheAPI: TemplateCenterCacheAPI),
                shouldCacheFilter: Bool = true) {
        self.networkAPI = depandency.networkAPI
        self.cacheAPI = depandency.cacheAPI
        self.shouldCacheFilter = shouldCacheFilter
        self.addMoreFilterTypes()
        self.handleFilterTypeCache()
        self.handleForceRefresh()
    }
    
    private func addMoreFilterTypes() {
        let bitableTemplateEnable = ReleaseConfig.isPrivateKA ? LKFeatureGating.bitableTemplateEnable : true
        if bitableTemplateEnable {
            filterTypes.append(.bitable)
        }
    }

    deinit {
        DocsLogger.info("📖📖📖TemplateCenterViewModel deinit")
    }
    
    private func filterTemplateBanner(filteredType: FilterItem.FilterType) -> [TemplateBanner] {
        
        guard !templateBanners.isEmpty else { return [] }
        
        let targetTypes = Set(FilterItem.convertType(filterType: filteredType).map { $0.rawValue })
        guard !targetTypes.isEmpty else { return templateBanners }
        return templateBanners.filter { banner in
            guard let typeList = banner.objTypeList else {
                return false
            }
            let types = Set(typeList)
            return !targetTypes.isDisjoint(with: types)
        }
//        if let targetType = FilterItem.convertType(filterType: filteredType).first?.rawValue {
//            return templateBanners.filter { banner in
//                if let typeList = banner.objTypeList {
//                    return typeList.contains(targetType)
//                } else {
//                    return false
//                }
//            }
//        } else {
//            return templateBanners
//        }
    }
    /// 添加“新建空白文档”
    private func insertCreateBlankDocsIfNeed(event: Event<Categories>, filterType: FilterItem.FilterType) -> Event<Categories> {
        guard createBlankDocs, filterType != .all,
              let docsType = docsTypeForCreateBlankDocs(filterType: filterType) else {
            if self.shouldUseNewForm() {
                switch event {
                case .next(let categories):
                    if let allCategory = categories.first(where: { $0.name == BundleI18n.SKResource.Doc_List_All }) {
                        if let firstSection = allCategory.sections.first {
                            let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_bitable_form_template"))
                            let lang = BundleI18n.currentLanguage.rawValue
                            let surveyTemplateMaps = settings?["surveyTemplate"] as? [String: Any] ?? [:]
                            let fallback = surveyTemplateMaps["fallback"] as? [String: String] ?? [:]
                            let surveyI18nId = surveyTemplateMaps["i18nId"] as? String
                            let i18nId = surveyI18nId ?? settings?["i18nId"] as? String
                            // 做前缀匹配
                            var objToken = fallback["objToken"] ?? ""
                            var templateId = fallback["templateId"] ?? ""
                            for item in surveyTemplateMaps {
                                if lang.hasPrefix(item.key) {
                                    if let map = item.value as? [String: String] {
                                        objToken = map["objToken"] ?? ""
                                        templateId = map["templateId"] ?? ""
                                    }
                                    break
                                }
                            }
                            
                            let createBlankDocs = TemplateModel(
                                createTime: 0,
                                id: i18nId ?? templateId,
                                name: "",
                                objToken: objToken,
                                objType: 8,
                                updateTime: 0,
                                source: .createBlankDocs
                            )
                            createBlankDocs.templateSource = self.templateSource
                            if firstSection.templates.first?.source == .emptyData {
                                firstSection.templates.removeFirst()
                            }
                            firstSection.templates.insert(createBlankDocs, at: 0)
                            return .next(categories)
                        }
                    }
                default:
                    DocsLogger.info("insertCreateBlankDocsIfNeed lark_survey default")
                }
            }
            return event
        }
        let createBlankDocs = TemplateModel(createTime: 0,
                                            id: "",
                                            name: "",
                                            objToken: "",
                                            objType: docsType.rawValue,
                                            updateTime: 0,
                                            source: .createBlankDocs)
        let recentSection = Section(name: BundleI18n.SKResource.Doc_List_Frequently_Used, templates: [createBlankDocs])
        
        switch event {
        case .next(let categories):
            if let allCategory = categories.first(where: { $0.name == BundleI18n.SKResource.Doc_List_All }) {
                if let recentSection = allCategory.sections.first(where: { $0.name == BundleI18n.SKResource.Doc_List_Frequently_Used }) {
                    // 有新建空白文档，就不需要显示空数据提示
                    if recentSection.templates.first?.source == .emptyData {
                        recentSection.templates.removeFirst()
                    }
                    recentSection.templates.insert(createBlankDocs, at: 0)
                } else {
                    allCategory.sections.insert(recentSection, at: 0)
                }
                return .next(categories)
            } else {
                let allCategory = Category(id: "", name: BundleI18n.SKResource.Doc_List_All, sections: [recentSection])
                return .next([allCategory])
            }
        case .error(_):
            // 不能因为数据请求失败就不展示“新建空白文档”
            let allCategory = Category(id: "", name: BundleI18n.SKResource.Doc_List_All, sections: [recentSection])
            return .next([allCategory])
        case .completed:
            return .completed
        @unknown default:
            fatalError("unknown default")
        }
    }
    
    private func shouldUseNewForm() -> Bool {
        return self.templateSource == TemplateCenterTracker.TemplateSource.lark_survey.rawValue || self.templateSource == TemplateCenterTracker.TemplateSource.baseHomepageLarkSurvey.rawValue || self.templateSource == TemplateCenterTracker.TemplateSource.spaceHomepageLarkSurvey.rawValue || self.templateSource == TemplateCenterTracker.TemplateSource.wikiHomepageLarkSurvey.rawValue
    }
    
    private func docsTypeForCreateBlankDocs(filterType: FilterItem.FilterType) -> DocsType? {
        switch filterType {
        case .doc: return docxEnable ? .docX : .doc
        case .sheet: return .sheet
        case .bitable: return .bitable
        case .mindnote: return .mindnote
        default: return nil
        }
    }

    private func handleFilterTypeCache() {
        guard shouldCacheFilter else {
            DocsLogger.info("should not cache the filter item")
            return
        }

        input.galleryFilterType
            .skip(1)
            .subscribe(onNext: {[weak self] (type) in
                self?.cacheAPI.setFilterType(.gallery, type: type)
            }).disposed(by: bag)

        input.businessFilterType
            .skip(1)
            .subscribe(onNext: {[weak self] (type) in
                self?.cacheAPI.setFilterType(.business, type: type)
            }).disposed(by: bag)

        input.customFilterType
            .skip(1)
            .subscribe(onNext: {[weak self] (type) in
                self?.cacheAPI.setFilterType(.custom, type: type)
            }).disposed(by: bag)
    }
    
    private func handleForceRefresh() {
        self.input.forceRefreshCustomTemplates
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            guard !self.customDataSource.isEmpty else { return }
            self.customDataSource = .empty
            self.input.customFilterType.accept(.all)
        })
        self.input.forceRefreshBusinessTemplates
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            guard !self.businessCategories.isEmpty else { return }
            self.businessCategories = []
            self.input.businessFilterType.accept(.all)
        })
    }

    private func getItems(by filterType: FilterItem.FilterType) -> [FilterItem] {
        var items = [FilterItem]()
        self.filterTypes.forEach { (type) in
            items.append(FilterItem(isSelected: filterType == type, filterType: type))
        }
        return items
    }
    
    private class func galleryCategories(from info: GalleryTemplateCategoriesInfo, templateSource: String? = nil) -> [Category] {
        guard let recTmplIds = info.recommendTmplIds,
              let tmplMetaDict = info.tmplMetaDict,
              let cateMetas = info.cateMetas,
              let cateIdToTmplIds = info.cateIdToTmplIds else {
            return []
        }
        var categories = [Category]()
        var sectionsForAllCategory = [Section]()
        let recommendSection = Section(
            name: BundleI18n.SKResource.Doc_List_Frequently_Used,
            templates: Self.getTemplates(with: recTmplIds, from: tmplMetaDict)
        )
        sectionsForAllCategory.append(recommendSection)
        for cateMeta in cateMetas {
            guard let tmplIds = cateIdToTmplIds[cateMeta.categoryId] else {
                continue
            }
            let templates = Self.getTemplates(with: tmplIds, from: tmplMetaDict)
            let section = Section(
                name: cateMeta.name,
                templates: templates
            )
            sectionsForAllCategory.append(section)
            if let copySection = section.copy() as? Section {
                let category = Category(id: cateMeta.categoryId, name: cateMeta.name, sections: [copySection])
                categories.append(category)
            }
        }
        let allCategory = Category(id: "", name: BundleI18n.SKResource.Doc_List_All, sections: sectionsForAllCategory)
        allCategory.hasMore = false
        categories.insert(allCategory, at: 0)
        
        return categories
    }
    private class func getTemplates(with ids: [String], from templateMap: [String: TemplateModel]) -> [TemplateModel] {
        var templates: [TemplateModel] = []
        for id in ids {
            if let template = templateMap[id] {
                templates.append(template)
            }
        }
        if templates.isEmpty {
            templates.append(TemplateModel.emptyData)
        }
        return templates
    }
    
    private class func customCategories(from customTemplates: CustomTemplates) -> Categories {
        var filterNames: [String] = [BundleI18n.SKResource.Doc_List_All]
        var categories: [Category] = []

        // my templates
        // will not append to categories if no data and no Filter type
        var ownTemplates = customTemplates.own
        if ownTemplates.isEmpty {
            let emptyData = TemplateModel.emptyData
            emptyData.tag = .customOwn
            ownTemplates.append(emptyData)
        }
        filterNames.append(BundleI18n.SKResource.Doc_List_My_Template)
        let ownSection = Section(
            name: BundleI18n.SKResource.Doc_List_My_Template,
            templates: ownTemplates
        )
        let ownCategory = Category(
            id: String(TemplateCategory.SpecialCategoryId.mine.rawValue),
            name: BundleI18n.SKResource.Doc_List_My_Template,
            sections: [ownSection]
        )
        ownCategory.hasMore = false
        categories.append(ownCategory)

        // share with me
        var shareTemplates = customTemplates.share
        if shareTemplates.isEmpty {
            let emptyData = TemplateModel.emptyData
            emptyData.tag = .customShare
            shareTemplates.append(emptyData)
        }
        let shareSection = Section(
            name: BundleI18n.SKResource.Doc_List_Share_With_Me,
            templates: shareTemplates
        )
        let shareCategory = Category(
            id: String(TemplateCategory.SpecialCategoryId.sharedWithMe.rawValue),
            name: BundleI18n.SKResource.Doc_List_Share_With_Me,
            sections: [shareSection]
        )
        shareCategory.hasMore = customTemplates.hasMore
        categories.append(shareCategory)

        let allCategory = Category(
            id: "",
            name: BundleI18n.SKResource.Doc_List_All,
            sections: [ownSection, shareSection]
        )
        allCategory.hasMore = customTemplates.hasMore
        categories.insert(allCategory, at: 0)
        return categories
    }
    private class func businessCategories(from: [TemplateCategory]) -> Categories {
        return from.map({
            let name = $0.name.isEmpty ? BundleI18n.SKResource.Doc_List_EnterpriseTemplate : $0.name
            let section = Section(name: name, templates: $0.templates)
            let category = Category(id: "", name: name, sections: [section])
            category.hasMore = false
            return category
        }).filter({ !($0.sections.first?.templates.isEmpty ?? true) })
    }
    
    private func docsType(from filterType: FilterItem.FilterType) -> DocsType? {
        var docsType = FilterItem.convertType(filterType: filterType).first
        if docsType == .doc, self.docxEnable {
            docsType = .docX
        } else if docsType == .docX, !self.docxEnable {
            docsType = .doc
        }
        return docsType
    }
    
    func isDataSourceEmpty(of mainType: TemplateMainType) -> Bool {
        switch mainType {
        case .gallery: return galleryCategories.isEmpty
        case .custom: return customDataSource.isEmpty
        case .business: return businessCategories.isEmpty
        }
    }
    func inputFilterType(of mainType: TemplateMainType) -> BehaviorRelay<FilterItem.FilterType> {
        switch mainType {
        case .gallery: return input.galleryFilterType
        case .custom: return input.customFilterType
        case .business: return input.businessFilterType
        }
    }
    func filterType(of mainType: TemplateMainType) -> FilterItem.FilterType {
        return inputFilterType(of: mainType).value
    }
    private class func isEmptyOf(businessTemplates: Categories) -> Bool {
        return businessTemplates.allSatisfy({ $0.sections.isEmpty })
    }
}

extension TemplateCenterViewModel {
    class Category {
        let id: String
        let name: String
        var currentPage = 0
        var hasMore = true
        var sections: [Section]
        init(id: String, name: String, sections: [Section]) {
            self.id = id
            self.name = name
            self.sections = sections
        }
    }
    
    class Section: NSCopying {
        let name: String
        var templates: [TemplateModel]
        init(name: String, templates: [TemplateModel]) {
            self.name = name
            self.templates = templates
        }
        func copy(with zone: NSZone? = nil) -> Any {
            let copy = Section(name: name, templates: templates)
            return copy
        }
        func appendNewTemplates(_ newTemplates: [TemplateModel]) {
            let existIds = Set(templates.map({ $0.id }))
            templates.append(contentsOf: newTemplates.filter({ !existIds.contains($0.id) }))
        }
    }
    
    public final class CategoryPageInfo: Codable {
        let categoryId: String
        let hasMore: Bool
        let pageIndex: Int
        let templates: [TemplateModel]
        init(categoryId: String, templates: [TemplateModel], pageIndex: Int, hasMore: Bool) {
            self.hasMore = hasMore
            self.pageIndex = pageIndex
            self.templates = templates
            self.categoryId = categoryId
        }
        
        enum Codingkeys: String, CodingKey {
            case categoryId
            case hasMore
            case pageIndex
            case templates
        }
        
        func toExternalItem() -> TemplateCategoryPageInfo {
            let items = self.templates.map { $0.toExternalItem() }
            let page = TemplateCategoryPageInfo(categoryId: self.categoryId,
                                                templates: items,
                                                pageIndex: self.pageIndex,
                                                hasMore: self.hasMore)
            return page
        }
    }
}


public extension TemplateModel {
    static func createBlankSurvey(templateSource: TemplateCenterTracker.TemplateSource?) -> TemplateModel? {
        guard let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_bitable_form_template")) else {
            DocsLogger.info("ccm_bitable_form_template setting error")
            return nil
        }
        let lang = BundleI18n.currentLanguage.rawValue
        let surveyTemplateMaps = settings["surveyTemplate"] as? [String: Any] ?? [:]
        let fallback = surveyTemplateMaps["fallback"] as? [String: String] ?? [:]
        let surveyI18nId = surveyTemplateMaps["i18nId"] as? String
        let i18nId = surveyI18nId ?? settings["i18nId"] as? String
        // 做前缀匹配
        var objToken = fallback["objToken"] ?? ""
        var templateId = fallback["templateId"] ?? ""
        for item in surveyTemplateMaps {
            if lang.hasPrefix(item.key) {
                if let map = item.value as? [String: String] {
                    objToken = map["objToken"] ?? ""
                    templateId = map["templateId"] ?? ""
                }
                break
            }
        }
        let blankSurveyId: String = i18nId ?? templateId
        guard !objToken.isEmpty, !blankSurveyId.isEmpty else {
            DocsLogger.info("ccm_bitable_form_template setting objToken or templateId is error")
            return nil
        }
        let blankSurveyModel = TemplateModel(
            createTime: 0,
            id: blankSurveyId,
            name: "",
            objToken: objToken,
            objType: DocsType.bitable.rawValue,
            updateTime: 0,
            source: .createBlankDocs
        )
        blankSurveyModel.templateSource = templateSource?.rawValue
        return blankSurveyModel
    }
    
    /* 目前通过该拓展方法避免WIKI引入业务细节 */
    func fileType() -> String {
        return shouldUseNewForm() ? "new_form_templates" : ""
    }
    
}
