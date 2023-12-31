//
//  TemplateHorizontalListViewModel.swift
//  SKCommon
//
//  Created by lijuyou on 2023/6/2.
//  


import Foundation
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import SKFoundation
import SpaceInterface


public final class TemplateHorizontalListViewModel {

    /// 从模板创建
    private let createByTemplateHandler: (TemplateModel, UIViewController) -> Void
    /// 打开更多模板页
    private let moreTemplateHandler: (UIViewController) -> Void
    /// 模板中心API
    private let templateProvider: TemplateCenterNetworkAPI
    /// 模板缓存
    private let templateCache: TemplateCenterCacheAPI
    private let dataQueue = SerialDispatchQueueScheduler(internalSerialQueueName: "ccm.template.horizontalList")
    private let disposeBag = DisposeBag()
    private let categoryId: String
    private let pageSize: Int
    private let docsType = DocsType.docX
    private let uiConfig: HorizontalTemplateUIConfig?

    public init(categoryId: String,
                pageSize: Int,
                uiConfig: HorizontalTemplateUIConfig?,
                templateProvider: TemplateCenterNetworkAPI,
                templateCache: TemplateCenterCacheAPI,
                createByTemplateHandler: @escaping (TemplateModel, UIViewController) -> Void,
                moreTemplateHandler: @escaping (UIViewController) -> Void) {
        self.categoryId = categoryId
        self.pageSize = pageSize
        self.uiConfig = uiConfig
        self.templateProvider = templateProvider
        self.templateCache = templateCache
        self.createByTemplateHandler = createByTemplateHandler
        self.moreTemplateHandler = moreTemplateHandler
    }

    func setup(templateView: TemplateHorizontalListView) {
        // 用于分页拉取模版的请求参数
        let pageIndex = 1
        let suggestPageSize = 200
        let pageSize = max(suggestPageSize, self.pageSize)

        let templateUpdatedHandler: (Event<TemplateCenterViewModel.CategoryPageInfo>) -> Void = { [weak templateView, weak self] event in
            guard let templateView = templateView, let self = self else { return }
            templateView.endLoading()
            switch event {
            case let .next(pageInfo):
                pageInfo.templates.forEach {
                    if self.uiConfig?.hideItemSubTitle ?? false {
                        $0.bottomLabelType = TemplateModel.BottomLabelTypeValue.hidden.rawValue
                    } else {
                        $0.bottomLabelType = TemplateModel.BottomLabelTypeValue.createTime.rawValue
                    }
                }
                templateView.updateData(pageInfo.templates, hasMore: pageInfo.hasMore)
                DocsLogger.info("getCategoryPageInfo from network success, begin save locally, count:\(pageInfo.templates.count)", component: LogComponents.docComponent)
                self.templateCache.setCategoryPageInfo(pageInfo,
                                                       for: pageSize,
                                                       docsType: self.docsType,
                                                       docxEnable: true)
            case let .error(error):
                DocsLogger.error("update templates failed", error: error, component: LogComponents.template)
                if templateView.templateDataSource.isEmpty {
                    templateView.showFailedView()
                } else {
                    DocsLogger.error("update templates failed, showing cache data", component: LogComponents.template)
                }
            case .completed:
                return
            @unknown default:
                return
            }
        }
        templateView.startLoading()
        let fetchRemoteData = templateProvider.fetchTemplates(of: self.categoryId,
                                                              at: pageIndex,
                                                              pageSize: pageSize,
                                                              docsType: self.docsType,
                                                              docxEnable: true)
        let fetchCacheData = templateCache.getCategoryPageInfo(of: self.categoryId,
                                                               at: pageIndex,
                                                               pageSize: pageSize,
                                                               docsType: self.docsType,
                                                               docxEnable: true)
        Observable.merge(fetchCacheData,
                         fetchRemoteData)
            .observeOn(dataQueue)
            .materialize()
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: templateUpdatedHandler)
            .disposed(by: disposeBag)
    }

    func handleClickMore(createController: UIViewController) {
        moreTemplateHandler(createController)
    }

    func createBy(template: TemplateModel, createController: UIViewController) {
        createByTemplateHandler(template, createController)
    }
}
