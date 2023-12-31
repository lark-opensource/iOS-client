//
//  SynchronizedClosure.swift
//  MailSDK
//
//  Created by zenghao on 2018/8/19.
//

import Foundation

func asyncRunInMainThread(_ block: @escaping () -> Void) {
    if Thread.current == Thread.main {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
