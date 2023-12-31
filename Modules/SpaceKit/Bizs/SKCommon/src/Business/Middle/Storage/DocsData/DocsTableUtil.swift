//
//  DocsTableBase.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2019/12/26.
//

import Foundation
import SQLite
import SKFoundation

public enum DocsTableUtil {
    public static func safeGetColumn<V: Value>(column: Expression<V?>, record: Row, source: DbErrorFromSource = .fileListGetData) -> V? {
        var result: V?
        do {
            result = try record.get(column)
        } catch {
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: .fileListGetData)
        }
        return result
    }

    public static func safeGetColumn<V: Value>(column: Expression<V>, record: Row, source: DbErrorFromSource = .fileListGetData) -> V? {
        var result: V?
        do {
            result = try record.get(column)
        } catch {
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
            DBErrorStatistics.dbStatisticsFor(error: error, fromSource: source)
        }
        return result
    }

    public static func getOriColumn<V: Value>(_ column: Expression<V?>, record: Row) -> V? {
        return self.safeGetColumn(column: column, record: record, source: .fileListGetOrignalData)
    }

    public static func getOriColumn<V: Value>(_ column: Expression<V>, record: Row) -> V? {
        return self.safeGetColumn(column: column, record: record, source: .fileListGetOrignalData)
    }

    public static func getNCOriColumn<V: Value>(_ column: Expression<V?>, record: Row) -> V? {
        return self.safeGetColumn(column: column, record: record, source: .ncGetOrignalData)
    }

    public static func getNCOriColumn<V: Value>(_ column: Expression<V>, record: Row) -> V? {
        return self.safeGetColumn(column: column, record: record, source: .ncGetOrignalData)
    }
}
