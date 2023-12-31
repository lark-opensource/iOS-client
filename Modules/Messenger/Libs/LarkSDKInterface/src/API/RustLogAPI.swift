//
//  RustLogAPI.swift
//  Pods
//
//  Created by lichen on 2018/10/10.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

// 客户端直接把日志传递给SDK, SDK 会流式上传服务器 可用于服务器报警
public protocol RustLogAPI {
    func log(level: RustPB.Tool_V1_SetLogBySDKRequest.Level, tag: String, message: String, extra: [String: String]) -> Observable<Void>
}
