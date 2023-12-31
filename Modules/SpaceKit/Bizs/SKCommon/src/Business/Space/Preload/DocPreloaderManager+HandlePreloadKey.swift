//
//  DocPreloaderManager+HandlePreloadKey.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/1/15.
//

import Foundation
extension DocPreloaderManager {
    /*
    //生成clientvar Preloader
    func createClientVarPreloader(_ preloadKeys: [PreloadKey]) -> SequeuePreloader<PreloadClientVarTask> {
        let curPreloadKeys = preloadKeys
        let clientVarPreloaderQueue = SequeuePreloader<PreloadClientVarTask>(logPrefix: "clientVarPre")
        clientVarPreloaderQueue.preloaderType = .single
        let preloadClientVarTasks = curPreloadKeys.map { (preloadKey) -> PreloadClientVarTask in
            let canUseCarrierNetwork: Bool = {
                if preloadKey.fromSource == .recentPreload {
                    return !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi
                }
                return true
            }()
            var task = preloadKey.makeClientVarTask(canUseCarrierNetwork: canUseCarrierNetwork, clientVarPreloaderType: self.clientVarPreloaderType, maxRetryCount: 3)
            task.rnPreloader = self.docRNPreloader
            return task
        }
        clientVarPreloaderQueue.addTasks(preloadClientVarTasks)
        return clientVarPreloaderQueue
    }

    //生成picture Preloader
    func createPicturePreloader(_ preloadKeys: [PreloadKey]) -> SequeuePreloader<PreloadPictureTask> {
        let curPrelaodKeys = preloadKeys
        let picturePreloaderQueue = SequeuePreloader<PreloadPictureTask>(logPrefix: "picturePreload")
        picturePreloaderQueue.preloaderType = .single
        let preloadPictureTasks = curPrelaodKeys.map({ (preloadKey) -> PreloadPictureTask in
            let curPreloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
            let task = curPreloadKey.makePictureTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.preloadPictureWifiOnly)
            return task
        })
        picturePreloaderQueue.addTasks(preloadPictureTasks)
        return picturePreloaderQueue
    }

    //生成vote Preloader
    func createVotePreloader(_ preloadKeys: [PreloadKey]) -> SequeuePreloader<RNPreloadTask> {
        let curPrelaodKeys = preloadKeys
        let votePreloaderQueue = SequeuePreloader<RNPreloadTask>(logPrefix: "votePreload")
        votePreloaderQueue.preloaderType = .single
        let preloadVoteTasks = curPrelaodKeys.map({ (preloadKey) -> RNPreloadTask in
            let curPreloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
            let task = curPreloadKey.makeVoteTask(delegate: self.docRNPreloader)
            return task
        })
        votePreloaderQueue.addTasks(preloadVoteTasks)
        return votePreloaderQueue
    }
    */
    
    /*
    //生成comment Preloader
    func createCommentPreloader(_ preloadKeys: [PreloadKey]) -> SequeuePreloader<RNPreloadTask> {
        let curPrelaodKeys = preloadKeys
        let commentPreloaderQueue = SequeuePreloader<RNPreloadTask>(logPrefix: "commentPreload")
        commentPreloaderQueue.preloaderType = .single
        let preloadCommentTasks = curPrelaodKeys.map({ (preloadKey) -> RNPreloadTask in
            let curPreloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
            let task = curPreloadKey.makeCommentTask(delegate: self.docRNPreloader)
            return task
        })
        commentPreloaderQueue.addTasks(preloadCommentTasks)
        return commentPreloaderQueue
    }

    //生成html Preloader
    func createHtmlPreloader(_ preloadKeys: [PreloadKey]) -> SequeuePreloader<PreloadHtmlTask>? {
        let curPrelaodKeys = preloadKeys
        let htmlPreloaderQueue = SequeuePreloader<PreloadHtmlTask>(logPrefix: "htmlPreload")
        htmlPreloaderQueue.preloaderType = .single
        var preloadHtmlTasks = [PreloadHtmlTask]()
        for preloadKey in curPrelaodKeys {
            let curPreloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
            guard curPreloadKey.type == .doc else {
                continue
            }
            let task = curPreloadKey.makeHtmlTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi)
            preloadHtmlTasks.append(task)
        }
        guard !preloadHtmlTasks.isEmpty else {
            return nil
        }
        htmlPreloaderQueue.addTasks(preloadHtmlTasks)
        return htmlPreloaderQueue
    }

    // 生成html Native Preloader
    func createHtmlNativePreloader(_ preloadKeys: [PreloadKey]) -> SequeuePreloader<NativePerloadHtmlTask>? {
        let curPrelaodKeys = preloadKeys
        let htmlPreloaderQueue = SequeuePreloader<NativePerloadHtmlTask>(logPrefix: "htmlNativePreload")
        htmlPreloaderQueue.preloaderType = .single
        var preloadHtmlTasks = [NativePerloadHtmlTask]()
        for preloadKey in curPrelaodKeys {
            let curPreloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
            guard curPreloadKey.type == .docX else {
                continue
            }
            let task = curPreloadKey.makeNativeHtmlTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi)
            preloadHtmlTasks.append(task)
        }
        guard !preloadHtmlTasks.isEmpty else {
            return nil
        }
        htmlPreloaderQueue.addTasks(preloadHtmlTasks)
        return htmlPreloaderQueue
    }
     */
}
