//
//  TemplateSearchViewModelTests.swift
//  SKCommon-Unit-Tests
//
//  Created by zoujie on 2022/11/30.
//  

import XCTest
import Foundation
import RxSwift
import SwiftyJSON
@testable import SKCommon
@testable import SKFoundation
import SpaceInterface

class TemplateMockDataProvider {
    static let pageSize: Int = 30
    let platform = "mobile"
    let parseDataQueue = DispatchQueue(label: "ccm.template.parse",
                                       qos: .default,
                                       attributes: .concurrent)
    let timeout: Double = 20.0     // 单次请求20s超时，DocsRequest有3次重试逻辑
    init() {}
}

extension TemplateMockDataProvider: TemplateCenterNetworkAPI {
    func fetchGalleryCategories(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> Observable<GalleryTemplateCategoriesInfo> {
        let info = GalleryTemplateCategoriesInfo(tmplMetaDict: ["mock": TemplateModel(createTime: 20_221_201,
                                                                                      id: "mock_templateModel",
                                                                                      name: "mock_templateModel",
                                                                                      objToken: "mock_objToken",
                                                                                      objType: 8,
                                                                                      updateTime: 20_221_201,
                                                                                      source: .business)])
        return .just(info)
    }
    func fetchTemplates(of categoryId: String, at page: Int, pageSize: Int?, docsType: DocsType?, docxEnable: Bool) -> Observable<TemplateCenterViewModel.CategoryPageInfo> {
        let info = TemplateCenterViewModel.CategoryPageInfo(categoryId: "mock_categoryId",
                                                            templates: [TemplateModel(createTime: 20_221_201,
                                                                                      id: "mock_templateModel",
                                                                                      name: "mock_templateModel",
                                                                                      objToken: "mock_objToken",
                                                                                      objType: 8,
                                                                                      updateTime: 20_221_201,
                                                                                      source: .business)],
                                                            pageIndex: 0,
                                                            hasMore: true)
        return .just(info)
    }
    func fetchCustomTemplates(objType: Int?, dataType: Int?, index: String, searchKey: String?) -> Observable<CustomTemplates> {
        return .just(CustomTemplates(hasMore: false,
                                     own: [TemplateModel(createTime: 20_221_201,
                                                         id: "mock_templateModel",
                                                         name: "mock_templateModel",
                                                         objToken: "mock_objToken",
                                                         objType: 8,
                                                         updateTime: 20_221_201,
                                                         source: .business)],
                                     share: [],
                                     shareIndex: "mock_shareIndex",
                                     users: [:]))
    }
    func fetchBusinessTemplates(objType: Int?, searchKey: String?) -> Observable<BusinessTemplates> {
        return .just(BusinessTemplates())
    }
    func fetchSuggestionTemplate() -> Observable<[TemplateModel]> {
        return .just([TemplateModel(createTime: 20_221_201,
                                    id: "mock_templateModel",
                                    name: "mock_templateModel",
                                    objToken: "mock_objToken",
                                    objType: 8,
                                    updateTime: 20_221_201,
                                    source: .business)])
    }
    func fetchSearchRecommend() -> Observable<[TemplateSearchRecommend]> {
        return .just([TemplateSearchRecommend(name: "mock_name")])
    }
    func fetchTemplateBanner() -> Observable<[TemplateBanner]> {
        return .just([TemplateBanner(bannerType: 0,
                                     imageToken: "mock_imageToken",
                                     topicId: 0,
                                     templateId: 0,
                                     objType: 8,
                                     objToken: "mock_objToken",
                                     objTypeList: nil)])
    }
    func fetchTemplateTheme(topicID: Int, docType: DocsType?) -> Observable<TemplateThemeResult> {
        return .just(TemplateThemeResult(templateBanner: nil, templates: [TemplateModel(createTime: 20_221_201,
                                                                                        id: "mock_templateModel",
                                                                                        name: "mock_templateModel",
                                                                                        objToken: "mock_objToken",
                                                                                        objType: 8,
                                                                                        updateTime: 20_221_201,
                                                                                        source: .business)]))
    }
    func deleteDIYTemplate(templateToken: String, objType: Int) -> Observable<(JSON?)> {
        return .just(nil)
    }
    func fetchTemplateCollection(id: String) -> Observable<TemplateCollection> {
        return .just(TemplateCollection(id: "mock_id", name: "mock_name", templates: [], appLink: nil))
    }
    func searchTemplates(
        keyword: String?,
        offset: Int,
        docsType: DocsType?,
        docxEnable: Bool,
        tabType: TemplateMainType?,
        userRecommend: Bool,
        buffer: String) -> Observable<PageModel<TemplateModel>> {
            var pageModel = PageModel<TemplateModel>(data: [TemplateModel(createTime: 20_221_201,
                                                                          id: "mock_templateModel",
                                                                          name: "mock_templateModel",
                                                                          objToken: "mock_objToken",
                                                                          objType: 8,
                                                                          updateTime: 20_221_201,
                                                                          source: .business)])
            return .just(pageModel)
        }
    func saveTemplateCollection(collectionId: String, parentFolderToken: String, folderVersion: Int) -> Observable<(TemplateCollectionSaveResult)> {
        return .just((TemplateCollectionSaveResult(folderToken: "mock_folderToken",
                                                   folderURL: "mock_folderURL",
                                                   tokenList: [])))
    }
    func deleteAllCustomTemplates() {}
    func deleteAllBusinessTemplates() {}
}

class TemplateSearchViewModelTests: XCTestCase {
    var viewModel: TemplateSearchViewModel?
    var disposeBag: DisposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()

        viewModel = TemplateSearchViewModel(networkAPI: TemplateMockDataProvider())
    }

    func testSearchFirstPageTemplates() {
        let expect = expectation(description: "test search firstPage templates")
        viewModel?.searchFirstPageTemplates(searchKey: "", docsType: .bitable, tabType: .business).subscribe(onNext: { result in
            let bitableCount = result.templates.filter({ $0.docsType == .bitable }).count
            XCTAssertTrue(bitableCount == 1)
            expect.fulfill()
        }).disposed(by: disposeBag)
        wait(for: [expect], timeout: 10)
    }

    func testSearchNextPageTemplates() {
        let expect = expectation(description: "test search nextPage templates")
        viewModel?.searchNextPageTemplates(docsType: .bitable, tabType: .business).subscribe(onNext: { result in
            let bitableCount = result.templates.filter({ $0.docsType == .bitable }).count
            XCTAssertTrue(bitableCount == 1)
            expect.fulfill()
        }).disposed(by: disposeBag)
        wait(for: [expect], timeout: 10)
    }
}
