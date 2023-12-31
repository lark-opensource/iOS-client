//
//  ReverseGeocodeManager.swift
//  OPPlugin
//
//  Created by zhangxudong on 8/4/22.
//
import CoreLocation
import LarkLocalizations
import LarkLocationPicker

/// 对POISearchService 进行简单封装
/// 封装的原因是 POISearchService 发出多次请求是无法区分 回调的唯一性
final class ReverseGeocodeManager {
    private var tasks = Set<ReverseGeocodeTask>()
    private let semaphore = DispatchSemaphore(value: 1)

    private func remove(task: ReverseGeocodeTask) {
        semaphore.wait()
        tasks.remove(task)
        semaphore.signal()
    }

    private func insert(task: ReverseGeocodeTask) {
        semaphore.wait()
        tasks.insert(task)
        semaphore.signal()
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D,
                        failedCallback: @escaping ((Error) -> Void),
                        successCallback: @escaping ((LarkLocationPicker.UILocationData) -> Void))
    {
        let task = ReverseGeocodeTask(coordinate: coordinate, failedCallback: { [weak self] error, task in
            self?.remove(task: task)
            failedCallback(error)
        }, successCallback: { [weak self] data, task in
            self?.remove(task: task)
            successCallback(data)
        })
        insert(task: task)
        task.startRequest()
    }
}

/// 每个Task内部封装一个 service 每个task 只能发起一次请求
private final class ReverseGeocodeTask: LarkLocationPicker.SearchAPIDelegate {
    private let service = POISearchService(language: LanguageManager.currentLanguage)
    private let coordinate: CLLocationCoordinate2D
    private let failedCallback: (Error, ReverseGeocodeTask) -> Void
    private let successCallback: (LarkLocationPicker.UILocationData, ReverseGeocodeTask) -> Void
    let taskID = UUID()
    fileprivate init(coordinate: CLLocationCoordinate2D,
                     failedCallback: @escaping ((Error, ReverseGeocodeTask) -> Void),
                     successCallback: @escaping ((LarkLocationPicker.UILocationData, ReverseGeocodeTask) -> Void))
    {
        self.coordinate = coordinate
        self.failedCallback = failedCallback
        self.successCallback = successCallback
        service.delegate = self
    }

    func startRequest() {
        service.searchReGeocode(center: coordinate)
    }

    public func reGeocodeFailed(data: LarkLocationPicker.UILocationData, err: Error) {
        failedCallback(err, self)
    }

    public func reGeocodeDone(data: LarkLocationPicker.UILocationData) {
        successCallback(data, self)
    }

    public func searchFailed(err: Error) {}

    public func searchInputTipDone(keyword: String, data: [(LarkLocationPicker.UILocationData, Bool)]) {}

    public func searchDone(keyword: String?, data: [LarkLocationPicker.UILocationData], isFirstPage: Bool) {}

    public func regionOutOfService(current: LarkLocationPicker.UILocationData) {}
}

extension ReverseGeocodeTask: Hashable {
    static func == (lhs: ReverseGeocodeTask, rhs: ReverseGeocodeTask) -> Bool {
        return lhs.taskID == rhs.taskID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(taskID)
    }
}
