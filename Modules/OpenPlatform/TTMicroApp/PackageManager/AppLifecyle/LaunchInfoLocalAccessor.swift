//
//  LaunchInfoLocalAccessor.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/8/17.
//

import Foundation
import FMDB
import LKCommonsLogging
import LarkOPInterface
import LarkFoundation
import OPSDK

@objcMembers
public final class LaunchInfoAccessorFactory: NSObject {
    static var instanceMap = [OPAppType : LaunchInfoLocalAccessor]()
    static let lock = NSLock()

    public static func launchInfoAccessor(type: OPAppType) -> LaunchInfoLocalAccessor? {
        var accessor: LaunchInfoLocalAccessor? = nil
        lock.lock()
        if let _accessor = instanceMap[type] {
            accessor = _accessor
        } else {
            let _accessor = LaunchInfoLocalAccessor(type: type)
            instanceMap[type] = _accessor
            accessor = _accessor
        }
        lock.unlock()
        return accessor
    }

    public static func clearLaunchInfoAccessor(type: OPAppType) {
        lock.lock()
        if let accessor = instanceMap[type] {
            accessor.closeDBQueue()
            instanceMap.removeValue(forKey: type)
        }
        lock.unlock()
    }

    public static func clearAllLuancInfoAccessor() {
        lock.lock()
        instanceMap.forEach { (_, accessor) in
            accessor.closeDBQueue()
        }
        instanceMap.removeAll()
        lock.unlock()
    }
}


private let logger = Logger.oplog(LaunchInfoLocalAccessor.self, category: "LaunchInfoLocalAccessor")

@objcMembers
public final class LaunchInfoLocalAccessor: NSObject {
    /// 内部私有的数据库实例，请勿直接使用
    private var internalDBQueue: FMDatabaseQueue?

    /// 数据库
    private var dbQueue: FMDatabaseQueue? {
        if internalDBQueue == nil {
            internalDBQueue = (BDPModuleManager(of: appType)
                                .resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?
                .sharedLocalFileManager()
                .dbQueue
            internalDBQueue?.inTransaction({ (db, rollback) in
                let createLaunchInfoTableResult = db.executeUpdate(String.CreateLaunchInfoTable, withArgumentsIn: [])
                if !createLaunchInfoTableResult {
                    let errMsg = "[LaunchInfo] createLaunchInfoTable failed, will rollback"
                    logger.error(errMsg)
                    rollback.pointee = true
                    assertionFailure(errMsg)
                }
            })
        }
        return internalDBQueue
    }

    /// 应用类型，外部传入
    private let appType: OPAppType

    /// meta本地存取器初始化方法
    /// - Parameters:
    ///   - type: 应用类型
    public init(type: OPAppType) {
        appType = type
        if type == .unknown {
            let errMsg = "[LaunchInfo] accessor init error with unknown type"
            logger.error(errMsg)
            assertionFailure(errMsg)
        }
    }

    /// 清除数据库实例
    public func closeDBQueue() {
        internalDBQueue?.close()
        internalDBQueue = nil
    }


    /// 增加一条启动数据
    /// - Parameters:
    ///   - appID: 应用ID
    ///   - tenantID: 租户ID
    ///   - applicationVersion: 应用版本(不是包版本, 不同形态的应用版本在meta中的字段是不同的, 需要注意)
    ///   - ts: 时间戳, 单位(ms);不传默认将存储时间作为时间戳
    /// - Returns: 结果
    public func addLaunchInfo(appID: String,
                              scene: Int,
                              applicationVersion: String = "unknown",
                              timestamp: TimeInterval = Date().timeIntervalSince1970 * 1000) -> Bool {
        let commonInfo = "[LaunchInfo] appID: \(appID) "
        guard !appID.isEmpty else {
            logger.warn(commonInfo + "is invalid")
            return false
        }

        var tenantID = "unknown"

        if let userPlugin = BDPTimorClient.shared().userPlugin.sharedPlugin() as? BDPUserPluginDelegate,
           let _tenantID = userPlugin.bdp_encyptTenantId() {
            tenantID = _tenantID
        }

        let sceneNumber = NSNumber(value: scene)
        let ts = NSNumber(value: Int(timestamp))

        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let year = NSNumber(value: date.year)
        let month = NSNumber(value: date.month)
        let day = NSNumber(value: date.day)
        let hour = NSNumber(value: date.hour)

        var result = true

        dbQueue?.inDatabase({ db in
            let saveResult = db.executeUpdate(String.AddLaunchInfoTable, withVAList: getVaList([appID, tenantID, applicationVersion, sceneNumber, ts, year, month, day, hour]))
            result = saveResult
        })

        if !result {
            logger.error(commonInfo + "save failed")
        }

        return result
    }

    /// 筛选出前X天中, 启动频次前X的appID
    /// - Parameters:
    ///   - most: 前X名
    ///   - beforeDays: 前多少天
    /// - Returns: 小程序ID数组
    public func queryTop(most: Int, beforeDays: Int) -> [String] {
        var result = [String]()

        let daysInterval = Double(beforeDays) * TimeInterval.OneDaySecond

        let beforeDayTs = NSNumber(value: (Date().timeIntervalSince1970 - daysInterval) * 1000)

        let countNumber = NSNumber(value: most)

        dbQueue?.inDatabase({ db in
            let rs = db.executeQuery(String.QueryDataOrderByCount, withVAList: getVaList([beforeDayTs, countNumber]))
            while let rs = rs, rs.next() {
                if let appID = rs.string(forColumnIndex: 0) {
                    result.append(appID)
                }
            }
        })

        return result
    }

    /// 筛选出前x天中, appID 在 哪些scene下启动
    public func queryUsedOpenInDays(appid:String, days: Int, scenes: [Int]) -> Bool {
        let daysInterval = Double(days) * TimeInterval.OneDaySecond
        let beforeDayTs = NSNumber(value: (Date().timeIntervalSince1970 - daysInterval) * 1000)
        var scenesInDB = [Int]()
        dbQueue?.inDatabase({ db in
            ///这里sql SELECT count(*) as num FROM OPLaunchInfoTable WHERE (appID = "cli_9cb844403dbb9108" AND scene in (1009,1002) ) 数组不好支持，因此改成 select scene xxx
            let rs = db.executeQuery(String.QueryUsedOpenInDays, withVAList: getVaList([appid,beforeDayTs]))
            while let rs = rs, rs.next() {
                let scene = rs.long(forColumn: "scene")
                scenesInDB.append(scene)
            }
            rs?.close()
        })
        
        for sceneInDB in scenesInDB{
            if scenes.contains(sceneInDB){
                return true
            }
        }
        
        return false
    }

    /// 删除老数据(180天前的数据)
    @discardableResult
    public func deleteOldData() -> Bool {
        var defaultDays: TimeInterval = 180

        if let daysString = BDPSDKConfig.shared().appLaunchInfoDeleteOldDataDays,
           let debugDaysDoubleValue = Double(daysString) {
            defaultDays = debugDaysDoubleValue
        }

        logger.info("[LaunchInfo] start delete before \(defaultDays)")

        // 180天的时间间隔(秒)
        let halfYearInterval = TimeInterval.OneDaySecond * defaultDays
        // 180天前的时间戳(毫秒)
        let sixMonthTimeAgoStamp = NSNumber(value: (Date().timeIntervalSince1970 - halfYearInterval) * 1000)

        var result = true
        dbQueue?.inDatabase({ db in
            result = db.executeUpdate(String.DeleteLaunchTableOldData, withVAList: getVaList([sixMonthTimeAgoStamp]))
        })

        if !result {
            logger.error("[LaunchInfo] delete old data failed")
        }

        return result
    }
}

fileprivate extension String {

    static let fieldInit = "OPLaunchInfoTable(ID INTEGER PRIMARY KEY AUTOINCREMENT, appID TEXT NOT NULL, tenantID TEXT NOT NULL, applicationVersion TEXT NOT NULL, scene INTEGER, ts INTEGER CHECK(ts > 0), year INTEGER CHECK(year > 0), month INTEGER CHECK(month > 0), day INTEGER CHECK(day > 0), hour INTEGER CHECK(hour > 0))"

    static let allFields = "appID, tenantID, applicationVersion, scene, ts, year, month, day, hour"

    /// 创建launchInfo表
    static let CreateLaunchInfoTable = "CREATE TABLE IF NOT EXISTS \(fieldInit);"

    /// 插入一条数据
    static let AddLaunchInfoTable = "INSERT INTO OPLaunchInfoTable(\(allFields)) values (?, ?, ?, ?, ?, ?, ?, ?, ?)"

    /// 更新launchInfo
    static let UpdateLaunchInfoTable = "REPLACE INTO OPLaunchInfoTable(\(allFields)) values (?, ?, ?, ?, ?, ?, ?, ?, ?)"

    /// 查询指定appID的启动数据
    static let QueryLaunchInfoWithAppID = "SELECT \(allFields) FROM OPLaunchInfoTable WHERE appID = ?;"

    /// 提取所有launchInfo信息
    static let QueryAllLaunchInfoTable = "SELECT \(allFields) FROM OPLaunchInfoTable;"

    /// 删除早于某个时间的数据(根据时间戳来判断)
    static let DeleteLaunchTableOldData = "DELETE FROM OPLaunchInfoTable WHERE ts < ?;"

    /// 删除所有LaunchInfo数据
    static let ClearLaunchTable = "DELETE FROM OPLaunchInfoTable;"

    /// 筛选某个时间到当前时间的AppID, 并按照次数降序取前X个
    static let QueryDataOrderByCount = "SELECT appID, count(*) AS cnt FROM OPLaunchInfoTable WHERE(ts > ?) GROUP BY appID ORDER BY cnt DESC LIMIT ?"
    
    /// 筛选出前x天中, appID 在 哪些scene下启动
    static let QueryUsedOpenInDays = "SELECT scene as scene FROM OPLaunchInfoTable WHERE (appID = ? AND ts >? );"

}

fileprivate extension TimeInterval {
    // 一天的时间(单位:秒)
    static let OneDaySecond: TimeInterval = 86400
}
