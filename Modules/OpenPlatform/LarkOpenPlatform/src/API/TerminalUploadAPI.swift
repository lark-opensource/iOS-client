//
//  TerminalUploadAPI.swift
//  LarkOpenPlatform
//
//  Created by tujinqiu on 2019/9/23.
//

import Foundation
import LarkContainer

extension OpenPlatformAPI {
    public static func TerminalUploadAPI(location: Any?,
                                         wifi: Any?,
                                         timestamp: String,
                                         did: String,
                                         resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .terminalUpload, resolver: resolver)
            .appendParam(key: .location, value: location)
            .appendParam(key: .wifi, value: wifi)
            .appendParam(key: .timestamp, value: timestamp)
            .appendParam(key: .deviceID, value: did)
            .useSession()
            .setScope(.uploadInfo)
    }
}
