//
//  InstanceSnapshot.swift
//  Calendar
//
//  Created by zhuheng on 2020/9/3.
//

import Foundation
import CalendarFoundation
import CryptoSwift
import LKCommonsLogging
import RxSwift
import LarkContainer
import LarkStorage

protocol InstanceSnapshot {
    var data: InstanceSnapshotData? { get }
    var firstScreenData: InstanceSnapshotData? { get }
    func load(firstScreenDayRange: JulianDayRange,
              expectTimeZoneId: String) -> Observable<Void>
    func writeToDiskIfNeeded(instances: [Rust.Instance], timeZoneId: String, dayRange: JulianDayRange)
}

struct InstanceSnapshotData {
    let instance: [Rust.Instance]
    let timeZoneId: String
    let julianDays: Set<Int32>
}
final class InstanceSnapshotImpl: InstanceSnapshot {
    static let logger = Logger.log(InstanceSnapshotImpl.self, category: "Calendar.Instance.Snapshot")
    private(set) var data: InstanceSnapshotData?
    private(set) var firstScreenData: InstanceSnapshotData?
    private lazy var cacheDir: IsoPath = {
        calendarDependency.userLibraryPath() + "home"
    }()
    private lazy var cachePath: IsoPath = {
        cacheDir + "instance"
    }()
    private var aesCipher: CryptoSwift.Cipher?
    private let instanceSplit: String = "_"
    private var diskInstanceHash: Int = 0

    let calendarDependency: CalendarDependency

    init(cipher: CalendarCipher?, calendarDependency: CalendarDependency) {
        do {
            self.aesCipher = try cipher?.generateAES()
        } catch {
            Self.logger.error("generate cipher error")
        }
        self.calendarDependency = calendarDependency
    }
    // 加载磁盘缓存
    func load(firstScreenDayRange: JulianDayRange,
              expectTimeZoneId: String) -> Observable<Void> {
        guard cachePath.exists,
            let aesCipher = self.aesCipher else {
            return .error(NSError(domain: "no disk cache \(cachePath)", code: 0, userInfo: nil))
        }

        let observable = Observable<Void>.create { (observer) -> Disposable in
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    TimerMonitorHelper.shared.launchTimeTracer?.getInstance.start()
                    let cacheData = try Data.read(from: self.cachePath)

                    guard let cacheInstanceObject = NSKeyedUnarchiver.unarchiveObject(with: cacheData) as? InstanceCacheObject,
                          let infoDecryptedData = try cacheInstanceObject.info?.decrypt(cipher: aesCipher) else {
                        observer.onError(NSError(domain: "cache unacrchvie error", code: 0, userInfo: nil))
                        return
                    }

                    let cacheInfo = NSKeyedUnarchiver.unarchiveObject(with: infoDecryptedData) as? HomeCacheInfoObject
                    guard let cachedTimeZoneId = cacheInfo?.timeZoneId, cachedTimeZoneId == expectTimeZoneId else {
                        observer.onError(NSError(domain: "time zone error \(String(describing: cacheInfo?.timeZoneId)) != \(expectTimeZoneId)", code: 0, userInfo: nil))
                        return
                    }
                    let firstScreenDays = Set( firstScreenDayRange.map { Int32($0) })
                    guard let cachedJulianDays = cacheInfo?.julianDays, firstScreenDays.isSubset(of: cachedJulianDays) else {
                        observer.onError(NSError(domain: "disk cache out of date \(String(describing: cacheInfo?.julianDays)) != \(firstScreenDays)", code: 0, userInfo: nil))
                        return
                    }

                    let currentUser = self.calendarDependency.currentUser
                    guard cacheInfo?.userId == currentUser.id, cacheInfo?.tenantId == currentUser.tenantId else {
                        observer.onError(NSError(domain: "account changed", code: 0, userInfo: nil))
                        return
                    }

                    guard let instanceDecryptedString = try cacheInstanceObject.instance?.decryptBase64ToString(cipher: aesCipher) else {
                        observer.onError(NSError(domain: "instance decrypt error", code: 0, userInfo: nil))
                        return
                    }
                    let instanceDecryptedArr: [String] = instanceDecryptedString.components(separatedBy: self.instanceSplit).filter { return !$0.isEmpty
                    }

                    var instances: [Rust.Instance] = [Rust.Instance]()
                    instanceDecryptedArr.forEach { (instanceBase64) in
                        if let data = Data(base64Encoded: instanceBase64), !instanceBase64.isEmpty {
                            do {
                                let instance = try CalendarEventInstance(serializedData: data)
                                instances.append(instance)
                            } catch {
                                assertionFailure("instance with serializedData error")
                                return observer.onError(NSError(domain: "instance with serializedData error", code: 0, userInfo: nil))
                            }
                        }
                    }

                    instances = instances.sortedByServerId()
                    if instanceDecryptedArr.count == instances.count {
                        self.diskInstanceHash = try instances.hash()
                        let cachedInstancesLength = instances.count

                        self.data = InstanceSnapshotData(instance: instances,
                                                         timeZoneId: cachedTimeZoneId,
                                                         julianDays: cachedJulianDays)

                        let firstScreenDaySet = Set(firstScreenDayRange.map { Int32($0) })
                        // 只保留与requestDays有交集的instance，用来加速冷启动。防止多余instanceView、viewData初始化
                        instances = instances.filter { (entity) -> Bool in
                            return !entity.getInstanceDays().isDisjoint(with: firstScreenDaySet)
                        }
                        TimerMonitorHelper.shared.launchTimeTracer?.getInstance.end(
                            extra: [.firstScreenInstancesLength: instances.count,
                                    .cachedInstancesLength: cachedInstancesLength]
                        )
                        self.firstScreenData = InstanceSnapshotData(instance: instances,
                                                                    timeZoneId: cachedTimeZoneId,
                                                                    julianDays: firstScreenDaySet)
                        observer.onNext(())
                        Self.logger.info("load disk cache sucess useCount = \(instances.count)")
                    } else {
                        let errorDesc = "\(instances.count)-\(instanceDecryptedArr.count)"
                        TimerMonitorHelper.shared.launchTimeTracer?.getInstance.error()
                        observer.onError(NSError(domain: "load disk cache error \(errorDesc)", code: 0, userInfo: nil))
                    }
                } catch let error {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
        return observable.do(onError: { (error) in
            Self.logger.error(error.localizedDescription)
        })
    }

    private let debouncer = Debouncer(delay: 1, queue: DispatchQueue.global())
    func writeToDiskIfNeeded(instances: [Rust.Instance], timeZoneId: String, dayRange: JulianDayRange) {
        guard let aesCipher = self.aesCipher else {
                return
        }

        let currentUser = calendarDependency.currentUser
        debouncer.call { [weak self] in
            guard let self = self else { return }
            do {
                let diskCacheDays = Set(dayRange.map { Int32($0) })

                let needWriteInstances = instances.filter { (instance) -> Bool in
                    // 过滤掉instance所在日期与所取日期没有交集的instance && 过滤掉不可见的calendar
                    return !instance.getInstanceDays().isDisjoint(with: diskCacheDays)
                }.sortedByServerId()

                let instanceNewHash = try needWriteInstances.hash()
                guard instanceNewHash != self.diskInstanceHash else {
                    Self.logger.info("cache not change")
                    return
                }
                let instanceBase64String = try needWriteInstances.base64String(with: self.instanceSplit)
                let info = HomeCacheInfoObject(userId: currentUser.id,
                                               tenantId: currentUser.tenantId,
                                               timeZoneId: timeZoneId,
                                               julianDays: diskCacheDays)
                let infoData = NSKeyedArchiver.archivedData(withRootObject: info)

                if let instanceEncryptedString = try instanceBase64String.encryptToBase64(cipher: aesCipher) {
                    let infoEncryptedData = try infoData.encrypt(cipher: aesCipher)
                    let instanceObject = InstanceCacheObject(instance: instanceEncryptedString,
                                                             info: infoEncryptedData)
                    let data = NSKeyedArchiver.archivedData(withRootObject: instanceObject)
                    if !self.cachePath.exists {
                        try? self.cacheDir.createDirectory()
                        try self.cachePath.createFile()
                    }

                    try data.write(to: self.cachePath)
                    Self.logger.info("write to disk finish \(needWriteInstances.count) dayRange =\(dayRange)")
                    self.diskInstanceHash = instanceNewHash
                }
            } catch let error {
                Self.logger.error("catch error \(error.localizedDescription)")
            }
        }
    }
}

extension Array where Element == Rust.Instance {
    fileprivate func hash() throws -> Int {
        var data = Data()
        for entity in self {
            let entityData = try entity.serializedData()
            data.append(entityData)
        }
        return data.hashValue
    }

    fileprivate func sortedByServerId() -> [Rust.Instance] {
        return self.sorted { (left, right) -> Bool in
            let leftID = Int(left.eventServerID) ?? 0
            let rightID = Int(right.eventServerID) ?? 0
            return leftID > rightID
        }
    }

    fileprivate func base64String(with split: String) throws -> String {
        var base64String = ""
        for entity in self {
            let entityData = try entity.serializedData()
            base64String.append(entityData.base64EncodedString())
            base64String.append(split)
        }
        return base64String
    }
}

extension Rust.Instance {
    func getInstanceDays() -> Set<Int32> {
        var result = Set<Int32>()
        guard startDay <= endDay else {
            return result
        }
        for day in self.startDay...self.endDay {
            result.insert(day)
        }
        return result
    }
}
