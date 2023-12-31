//
//  DBErrorStatistics.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/9/26.
//
import Foundation
import SQLite
import SKFoundation

public enum DbCustomerErrCode: Int {
    case jsonEncodeErrer = 1000001
}

public enum DbErrorFromSource: String {
    case fileList
    case cache
    case fileListGetData
    case fileListGetOrignalData
    case ncGetOrignalData
    case fileListMigrationCreate
    case fileListMigrationUpdate
    case fileListMigrationAddMiss
    case fileListMigrationProgress
    case jsonEncodeErr
    case cypherDbWithKeyFileList
    case cypherDbWithKeyCache
    case cypherInnerFileList
    case cypherInnerCache
}

public enum DBErrorStatistics {
    public static func dbStatisticsFor(error: Error, fromSource: DbErrorFromSource = DbErrorFromSource.fileList) {
        guard let sqlErr = error as? SQLite.Result else {
            return
        }

        guard case .error(let message, let code, _) = sqlErr else {

            spaceAssertionFailure("db error is not SQLite.Result")
            return
        }

        let params: [String: Any] = ["doc_db_err_source": fromSource.rawValue,
                                     "doc_db_error_code": code,
                                     "doc_db_error_message": message]
        DocsTracker.log(enumEvent: .dbError, parameters: params)
    }

    public static func dbCustomerReport(errorCode: DbCustomerErrCode, msg: String, fromSource: DbErrorFromSource = DbErrorFromSource.jsonEncodeErr) {
        self.dbCustomerReport(errorCode: errorCode.rawValue, msg: msg, fromSource: fromSource)
    }

    public static func dbCustomerReport(errorCode: Int, msg: String, fromSource: DbErrorFromSource = DbErrorFromSource.jsonEncodeErr) {
        let params: [String: Any] = ["doc_db_err_source": fromSource,
                                     "doc_db_error_code": errorCode,
                                     "doc_db_error_message": msg]
        DocsTracker.log(enumEvent: .dbError, parameters: params)
    }
}
