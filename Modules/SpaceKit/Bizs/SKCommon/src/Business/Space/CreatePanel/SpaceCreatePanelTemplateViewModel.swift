//
//  SpaceCreatePanelTemplateViewModel.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/4/11.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import SKFoundation


public final class SpaceCreatePanelTemplateViewModel {

    private let createByTemplateHandler: (TemplateModel, UIViewController) -> Void
    private let moreTemplateHandler: (UIViewController) -> Void
    private let templateProvider: TemplateCenterNetworkAPI
    private let templateCache: TemplateCenterCacheAPI
    private let dataQueue = SerialDispatchQueueScheduler(internalSerialQueueName: "ccm.template.suggestion")
    private let disposeBag = DisposeBag()

    public init(templateProvider: TemplateCenterNetworkAPI,
                templateCache: TemplateCenterCacheAPI,
                createByTemplateHandler: @escaping (TemplateModel, UIViewController) -> Void,
                moreTemplateHandler: @escaping (UIViewController) -> Void) {
        self.templateProvider = templateProvider
        self.templateCache = templateCache
        self.createByTemplateHandler = createByTemplateHandler
        self.moreTemplateHandler = moreTemplateHandler
    }

    func setup(templateView: TemplateSuggestionView) {
        let templateUpdatedHandler: (Event<[TemplateModel]>) -> Void = { [weak templateView] event in
            guard let templateView = templateView else { return }
            templateView.endLoading()
            switch event {
            case let .next(templates):
                templateView.updateData(templates)
            case let .error(error):
                DocsLogger.error("update templates failed", error: error)
                if !DocsNetStateMonitor.shared.isReachable {
                    templateView.showNoNetView()
                } else if templateView.templateDataSource.isEmpty {
                    templateView.showFailedView()
                } else {
                    DocsLogger.error("update templates failed, showing cache data")
                }
            case .completed:
                return
            @unknown default:
                return
            }
        }
        templateView.startLoading()
        Observable.merge(templateCache.getSuggestionTemplates(),
                         templateProvider.fetchSuggestionTemplate())
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
