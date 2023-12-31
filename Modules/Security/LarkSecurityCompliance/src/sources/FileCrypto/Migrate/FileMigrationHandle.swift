//
//  FileMigrationHandle.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/27.
//

import UIKit

protocol FileRecordHandle {
    var filePath: String { get }
}

protocol FileMigrationHandle: FileRecordHandle {
    var migrationID: String { get }
}
