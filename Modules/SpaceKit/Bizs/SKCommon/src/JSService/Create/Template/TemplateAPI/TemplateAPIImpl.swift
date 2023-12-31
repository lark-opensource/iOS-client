//
//  TemplateAPIImpl.swift
//  SKCommon
//
//  Created by lijuyou on 2023/6/2.
//  


import SKFoundation
import SpaceInterface
import RxSwift
import SKInfra
import EENavigator

public final class TemplateAPIImpl: TemplateAPI {
    
    public static let shared = TemplateAPIImpl()
    
    private lazy var templateDataProvider: TemplateDataProvider = {
        TemplateDataProvider()
    }()
    private let dataQueue = SerialDispatchQueueScheduler(internalSerialQueueName: "ccm.template.horizontalList")
    private let disposeBag = DisposeBag()
    
    public func createDocsByTemplate(docType: Int,
                                     docToken: String?,
                                     templateId: String?,
                                     templateSource: String?,
                                     titleParam: CreateDocTitleParams?,
                                     callback: ((DocsTemplateCreateResult?, Error?) -> Void)?) {
        var params = [String: Any]()
        if let token = docToken {
            params["token"] = token
        }
        if let templateId = templateId {
            params["template_id"] = templateId
        }
        if let titleParam = titleParam {
            if let title = titleParam.title {
                params["title"] = title
            }
            if let titlePrefix = titleParam.titlePrefix {
                params["title_prefix"] = titlePrefix
            }
            if let titleSuffix = titleParam.titleSuffix {
                params["title_suffix"] = titleSuffix
            }
        }
        var source: TemplateCenterTracker.TemplateSource?
        if let templateSource = templateSource {
            source = TemplateCenterTracker.TemplateSource(templateSource)
        }
        let req = DocsRequestCenter.createByTemplate(type: DocsType(rawValue: docType),
                                                     in: "",
                                                     parameters: params,
                                                     from: nil,
                                                     templateSource: source) { res, error in
            callback?(DocsTemplateCreateResult(url: res?.url ?? "",
                                            title: res?.title ?? ""), error)
        }
        req.makeSelfReferenced()
    }
    
    
    public func fetchTemplateData(categoryId: String,
                                  pageIndex: Int,
                                  pageSize: Int,
                                  docsType: DocsType?,
                                  templateSource: String?) -> Observable<TemplateCategoryPageInfo> {
        templateDataProvider.templateSource = templateSource
        let fetchDataAction =  templateDataProvider.fetchTemplates(of: categoryId,
                                                             at: pageIndex,
                                                             pageSize: pageSize,
                                                             docsType: docsType,
                                                             docxEnable: true)
        return fetchDataAction.flatMap { (data) -> Observable<TemplateCategoryPageInfo> in
            return .just(data.toExternalItem())
        }
    }
    
    public func deleteDoc(docToken: String, docType: Int) -> Completable {
        let type = DocsType(rawValue: docType)
        guard let spaceAPI = DocsContainer.shared.resolve(SpaceManagementAPI.self) else {
            spaceAssertionFailure()
            return .error(TemplateAPIError.runtimeError)
        }
        return Completable.create { completable in
            return spaceAPI.deleteInDoc(objToken: docToken, docType: type, canApply: false).subscribe { _ in
                completable(.error(TemplateAPIError.permissionError))
            } onError: { error in
                completable(.error(error))
            } onCompleted: {
                completable(.completed)
            }
        }
    }
    
    public func createTemplateHorizontalListView(frame: CGRect,
                                                 params: HorizontalTemplateParams,
                                                 delegate: TemplateHorizontalListViewDelegate) -> TemplateHorizontalListViewProtocol {
        let view = TemplateHorizontalListView(frame: frame,
                                              params: params,
                                              delegate: delegate)
        return view
    }
    
    public func createTemplateSelectedPage(param: CreateTemplatePageParam,
                                           fromVC: UIViewController,
                                           delegate: TemplateSelectedDelegate?) -> UIViewController? {
        var objType: Int? = param.dcSceneId != nil ? DocsType.docX.rawValue : nil
        let dataProvider = TemplateDataProvider()
        let topicId = TemplateThemeViewModel.defaultTopicId
        let categoryId = Int(param.categoryId)
        let vm = TemplateThemeViewModel(networkAPI: dataProvider,
                                        cacheAPI: dataProvider,
                                        topID: topicId,
                                        categoryId: categoryId,
                                        docComponentSceneId: param.dcSceneId,
                                        objType: objType)
        let source: TemplateCenterTracker.EnterTemplateSource = .promotionalDocs //此次没有新增定义
        let templateSource = TemplateCenterTracker.TemplateSource(param.templateSource)
        let vc = TemplateThemeListViewController(
            fromViewWidth: 0,
            viewModel: vm,
            filterType: nil,
            objType: objType,
            mountLocation: .spaceDefault,
            targetPopVC: fromVC,
            source: source,
            templateSource: templateSource
        )
        vc.selectedDelegate = delegate
        vc.templatePageConfig = param.templatePageConfig
        return vc
    }
}
