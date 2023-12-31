//
//  TemplateCollectionViewModel.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/5/28.
//  


import Foundation
import RxSwift
import SKFoundation
import SKResource

class TemplateCollectionViewModel {
    let templates: ReplaySubject<[TemplateModel]> = ReplaySubject<[TemplateModel]>.create(bufferSize: 1)
    let colletionName: PublishSubject<String> = PublishSubject()
    let error: PublishSubject<Void> = PublishSubject()
    let loading: PublishSubject<Bool> = PublishSubject()
    let bottomTitle: BehaviorSubject<String> = BehaviorSubject(value: "")
    private let collectionId: String
    private let networkAPI: TemplateCenterNetworkAPI
    private let disposeBag = DisposeBag()
    private let loadData: PublishSubject<Void> = PublishSubject()
    private var collection: TemplateCollection?

    let type: TemplateModel.TemplateType
    
    var appLink: String {
        return collection?.appLink ?? ""
    }
    
    var setName: String {
        return collection?.name ?? ""
    }
    
    init(collectionId: String, networkAPI: TemplateCenterNetworkAPI, type: TemplateModel.TemplateType) {
        self.collectionId = collectionId
        self.networkAPI = networkAPI
        self.type = type
        setupBottomTitle()
    }
    
    func setupBottomTitle() {
        var title = BundleI18n.SKResource.CreationMobile_Operation_ApplyTemplateSolution
        if type == .ecology {
            title = BundleI18n.SKResource.LarkCCM_Template_EnquireNow_Button
        }
        bottomTitle.onNext(title)
    }
    
    func requestData() {
        loading.onNext(true)
        networkAPI.fetchTemplateCollection(id: collectionId)
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .next(let collection):
                    self.collection = collection
                    let name = "\(collection.name)（ \(collection.templates.count)\(BundleI18n.SKResource.CreationMobile_Operation_NumberofTemplate) ）"
                    self.colletionName.onNext(name)
                    self.templates.onNext(collection.templates)
                case .error(let err):
                    DocsLogger.error("请求场景化模版详情失败", error: err)
                    self.error.onNext(())
                    self.loading.onNext(false)
                case .completed: self.loading.onNext(false)
                @unknown default: break
                }
            })
            .disposed(by: disposeBag)
    }
    
    func saveTemplateCollectionToFolder(parent parentFolderToken: String, folderVersion: Int, completion: @escaping (_ result: TemplateCollectionSaveResult?) -> Void) {
        networkAPI.saveTemplateCollection(collectionId: collectionId,
                                          parentFolderToken: parentFolderToken,
                                          folderVersion: folderVersion)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { result in
                completion(result)
            }, onError: { error in
                DocsLogger.error("保存场景化模版失败", error: error)
                completion(nil)
            })
            .disposed(by: disposeBag)
    }
}
