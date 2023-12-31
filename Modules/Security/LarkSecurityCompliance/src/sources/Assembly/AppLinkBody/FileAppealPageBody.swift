//
//  FileAppealPageBody.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/18.
//

import Foundation
import EENavigator

// 这里的url参数需要下发
public struct FileAppealPageBody: CodablePlainBody {

    public static let pattern: String = "/client/file_security_check/appeal"

    public let objToken: String
    public let version: Int
    public let fileType: Int
    public let locale: String

    public init(objToken: String, version: Int, fileType: Int, locale: String) {
        self.objToken = objToken
        self.version = version
        self.fileType = fileType
        self.locale = locale
    }
}
