//
//  TemplateSearchViewModel.swift
//  SKCommon
//
//  Created by bytedance on 2021/1/4.
//

import Foundation
import RxSwift
import RxCocoa
import SKResource
import SpaceInterface

class TemplateSearchViewModel {
    // depandency
    private let networkAPI: TemplateCenterNetworkAPI
    
    var searchText = PublishRelay<String>()
    
    var keyword: String?
    
    var docxEnable = false
    
    var templateSource: String?
    
    private(set) var gallerySearchResult = TemplateSearchResult.createEmptyResult()
    private(set) var customSearchResult = TemplateSearchResult.createEmptyResult()
    private(set) var businessSearchResult = TemplateSearchResult.createEmptyResult()

    init(networkAPI: TemplateCenterNetworkAPI) {
        self.networkAPI = networkAPI
    }

    func searchFirstPageTemplates(searchKey: String, docsType: DocsType? = nil, tabType: TemplateMainType) -> Observable<TemplateSearchResult> {
        return networkAPI.searchTemplates(
            keyword: searchKey,
            offset: 0,
            docsType: docsType,
            docxEnable: docxEnable,
            tabType: tabType,
            userRecommend: false,
            buffer: ""
        ).map { [weak self] (pageModel) in
            let templates = pageModel.data ?? []
            let tpls = templates.map {
                let tpl = $0
                tpl.templateSource = self?.templateSource
                return tpl
            }
            
            let hasMore = pageModel.hasMore ?? false
            let buffer = pageModel.buffer ?? ""
            let result = TemplateSearchResult(keyword: searchKey, templates: tpls, hasMore: hasMore, buffer: buffer)
            self?.setResult(result, for: tabType)
            return result
        }
    }
    func searchNextPageTemplates(docsType: DocsType? = nil, tabType: TemplateMainType) -> Observable<TemplateSearchResult> {
        let lastResult = getResult(with: tabType)
        return networkAPI.searchTemplates(
            keyword: lastResult.keyword,
            offset: lastResult.templates.count,
            docsType: docsType,
            docxEnable: docxEnable,
            tabType: tabType,
            userRecommend: false,
            buffer: lastResult.buffer
        ).map { [weak self] (pageModel) in
            let templates = pageModel.data ?? []
            let hasMore = pageModel.hasMore ?? false
            let buffer = pageModel.buffer ?? ""
            let tpls = templates.map {
                let tpl = $0
                tpl.templateSource = self?.templateSource
                return tpl
            }
            let result = TemplateSearchResult(
                keyword: lastResult.keyword,
                templates: lastResult.templates + tpls,
                hasMore: hasMore,
                buffer: buffer
            )
            self?.setResult(result, for: tabType)
            return result
        }
    }
    
    func fetchSearchTemplateRecommend() -> Observable<[TemplateSearchRecommend]> {
        return networkAPI.fetchSearchRecommend()
    }
    
    func deleteTemplateInMemory(templateToken: String) -> Observable<TemplateSearchResult> {
        self.customSearchResult.templates = self.customSearchResult.templates.filter({ $0.objToken != templateToken })
        return .just(self.customSearchResult)
    }
    
    func clearAllData() {
        let empty = TemplateSearchResult.createEmptyResult()
        gallerySearchResult = empty
        customSearchResult = empty
        customSearchResult = empty
    }
    
    func getResult(with tabType: TemplateMainType) -> TemplateSearchResult {
        switch tabType {
        case .gallery:
            return gallerySearchResult
        case .custom:
            return customSearchResult
        case .business:
            return businessSearchResult
        }
    }
    private func setResult(_ result: TemplateSearchResult, for type: TemplateMainType) {
        switch type {
        case .gallery:
            gallerySearchResult = result
        case .custom:
            customSearchResult = result
        case .business:
            businessSearchResult = result
        }
    }
}
