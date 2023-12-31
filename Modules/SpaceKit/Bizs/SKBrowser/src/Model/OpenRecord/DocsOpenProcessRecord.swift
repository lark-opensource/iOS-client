//
//  DocsOpenProcessRecord.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/20.
//

import Foundation
import SKCommon
import SKFoundation

struct DocsOpenProcessRecord {
    private static let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var currentInfo = ObserableWrapper<String>("")

    func appendInfo(_ info: String) {
        let timedInfo = DocsOpenProcessRecord.dateFormatter.string(from: Date()) + ": " + info + "\n"
        currentInfo.value += timedInfo
    }
}
