//
//  DocsFeedViewModel+Request.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/22.
//  


import Foundation
import RxSwift
import RxCocoa
import SKFoundation

// MARK: - 接口请求
    
extension DocsFeedViewModel {

    func fetchServiceData() {
        DocsLogger.feedInfo("begin requestFeedData")
        service.requestFeedData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (data: FeedMessagesWithMetaInfo) in
                self?.cacheDisposeBag = DisposeBag()
                self?.output?.loading.accept(false)
                DocsLogger.feedInfo("showing server data, count:\(data.messages.count)")
                MentionedEntityLocalizationManager.current.updateUsers(data.entity.users)
                MentionedEntityLocalizationManager.current.updateDocMetas(data.entity.metas)
                self?.record(stage: .deserialize)
                self?.updateMessages(.server(data.messages))
            }, onError: { [weak self] error in
                DocsLogger.feedError("show server data failed, error:\(error)")
                guard let self = self else { return }
                if let err = error as? DocsFeedService.FeedError,
                   err == .forbidden {
                    self.error = .forbidden
                    self.output?.showEmptyView.accept(true)
                    self.service.clearAllBadge(docsInfo: self.docsInfo)
                    self.output?.close.accept(())
                }
            }).disposed(by: serverDisposeBag)
    }
    
    func fetchCache() {
        DocsLogger.feedInfo("begin fetchCache")
        feedCache.getCache(type: FeedMessageModel.self)
            .subscribe { [weak self] (models) in
                guard let self = self else { return }
                self.output?.loading.accept(false)
                DocsLogger.feedInfo("显示缓存数据 count:\(models.count)")
                self.record(stage: .cacheLoad)
                self.updateMessages(.cache(models))
            } onError: { (error) in
                DocsLogger.feedInfo("\(error)")
            }.disposed(by: cacheDisposeBag)
    }
}
