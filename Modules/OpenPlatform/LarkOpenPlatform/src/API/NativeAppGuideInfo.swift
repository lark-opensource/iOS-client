//
//  NativeAppGuideInfo.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/5/16.
//

import Foundation
import LarkContainer

extension OpenPlatformAPI {
    
    static func getNativeAppGuideInfoAPI(app_ids: [String]?, resolver: UserResolver
) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getNativeAppGuideInfo, resolver: resolver)
            .useSession()
            .setScope(.nativeApp)
            .appendParam(key: .cli_ids, value: app_ids)
    }
    
}
