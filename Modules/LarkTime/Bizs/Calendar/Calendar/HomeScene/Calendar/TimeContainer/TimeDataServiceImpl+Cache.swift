//
//  TimeDataServiceImpl+Cache.swift
//  Calendar
//
//  Created by JackZhao on 2023/12/14.
//

import RxRelay
import RxSwift
import Foundation
import CryptoSwift
import LKCommonsLogging
import CalendarFoundation

extension TimeDataServiceImpl {
    // 加载磁盘缓存
    func prepareDiskData(firstScreenDayRange: JulianDayRange) {
        guard taskInCalendarFG else { return }
        let observable = Observable<TimeBlockModelMap>.create { (observer) -> Disposable in
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    guard let cachePath = self.cachePath, cachePath.exists,
                        let aesCipher = self.aesCipher else {
                        observer.onError(NSError(domain: "no disk cache \(String(describing: self.cachePath))", code: 0, userInfo: nil))
                        return
                    }
                    let cacheData = try Data.read(from: cachePath)
                    guard let cacheTimeBlockObject = NSKeyedUnarchiver.unarchiveObject(with: cacheData) as? TimeBlockCacheObject,
                          let infoDecryptedData = try cacheTimeBlockObject.info?.decrypt(cipher: aesCipher) else {
                        observer.onError(NSError(domain: "cache unacrchvie error", code: 0, userInfo: nil))
                        return
                    }

                    let cacheInfo = NSKeyedUnarchiver.unarchiveObject(with: infoDecryptedData) as? HomeCacheInfoObject
                    let firstScreenDays = Set(firstScreenDayRange.map { Int32($0) })
                    guard let cachedJulianDays = cacheInfo?.julianDays, firstScreenDays.isSubset(of: cachedJulianDays) else {
                        observer.onError(NSError(domain: "disk cache out of date \(String(describing: cacheInfo?.julianDays)) != \(firstScreenDays)", code: 0, userInfo: nil))
                        return
                    }

                    guard let currentUser = self.calendarDependency?.currentUser else { return }
                    guard cacheInfo?.userId == currentUser.id, cacheInfo?.tenantId == currentUser.tenantId else {
                        observer.onError(NSError(domain: "account changed", code: 0, userInfo: nil))
                        return
                    }

                    guard let timeBlockDecryptedString = try cacheTimeBlockObject.timeBlock?.decryptBase64ToString(cipher: aesCipher) else {
                        observer.onError(NSError(domain: "timeBlocks decrypt error", code: 0, userInfo: nil))
                        return
                    }
                    let timeBlockDecryptedArr: [String] = timeBlockDecryptedString.components(separatedBy: Self.timeBlockSplit).filter { return !$0.isEmpty
                    }

                    var timeBlocks = [TimeBlock]()
                    timeBlockDecryptedArr.forEach { (timeBlockBase64) in
                        if let data = Data(base64Encoded: timeBlockBase64), !timeBlockBase64.isEmpty {
                            do {
                                let timeBlock = try TimeBlock(serializedData: data)
                                timeBlocks.append(timeBlock)
                            } catch {
                                assertionFailure("timeBlocks with serializedData error")
                                return observer.onError(NSError(domain: "timeBlocks with serializedData error", code: 0, userInfo: nil))
                            }
                        }
                    }
                    
                    guard let timeContainerDecryptedString = try cacheTimeBlockObject.timeCotainer?.decryptBase64ToString(cipher: aesCipher) else {
                        observer.onError(NSError(domain: "timeContainer decrypt error", code: 0, userInfo: nil))
                        return
                    }
                    let timeContainerDecryptedArr: [String] = timeContainerDecryptedString.components(separatedBy: Self.timeBlockSplit).filter { return !$0.isEmpty
                    }
                    
                    var timeCotainerMap = [String: TimeContainer]()
                    timeContainerDecryptedArr.forEach { (base64) in
                        if !base64.isEmpty, let data = Data(base64Encoded: base64) {
                            do {
                                let timeContainer = try TimeContainer(serializedData: data)
                                timeCotainerMap[timeContainer.serverID] = timeContainer
                            } catch {
                                assertionFailure("timeContainers with serializedData error")
                                return observer.onError(NSError(domain: "timeContainers with serializedData error", code: 0, userInfo: nil))
                            }
                        }
                    }
                    Self.logger.info("load disk timeblock count = \(timeBlocks.count)")
                    if timeBlockDecryptedArr.count == timeBlocks.count {
                        self.diskTimeBlockHash = try timeBlocks.hash()

                        let firstScreenDaySet = Set(firstScreenDayRange.map { Int32($0) })
                        // 只保留与requestDays有交集的timeBlock，用来加速冷启动。防止多余timeBlock、viewData初始化
                        timeBlocks = timeBlocks.filter { (entity) -> Bool in
                            return !entity.getTimeBlockDays().isDisjoint(with: firstScreenDaySet)
                        }
                        if Set(firstScreenDayRange.map { Int32($0) }).isSubset(of: firstScreenDaySet) {
                            let map = Self.groupedByDay(from: timeBlocks.map { TimeBlockModel(pbModel: $0, container: timeCotainerMap[$0.containerIDOnDisplay]) }, for: firstScreenDayRange)
                            Self.logger.info("load disk cache sucess useCount = \(map.count)")
                            observer.onNext(map)
                        } else {
                            Self.logger.info("load disk cache empty")
                            observer.onNext([:])
                        }
                    } else {
                        let errorDesc = "\(timeBlocks.count)-\(timeBlockDecryptedArr.count)"
                        observer.onError(NSError(domain: "load disk cache error \(errorDesc)", code: 0, userInfo: nil))
                    }
                } catch let error {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
        observable.subscribe(onNext: { [weak self] map in
            self?.timeBlockDiskDataSubject.onNext(map)
        }, onError: { [weak self] error in
            self?.timeBlockDiskDataSubject.onError(error)
        }).disposed(by: self.bag)
    }
    
    func writeToDiskIfNeeded(timeBlocks: [TimeBlock],
                             timeContainer: [TimeContainer],
                             dayRange: JulianDayRange) {
        guard let cachePath, let aesCipher = self.aesCipher, let currentUser = calendarDependency?.currentUser else {
            return
        }

        debouncer.call { [weak self] in
            guard let self = self else { return }
            do {
                let diskCacheDays = Set(dayRange.map { Int32($0) })

                let needWriteTimeBlocks = timeBlocks.filter { (timeBlock) -> Bool in
                    // 过滤掉timeBlock所在日期与所取日期没有交集的timeBlock
                    return !timeBlock.getTimeBlockDays().isDisjoint(with: diskCacheDays)
                }.sortedByServerId()
                let newHash = try needWriteTimeBlocks.hash()
                guard newHash != self.diskTimeBlockHash else {
                    Self.logger.info("cache not change")
                    return
                }
                let timeBlockBase64String = try needWriteTimeBlocks.base64String(with: Self.timeBlockSplit)
                let timeContainerBase64String = try timeContainer.base64String(with: Self.timeBlockSplit)
                let info = HomeCacheInfoObject(userId: currentUser.id,
                                               tenantId: currentUser.tenantId,
                                               timeZoneId: "",
                                               julianDays: diskCacheDays)
                let infoData = try NSKeyedArchiver.archivedData(withRootObject: info, requiringSecureCoding: false)

                if let timeBlockEncryptedString = try timeBlockBase64String.encryptToBase64(cipher: aesCipher), let timeContainerEncryptedString = try timeContainerBase64String.encryptToBase64(cipher: aesCipher) {
                    let infoEncryptedData = try infoData.encrypt(cipher: aesCipher)
                    let timeBlockObject = TimeBlockCacheObject(timeBlock: timeBlockEncryptedString,
                                                               info: infoEncryptedData,
                                                               timeCotainer: timeContainerEncryptedString)
                    let data = try NSKeyedArchiver.archivedData(withRootObject: timeBlockObject, requiringSecureCoding: false)
                    if !cachePath.exists {
                        try? self.cacheDir?.createDirectory()
                        try cachePath.createFile()
                    }

                    try data.write(to: cachePath)
                    Self.logger.info("write to disk finish \(needWriteTimeBlocks.count) dayRange = \(dayRange)")
                    self.diskTimeBlockHash = newHash
                }
            } catch let error {
                Self.logger.error("catch error \(error.localizedDescription)")
            }
        }
    }
}

extension Array where Element == TimeContainer {
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

extension Array where Element == TimeBlock {
    fileprivate func hash() throws -> Int {
        var data = Data()
        for entity in self {
            let entityData = try entity.serializedData()
            data.append(entityData)
        }
        return data.hashValue
    }

    fileprivate func sortedByServerId() -> [TimeBlock] {
        return self.sorted(by: { $0.blockID < $1.blockID })
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

final class TimeBlockCacheObject: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(self.timeBlock, forKey: "timeBlock")
        coder.encode(self.info, forKey: "info")
        coder.encode(self.timeCotainer, forKey: "timeCotainer")
    }

    required init?(coder: NSCoder) {
        self.timeBlock = coder.decodeObject(forKey: "timeBlock") as? String
        self.info = coder.decodeObject(forKey: "info") as? Data
        self.timeCotainer = coder.decodeObject(forKey: "timeCotainer") as? String
    }

    private(set) var timeBlock: String?
    private(set) var timeCotainer: String?
    private(set) var info: Data?

    init(timeBlock: String, info: Data, timeCotainer: String) {
        self.timeBlock = timeBlock
        self.timeCotainer = timeCotainer
        self.info = info
    }
}

extension TimeBlock {
    func getTimeBlockDays() -> Set<Int32> {
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
