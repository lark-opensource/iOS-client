//
//  SCLoggerWrapper.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/12/24.
//

import Foundation

public final class SCLoggerWrapper: NSObject {
    @objc
    public static func sc_info(_ msg: String, file: String = #fileID) {
        SCLogger.info(msg, file: file)
    }
}
