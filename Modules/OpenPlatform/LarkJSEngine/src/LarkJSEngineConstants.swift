//
//  LarkJSEngineConstants.swift
//  LarkJSEngine
//
//  Created by Jiayun Huang on 2021/12/3.
//

import Foundation

public enum LarkJSEngineType: Int, Encodable {
    case jsCore = 0
    // case falconJSCore = 1 // FalconJSCore, 已下线
    case vmsdkJSCore = 2
    case vmsdkQuickJS = 3
}
