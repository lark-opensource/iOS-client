//
//  OpenPluginSearchPOIImpl.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/12/14.
//

import Foundation
import OPPlugin
import CoreLocation
import LarkLocalizations
import LarkLocationPicker
import LKCommonsLogging

private let logger = Logger.oplog(OpenPluginSearchPoiProvider.self, category: "OpenPluginSearchPoi")
final class OpenPluginSearchPoiProvider: OpenPluginSearchPoiProxy {
    private var tasks = Set<SearchPOITask>()
    private let semaphore = DispatchSemaphore(value: 1)

    private func remove(task: SearchPOITask) {
        semaphore.wait()
        tasks.remove(task)
        semaphore.signal()
    }

    private func insert(task: SearchPOITask) {
        semaphore.wait()
        tasks.insert(task)
        semaphore.signal()
    }

    func searchPOI(coordinate: CLLocationCoordinate2D,
                   radius: Int,
                   maxCount: Int,
                   keyword: String?,
                   failedCallback: @escaping ((Error) -> Void),
                   successCallback: @escaping (([LarkLocationPicker.LocationData]) -> Void))
    {
        let searchTask = SearchPOITask(coordinate: coordinate,
                      radius: radius,
                      maxCount: maxCount,
                      keyword: keyword) { [weak self] error, task in
            logger.info("OpenPluginSearchPoiProvider:\(task.taskID) failedCallback")
            self?.remove(task: task)
            failedCallback(error)
        } successCallback: { [weak self] data, task in
            logger.info("OpenPluginSearchPoiProvider:\(task.taskID) successCallback")
            self?.remove(task: task)
            successCallback(data)
        }
        insert(task: searchTask)
        logger.info("OpenPluginSearchPoiProvider:\(searchTask.taskID) searchPOI")
        searchTask.startRequest()
    }
}

/// 每个Task内部封装一个 service 每个task 只能发起一次请求
private final class SearchPOITask: LarkLocationPicker.SearchPOIDelegate {
    
    
    private let service = POISearchService(language: LanguageManager.currentLanguage)
    private let coordinate: CLLocationCoordinate2D
    private let radius: Int
    private let maxCount: Int
    private let keyword: String?

    private let failedCallback: (Error, SearchPOITask) -> Void
    private let successCallback: ([LarkLocationPicker.LocationData], SearchPOITask) -> Void
    let taskID = UUID()
    
    fileprivate init(coordinate: CLLocationCoordinate2D,
                     radius: Int,
                     maxCount: Int,
                     keyword: String?,
                     failedCallback: @escaping ((Error, SearchPOITask) -> Void),
                     successCallback: @escaping (([LarkLocationPicker.LocationData], SearchPOITask) -> Void))
    {
        self.coordinate = coordinate
        self.radius = radius
        self.maxCount = maxCount
        self.keyword = keyword
        self.failedCallback = failedCallback
        self.successCallback = successCallback
        service.poiDelegate = self
    }

    func startRequest() {
        logger.info("SearchPOITask:\(taskID) startRequest")
        service.searchPOI(center: coordinate, radiusInMeters: radius, pageSize: maxCount, keywords: keyword)
    }
    
    func searchPOIDone(data: [LarkLocationPicker.LocationData]) {
        logger.info("SearchPOITask:\(taskID) searchPOIDone, data.count:\(data.count)")
        successCallback(data, self)
    }
    
    func searchFailed(err: Error) {
        logger.error("SearchPOITask:\(taskID) searchFailed, error:\(err)")
        failedCallback(err, self)
    }
}

extension SearchPOITask: Hashable {
    static func == (lhs: SearchPOITask, rhs: SearchPOITask) -> Bool {
        return lhs.taskID == rhs.taskID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(taskID)
    }
}
