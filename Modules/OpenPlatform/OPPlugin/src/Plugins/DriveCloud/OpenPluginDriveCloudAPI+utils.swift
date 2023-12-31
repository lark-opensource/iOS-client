//
//  OpenPluginDriveCloudAPI+utils.swift
//  OPPlugin
//
//  Created by 刘焱龙 on 2022/12/29.
//

import Foundation
import LarkOpenAPIModel

extension OpenPluginDriveCloudAPI {
    enum DriveErrorCode: Int {
        case canceled = 1000
    }

    func extraString(extra: [AnyHashable: Any]?) -> String? {
        guard let extra = extra else {
            return nil
        }
        do {
            return try extra.convertToJsonStr()
        } catch {
            return nil
        }
    }

    static func driveSDKExtraErrString(errorCode: Int?, driveError: Error?) -> String {
        var code = 999
        if let realErrorCode = errorCode {
            code = realErrorCode
        }
        if let driveErrorCode = (driveError as? NSError)?.code {
            code = driveErrorCode
        }
        return "errCode: \(code)"
    }
}
