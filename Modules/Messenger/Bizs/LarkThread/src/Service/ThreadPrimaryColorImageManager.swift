//
//  ThreadPrimaryColorService.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/10/14.
//

import Foundation
import LarkUIKit

final class ThreadPrimaryColorManager: PrimaryColorManager {
    override class var trailKey: String {
        return "_thread_group_avatar_blend_v2"
    }

    override class func businessPath() -> String {
        return "Thread"
    }

}
