//
//  Util.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import Foundation

func excuteInMain(_ callback: () -> Void) {
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.sync {
            callback()
        }
    }
}
