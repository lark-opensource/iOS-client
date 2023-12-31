//
//  PlainError.swift
//  Lark
//
//  Created by liuwanlin on 2018/7/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct PlainError: Error {
    public let localizedDescription: String

    public init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
