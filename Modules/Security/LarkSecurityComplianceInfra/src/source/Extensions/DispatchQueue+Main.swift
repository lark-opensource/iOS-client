//
//  DispatchQueue+Main.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2023/1/3.
//

import UIKit

public extension DispatchQueue {
    public static func runOnMainQueue(_ block: (() -> Void)?) {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async {
                block?()
            }
        }
    }
}
