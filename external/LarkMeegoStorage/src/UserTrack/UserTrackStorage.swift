//
//  UserTrackStorage.swift
//  LarkMeegoStorage
//
//  Created by shizhengyu on 2023/3/15.
//

import Foundation
import meego_rust_ios
import RxSwift
import LarkMeegoLogger

protocol DbValueConvertible: CaseIterable {
    var dbValue: Int64 { get }
}

/// 在哪个 lark 场景触达的
public enum LarkScene: String, DbValueConvertible {
    case message
    case messageCard = "message_card"

    var dbValue: Int64 {
        return Int64(Self.allCases.firstIndex(of: self) ?? -1)
    }
}

/// 进入到了哪个 meego 场景
public enum MeegoScene: String {
    case detail
    case singleView
}

/// 用户触发的行为类型
public enum UserActivity: String, DbValueConvertible {
    case exposeEntrance = "expose_entrance"
    case exposeScene = "expose_scene"

    var dbValue: Int64 {
        return Int64(Self.allCases.firstIndex(of: self) ?? -1)
    }
}

public class UserTrackStorage: UserStorage {
    private static let domain = "user_track_table"

    /// 添加一条用户行为记录
    public func add(
        with larkScene: LarkScene,
        meegoScene: MeegoScene,
        userActivity: UserActivity,
        timestampMills: Int64
    ) -> Observable<Void> {
        guard let database = userDb.wrappedValue else {
            MeegoLogger.warnWithAssert("add user track failed due to database is nil", domain: UserTrackStorage.domain)
            return .error(StructureStorageOptError.databaseNotExist)
        }

        return Observable.create { ob in
            do {
                try userTrackAdd(
                    db: database,
                    larkScene: larkScene.dbValue,
                    meegoScene: meegoScene.rawValue,
                    action: userActivity.dbValue,
                    timestampMillis: timestampMills
                )
                MeegoLogger.debug("add user track success, db handle = \(database.handle)", domain: UserTrackStorage.domain)
                ob.end(())
            } catch let error {
                let debugMsg = "add user track failed due to rust call error = \(error.localizedDescription)"
                MeegoLogger.warnWithAssert(debugMsg, domain: UserTrackStorage.domain)
                ob.end(with: StructureStorageOptError.rustInnerError(debugMsg: debugMsg))
            }
            return Disposables.create()
        }.subscribeOn(structureStorageOptScheduler)
    }

    /// 查询某个时间段内用户某种行为的总数统计
    public func count(
        since timeStampMillis: Int64,
        larkScene: LarkScene,
        meegoScene: MeegoScene,
        userActivity: UserActivity
    ) -> Observable<Int64> {
        guard let database = userDb.wrappedValue else {
            MeegoLogger.warnWithAssert("count user track failed due to database is nil", domain: UserTrackStorage.domain)
            return .error(StructureStorageOptError.databaseNotExist)
        }

        return Observable.create { ob in
            do {
                let count = try userTrackCount(
                    db: database,
                    larkScene: larkScene.dbValue,
                    meegoScene: meegoScene.rawValue,
                    action: userActivity.dbValue,
                    afterTimeStampMillis: timeStampMillis
                )
                MeegoLogger.debug("count user track success, count = \(count), db handle = \(database.handle)", domain: UserTrackStorage.domain)
                ob.end(count)
            } catch let error {
                let debugMsg = "count user track failed due to rust call error = \(error.localizedDescription)"
                MeegoLogger.warnWithAssert(debugMsg, domain: UserTrackStorage.domain)
                ob.end(with: StructureStorageOptError.rustInnerError(debugMsg: debugMsg))
            }
            return Disposables.create()
        }.subscribeOn(structureStorageOptScheduler)
    }

    /// 删除 before_time_stamp_mills 之前的用户行为记录
    public func delete(until timestampMills: Int64) -> Observable<Void> {
        guard let database = userDb.wrappedValue else {
            MeegoLogger.warnWithAssert("delete user track failed due to database is nil", domain: UserTrackStorage.domain)
            return .error(StructureStorageOptError.databaseNotExist)
        }

        return Observable.create { ob in
            do {
                try userTrackDelete(db: database, beforeTimeStampMillis: timestampMills)
                MeegoLogger.debug("delete user track success, db handle = \(database.handle)", domain: UserTrackStorage.domain)
                ob.end(())
            } catch let error {
                let debugMsg = "delete user track failed due to rust call error = \(error.localizedDescription)"
                MeegoLogger.warnWithAssert(debugMsg, domain: UserTrackStorage.domain)
                ob.end(with: StructureStorageOptError.rustInnerError(debugMsg: debugMsg))
            }
            return Disposables.create()
        }.subscribeOn(structureStorageOptScheduler)
    }
}
