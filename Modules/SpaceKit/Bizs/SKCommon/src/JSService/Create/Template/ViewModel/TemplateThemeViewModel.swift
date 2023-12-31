//
//  TemplateThemeViewModel.swift
//  SKCommon
//
//  Created by SZEECI on 2021/1/22.
//

import SKFoundation
import RxSwift
import RxCocoa
import LarkReleaseConfig
import SpaceInterface
import SKInfra

public final class TemplateThemeViewModel {
    
    // Input
    struct InputBridge {
        let cacheAPI: TemplateCenterCacheAPI
        // fetch all templates of topic
        let initTemplates = PublishSubject<Void>()
        
        let filterTemplates = BehaviorRelay<FilterItem.FilterType>(value: .all)
        
        // present filter view
        let showFilterView = PublishSubject<Void>()
        
    }

    private(set) var gallerySearchResult = TemplateSearchResult.createEmptyResult()
    
    private(set) var filterTypes: [FilterItem.FilterType] = [.all, .doc, .sheet, .mindnote]
    private(set) var objType: DocsType?
    public static let defaultTopicId = -1
    private let defaultPageSize = 500
    private let defaultPageIndex = 1
    
    lazy var showFilterView: Observable<[FilterItem]> = {
        input.showFilterView.map { [weak self] () -> [FilterItem] in
            guard let self = self else { return [] }
            var items = [FilterItem]()
            self.filterTypes.forEach { (type) in
                items.append(FilterItem(isSelected: self.input.filterTemplates.value == type, filterType: type))
            }
            return items
        }
    }()

    lazy var input: InputBridge = { InputBridge(cacheAPI: self.cacheAPI) }()
    
    // depandency
    private let networkAPI: TemplateCenterNetworkAPI
    private let cacheAPI: TemplateCenterCacheAPI
    private let topID: Int
    private let categoryId: Int?  //支持TopicId和categoryId两种模式
    private let docComponentSceneId: String?
    public var isFromDocComponent: Bool {
        !(self.docComponentSceneId?.isEmpty ?? true)
    }
    
    var templatePageConfig: TemplatePageConfig?
    
    private let serialQueue = SerialDispatchQueueScheduler(internalSerialQueueName: "ccm.bytedance.template.topicListViewmodel")
    
    private(set) var templateThemeResult: TemplateThemeResult?

    private(set) var bannerImageRelay = BehaviorRelay<UIImage?>(value: nil)
    private let disposeBag = DisposeBag()
    public init(networkAPI: TemplateCenterNetworkAPI,
                cacheAPI: TemplateCenterCacheAPI,
                topID: Int,
                categoryId: Int? = nil,
                docComponentSceneId: String? = nil,
                objType: Int? = nil) {
        self.networkAPI = networkAPI
        self.cacheAPI = cacheAPI
        self.topID = topID
        self.categoryId = categoryId
        self.docComponentSceneId = docComponentSceneId
        if let objType = objType {
            self.objType = DocsType(rawValue: objType)
        }
        addMoreFilterTypes()
    }
    
    private func addMoreFilterTypes() {
        let bitableTemplateEnable = ReleaseConfig.isPrivateKA ? LKFeatureGating.bitableTemplateEnable : true
        if bitableTemplateEnable {
            filterTypes.append(.bitable)
        }
    }
    
    var isCategoryMode: Bool {
        return topID < 0 && categoryId != nil
    }
    
    // Output
    lazy var templateThemeResultUpdated: Observable<Event<TemplateThemeResult>> = {
        if isCategoryMode {
            // 使用分类场景
            return templateCategoryResultUpdated
        }
        // try to get data from cache firstly
        // when request callback, update the data in cache
        let getDataSequence = input
            .initTemplates
            .flatMap({[weak self] _ -> Observable<Event<TemplateThemeResult>> in
                guard let self = self else { return .never() }
                return Observable.merge(self.cacheAPI.getTopicTemplatesResult(for: self.topID),
                                        self.networkAPI.fetchTemplateTheme(topicID: self.topID, docType: nil)
                                            .do(onNext: { [weak self] (result) in
                                                DocsLogger.info("📖📖📖 fetch topic templates from network success, begin save locally")
                                                guard let self = self else { return }
                                                self.cacheAPI.setTopicTemplatesResult(result, for: self.topID)
                                        }))
                    .observeOn(self.serialQueue)
                    .materialize()
                    .filter { [weak self] (event) -> Bool in
                        switch event {
                        case .next:
                            return true
                        case .completed, .error:
                            // 有缓存，不处理网络错误
                            return self?.templateThemeResult?.templates.isEmpty ?? true
                        @unknown default:
                            return false
                        }
                    }
            })

        // filter by docsType
        let filterSequence = input.filterTemplates

        return Observable
            .combineLatest(getDataSequence, filterSequence)
            .observeOn(self.serialQueue)
            .map {[weak self] (event, filteredType) -> Event<TemplateThemeResult> in
                guard let self = self else { return .completed }
                return self.filterDataSource(event: event, filteredType: filteredType)
            }
            .observeOn(MainScheduler.instance)
            .share()
    }()
    
    // Output for Category
    private lazy var templateCategoryResultUpdated: Observable<Event<TemplateThemeResult>> = {
        // try to get data from cache firstly
        // when request callback, update the data in cache
        let getDataSequence = input
            .initTemplates
            .flatMap({[weak self] _ -> Observable<Event<TemplateThemeResult>> in
                guard let self = self else { return .never() }
                guard let categoryId = self.categoryId else {
                    DocsLogger.error("must have categoryId", component: LogComponents.template)
                    return .never()
                }
                
                let transform = { (pageInfo: TemplateCenterViewModel.CategoryPageInfo) -> TemplateThemeResult in
                    pageInfo.templates.forEach {
                        if self.templatePageConfig?.hideItemSubTitle ?? false {
                            $0.bottomLabelType = TemplateModel.BottomLabelTypeValue.hidden.rawValue
                        } else {
                            $0.bottomLabelType = TemplateModel.BottomLabelTypeValue.createTime.rawValue
                        }
                    }
                    let model = TemplateThemeResult(templateBanner: nil, templates: pageInfo.templates)
                    return model
                }
                let fetchCacheData = self.cacheAPI.getCategoryPageInfo(of: String(categoryId),
                                                                       at: self.defaultPageIndex,
                                                                       pageSize: self.defaultPageSize,
                                                                       docsType: self.objType,
                                                                       docxEnable: true).map(transform)
                
                let fetchRemoteData = self.networkAPI.fetchTemplates(of: String(categoryId),
                                                                     at: self.defaultPageIndex,
                                                                     pageSize: self.defaultPageSize,
                                                                     docsType: self.objType,
                                                                     docxEnable: true)
                    .do(onNext: { [weak self] (pageInfo) in
                        guard let self = self else { return }
                        DocsLogger.info("📖📖📖 fetch category templates from network success, begin save locally, count:\(pageInfo.templates.count)", component: LogComponents.template)
                        self.cacheAPI.setCategoryPageInfo(pageInfo,
                                                          for: self.defaultPageSize,
                                                          docsType: self.objType,
                                                          docxEnable: true)
                    }).map(transform)
                
                return  Observable.merge(fetchCacheData,
                                         fetchRemoteData)
                    .observeOn(self.serialQueue)
                    .materialize()
                    .filter { [weak self] (event) -> Bool in
                        switch event {
                        case .next:
                            return true
                        case .completed, .error:
                            // 有缓存，不处理网络错误
                            return self?.templateThemeResult?.templates.isEmpty ?? true
                        @unknown default:
                            return false
                        }
                    }
            })

        // filter by docsType
        let filterSequence = input.filterTemplates

        return Observable
            .combineLatest(getDataSequence, filterSequence)
            .observeOn(self.serialQueue)
            .map {[weak self] (event, filteredType) -> Event<TemplateThemeResult> in
                guard let self = self else { return .completed }
                return self.filterDataSource(event: event, filteredType: filteredType)
            }
            .observeOn(MainScheduler.instance)
            .share()
    }()
    
    private func downloadBannerImageIfNeed() {
        guard bannerImageRelay.value == nil, let banner = templateThemeResult,
              let imageUrl = banner.templateBanner?.imageUrl, !imageUrl.isEmpty,
              let url = URL(string: imageUrl) else { return }
        DispatchQueue.main.async {
            
            let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
            manager.getThumbnail(url: url, source: .template)
                .asDriver(onErrorJustReturn: UIImage())
                .drive(onNext: { [weak self] (image) in
                    self?.bannerImageRelay.accept(image)
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    private func filterDataSource(event: Event<TemplateThemeResult>,
                                  filteredType: FilterItem.FilterType) -> Event<TemplateThemeResult> {
        var filteredTypes: [Int] = []
        if filteredType == .doc {
            filteredTypes = [DocsType.doc.rawValue, DocsType.docX.rawValue]
        } else {
            if let type = FilterItem.convertType(filterType: filteredType).first?.rawValue {
                filteredTypes = [type]
            }
        }
        
        if case let .next(result) = event {
            var templates = result.templates
            if self.templatePageConfig?.showCreateBlankItem ?? false {
                templates.insert(createBlankItem(), at: 0)
            }
            let tempResult = TemplateThemeResult(templateBanner: result.templateBanner,
                                                templates: templates)
            self.templateThemeResult = tempResult
            self.downloadBannerImageIfNeed()
            if filteredTypes.isEmpty {
                return .next(tempResult)
            } else {
                let newTemplates = tempResult.templates.filter({ filteredTypes.contains($0.objType) })
                let newResult = TemplateThemeResult(templateBanner: tempResult.templateBanner,
                                                         templates: newTemplates)
                if newTemplates.isEmpty {
                    if filteredType == .all {
                        return .error(TemplateError.themeNoData)
                    } else {
                        return .error(TemplateError.filterTypeNoData)
                    }
                }
                return .next(newResult)
            }
        } else if case .error(_) = event {
            if self.templatePageConfig?.showCreateBlankItem ?? false {
                //error时也显示创建空白文档
                DocsLogger.error("show create black docs when error", component: LogComponents.template)
                let tempResult = TemplateThemeResult(templateBanner: nil,
                                                     templates: [createBlankItem()])
                return .next(tempResult)
            }
            return event
        }
        return event
    }
    
    private func createBlankItem() -> TemplateModel {
        let createBlankDocs = TemplateModel(createTime: 0,
                                            id: "",
                                            name: "",
                                            objToken: "",
                                            objType: self.objType?.rawValue ?? DocsType.docX.rawValue,
                                            updateTime: 0,
                                            source: .createBlankDocs)
        return createBlankDocs
    }
}
