//
//  DocsSercetDebugViewController+perf.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/9/21.
//  


import Foundation

#if BETA || ALPHA || DEBUG
extension DocsSercetDebugViewController {
    
    /// 手动创建一个功耗问题
    func createPowerIssue() {
        let serial = DispatchQueue(label: "ccm.debug.powerissue.\(UUID().uuidString)")
        serial.async {
            for i in 0 ... Int.max {
                let formatter = DateFormatter.init() // 这个操作比较耗性能
                formatter.dateFormat = "yyyy.MM.dd"
                print("make some log \(formatter.string(from: Date())), index:\(i)")
            }
        }
    }
}
#endif
