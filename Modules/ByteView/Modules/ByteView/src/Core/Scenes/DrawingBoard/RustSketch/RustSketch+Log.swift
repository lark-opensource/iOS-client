//
//  RustSketch+Log.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/3/13.
//

import Foundation
import ByteViewTracker

private func sketchLog(cStr: UnsafePointer<Int8>?) {
    #if DEBUG
    guard let ptr = cStr else {
        return
    }
    let str = String(cString: ptr)
    RustSketch.logger.info(str)
    #endif
}

private func sketchInfo(cStr: UnsafePointer<Int8>?) {
    guard let ptr = cStr else {
        return
    }
    let str = String(cString: ptr)
    RustSketch.logger.info(str)
}

private func sketchWarn(cStr: UnsafePointer<Int8>?) {
    guard let ptr = cStr else {
        return
    }
    let str = String(cString: ptr)
    RustSketch.logger.warn(str)
}

private func sketchError(cStr: UnsafePointer<Int8>?) {
    guard let ptr = cStr else {
        return
    }
    let str = String(cString: ptr)
    RustSketch.logger.error(str)
}

private func sketchMonitor(jsonMsg: UnsafePointer<Int8>?) {
    guard let jsonMsg = jsonMsg else {
        return
    }

    let data = Data(bytes: jsonMsg, count: strlen(jsonMsg))
    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
       let name = json["key"] as? String {
        let params = json["params"] as? [String: Any]
        VCTracker.post(TrackEvent.raw(name: name, params: params ?? [:]))
        ByteViewSketch.logger.info("post rust_sketch track: \(name)")
    } else {
        ByteViewSketch.logger.error("post rust_sketch track failed: \(jsonMsg)")
    }
}

extension RustSketch {
    static let logger = Logger.sketchSDK
    static var defaultLogInstance = SketchLogInstance(log: sketchLog,
                                                      info: sketchInfo,
                                                      warn: sketchWarn,
                                                      error: sketchError,
                                                      monitor: sketchMonitor)
}
