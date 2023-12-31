//
//  TemplateCenterViewModelTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by 曾浩泓 on 2022/6/2.
//  


import XCTest
import RxSwift
import RxCocoa
import OHHTTPStubs
@testable import SKCommon
@testable import SKFoundation
import SpaceInterface
import SKInfra

class TemplateCenterCacheAPIMock {
    func getLocalData<T>(data: T) -> Observable<T> {
        return Observable.create { (observer) -> Disposable in
            observer.onNext(data)
            return Disposables.create()
        }
    }
}
extension TemplateCenterCacheAPIMock: TemplateCenterCacheAPI {
    func setCategoryPageInfo(_ pageInfo: SKCommon.TemplateCenterViewModel.CategoryPageInfo, for pageSize: Int?, docsType: SpaceInterface.DocsType?, docxEnable: Bool) {
        
    }
    
    func getCategoryPageInfo(of categoryId: String, at page: Int, pageSize: Int?, docsType: SpaceInterface.DocsType?, docxEnable: Bool) -> RxSwift.Observable<SKCommon.TemplateCenterViewModel.CategoryPageInfo> {
        Observable<SKCommon.TemplateCenterViewModel.CategoryPageInfo>.create { obj in
            return Disposables.create()
        }
    }
    
    func setGalleryCategories(_ categories: GalleryTemplateCategoriesInfo, docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) {}
    func setCustomTemplates(_ type: FilterItem.FilterType, _ templates: CustomTemplates) {}
    func setBusinessTemplates(_ type: FilterItem.FilterType, _ templates: BusinessTemplates) {}
    func setFilterType(_ mainType: TemplateMainType, type: FilterItem.FilterType) {}
    func setSuggestionTemplates(_ templates: [TemplateModel]) {}
    func setTopicTemplatesResult(_ templateThemeResult: TemplateThemeResult, for topic: Int) {}

    func getGalleryCategories(docsType: DocsType?, docxEnable: Bool, userRecommend: Bool) -> Observable<GalleryTemplateCategoriesInfo> {
        let cateMeta = TemplateCategoryMeta(name: "local category", categoryId: "1")
        let tmplMedol = TemplateModel(createTime: 0, id: "1", name: "", objToken: "", objType: 22, updateTime: 0, source: .system)
        let info = GalleryTemplateCategoriesInfo(cateMetas: [cateMeta], tmplMetaDict: ["1": tmplMedol], cateIdToTmplIds: ["1": ["1"]], recommendTmplIds: ["1"])
        return getLocalData(data: info)
    }
    func getCustomTemplates(filteredType: FilterItem.FilterType) -> Observable<CustomTemplates> {
        let templates = CustomTemplates(hasMore: false, own: [], share: [], shareIndex: "", users: [:])
        return getLocalData(data: templates)
    }
    func getBusinessTemplates(filteredType: FilterItem.FilterType) -> Observable<BusinessTemplates> {
        let data = TemplateCategory(name: "", templates: [])
        return getLocalData(data: [data])
    }
    func getSuggestionTemplates() -> Observable<[TemplateModel]> {
        let data = TemplateModel(createTime: 0, id: "", name: "", objToken: "", objType: 0, updateTime: 0, source: .system)
        return getLocalData(data: [data])
    }
    func getTopicTemplatesResult(for topic: Int) -> Observable<TemplateThemeResult> {
        let data = TemplateThemeResult(templateBanner: nil, templates: [])
        return getLocalData(data: data)
    }
}

class TemplateCenterViewModelTests: XCTestCase {

    var viewModel: TemplateCenterViewModel!
    var disposeBag: DisposeBag!
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        setupStub()
        disposeBag = DisposeBag()
        
        let dataProvider = TemplateDataProvider()
        let cacheDataProvider = TemplateCenterCacheAPIMock()
        viewModel = TemplateCenterViewModel(depandency: (dataProvider, cacheDataProvider))
    }
    
    private func setupStub() {
        HttpStubHelper.stubSuccess(
            apiPath: OpenAPI.APIPath.getSystemTemplateV2,
            jsonFileName: "TemplateSysListV2"
        )
        HttpStubHelper.stubSuccess(
            apiPath: OpenAPI.APIPath.getTemplateCenterBanner,
            jsonFileName: "TemplateBanner"
        )
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        disposeBag = nil
    }
    
    func testGalleryCategorySource() {
        let expectLocal = expectation(description: "get local GalleryCategory")
        let expectNetwork = expectation(description: "get online GalleryCategory")
        var hasLocalData = false
        viewModel.galleryCategoryUpdated.subscribe(onNext: { event in
            switch event {
            case .next(let data):
                XCTAssertFalse(data.isEmpty, "gallery category data is empty")
                if data[1].name.isEqual(to: "local category") {
                    expectLocal.fulfill()
                    hasLocalData = true
                } else {
                    XCTAssertTrue(hasLocalData, "use local data first")
                    expectNetwork.fulfill()
                }
            case .error(let e):
                XCTFail("occur error:\(e)")
            case .completed: break
            @unknown default: break
            }
        }).disposed(by: disposeBag)
        viewModel.input.galleryFilterType.accept(.all)
        wait(for: [expectLocal, expectNetwork], timeout: 10)
    }
    
    func testGalleryCategoryContainBlank() {
        let expect = expectation(description: "test GalleryCategory contain blank docs type")
        viewModel.createBlankDocs = true
        var isFulfill = false
        viewModel.galleryCategoryUpdated.subscribe(onNext: { event in
            if isFulfill {
                return
            }
            switch event {
            case .next(let data):
                XCTAssertFalse(data.isEmpty, "gallery category data is empty")
                if let firstTmplSource = data.first?.sections.first?.templates.first?.source {
                    XCTAssertTrue(firstTmplSource == .createBlankDocs, "first template must be createBlankDocs")
                    expect.fulfill()
                    isFulfill = true
                } else {
                    XCTFail("can't get first template source")
                }
            case .error(let e):
                XCTFail("occur error:\(e)")
            case .completed: break
            @unknown default: break
            }
        }).disposed(by: disposeBag)
        viewModel.input.galleryFilterType.accept(.mindnote)
        wait(for: [expect], timeout: 10)
    }

    func testLoadAllTypeBanner() {
        let expect = expectation(description: "test TemplateCenterViewModel LoadAllTypeBannerData")
        loadBanner(filterType: .all, docsTypes: [.doc, .docX, .sheet, .bitable, .mindnote], expection: expect)
    }
    
    func testLoadDocTypeBanner() {
        let expect = expectation(description: "test TemplateCenterViewModel LoadDocTypeBannerData")
        loadBanner(filterType: .doc, docsTypes: [.doc, .docX], expection: expect)
    }
    
    private func loadBanner(filterType: FilterItem.FilterType, docsTypes: [DocsType], expection: XCTestExpectation) {
        viewModel.templateBannerUpdated.subscribe(onNext: { (event) in
            switch event {
            case .next(let data):
                XCTAssertTrue(!data.isEmpty, "banners is empty")
                let allTypes = Set(docsTypes.map { $0.rawValue })
                let allSatisfy = data.allSatisfy { banner in
                    let objTypes: Set<Int> = Set(banner.objTypeList ?? [])
                    return !objTypes.isDisjoint(with: allTypes)
                }
                XCTAssertTrue(allSatisfy, "should get doc/docx banner")
                expection.fulfill()
            case .error(_):
                XCTFail("occur error")
            case .completed: break
            @unknown default: break
            }
        }).disposed(by: disposeBag)
        viewModel.input.galleryFilterType.accept(filterType)
        viewModel.input.initTemplateBanner.onNext(())
        wait(for: [expection], timeout: 10)
    }

}
