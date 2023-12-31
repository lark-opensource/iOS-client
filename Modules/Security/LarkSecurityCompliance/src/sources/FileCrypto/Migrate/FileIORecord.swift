//
//  FileIORecord.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/24.
//

import Foundation
import LarkSecurityComplianceInfra

final class FileIORecord {
    
    enum From {
        case write
        case read
    }
    
    enum Method {
        case `open`
        case close
    }

    @SafeWrapper private(set) var readCount = 0
    @SafeWrapper private(set) var writeCount = 0
    
    func record(from: From, method: Method) {
        switch from {
        case .write:
            writeCount += (method == .open ? 1 : -1)
        case .read:
            readCount += (method == .open ? 1 : -1)
        }
    }
}
