//
//  DebugBody.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/17/19.
//
#if !LARK_NO_DEBUG
import Foundation
import EENavigator

public struct DebugBody: CodablePlainBody {
    public static let pattern = "//client/inner/debug"

    public init() {}
}
#endif
