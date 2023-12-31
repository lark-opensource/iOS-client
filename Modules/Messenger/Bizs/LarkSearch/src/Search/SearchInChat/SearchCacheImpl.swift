//
//  SearchCache.swift
//  LarkSearch
//
//  Created by zc09v on 2018/9/3.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkSearchFilter
import LarkMessengerInterface
import LarkSDKInterface
import LarkSearchCore

/// 一个简单的内存缓存
final class SearchCacheImpl: SearchCache {
    private var cache: [SearchCacheData] = []
    private let maxCacheCount: Int = 5
    private let dataAliveTime: TimeInterval = 5 * 60
    private let workQueue = DispatchQueue(label: "SearchCacheQueue", qos: .userInitiated)
    private var cleanTimer: Timer?

    /// 是否有搜索更多数据的提示展示
    var showRequestColdDataTip: Bool?
    private lazy var workQueueScheduler: SerialDispatchQueueScheduler = {
        return SerialDispatchQueueScheduler(queue: workQueue, internalSerialQueueName: workQueue.label)
    }()

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    deinit {
        cleanTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    func set(key: String, quary: String, filers: [SearchFilter], results: [SearchResultType], visitIndex: IndexPath, showRequestColdTip: Bool? = nil) {
        if cleanTimer == nil {
            self.startCleanTimer()
        }
        workQueue.async { [weak self] in
            guard let `self` = self else { return }
            var newData = SearchCacheData(key: key, quary: quary, filters: filers, results: results, visitIndex: visitIndex)
            newData.showRequestColdTip = showRequestColdTip
            let newResultsIsEmpty = results.isEmpty
            if let index = self.cache.firstIndex(where: { (data) -> Bool in
                return data.key == key
            }) {
                self.cache.remove(at: index)
                if !newResultsIsEmpty {
                    //把新数据挪到队列尾部
                    self.cache.append(newData)
                }
            } else {
                if !newResultsIsEmpty {
                    self.cache.append(newData)
                    if self.cache.count > self.maxCacheCount {
                        self.cache.removeFirst()
                    }
                }
            }
        }
    }

    func getCacheData(key: String) -> Observable<SearchCacheData?> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let `self` = self,
                let dataIndex = self.cache.firstIndex(where: { (data) -> Bool in
                    return data.key == key
                }) else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return Disposables.create()
            }
            let data = self.cache[dataIndex]
            if self.dataNeedClean(data) {
                self.cache.remove(at: dataIndex)
                observer.onNext(nil)
            } else {
                observer.onNext(data)
            }
            observer.onCompleted()
            return Disposables.create()
        }.subscribeOn(workQueueScheduler)
    }

    @objc
    private func appDidReceiveMemoryWarningNotification() {
        workQueue.async { [weak self] in
            self?.cache.removeAll()
        }
    }

    private func dataNeedClean(_ data: SearchCacheData) -> Bool {
        return Date().timeIntervalSince(data.timpStamp) > self.dataAliveTime
    }

    private func startCleanTimer() {
        cleanTimer = Timer(timeInterval: self.dataAliveTime, repeats: true, block: { [weak self] (_) in
            self?.handleCleanTimer()
        })
        //不要求计时特别精准，仅在defaultRunLoopMode下工作即可
        cleanTimer.flatMap { RunLoop.main.add($0, forMode: .default) }
    }

    private func handleCleanTimer() {
        self.workQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            let dataCountInCache = self.cache.count
            var cleanDataIndex: Int?
            for i in 0..<dataCountInCache {
                let data = self.cache[i]
                if self.dataNeedClean(data) {
                    cleanDataIndex = i
                } else {
                    break
                }
            }
            if let cleanDataIndex = cleanDataIndex {
                self.cache.removeSubrange(0...cleanDataIndex)
            }
        }
    }
}
