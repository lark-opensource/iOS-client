//
//  DocsNetTimeLine.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/12.
//

import Foundation

protocol DocsNetTimeLine {
    var requestDuration: TimeInterval { get }
}

class DocsNetTimeInfo: DocsNetTimeLine {
    var timelines = [DocsNetTimeLine]()

    var requestDuration: TimeInterval {
        return timelines.map { $0.requestDuration }.reduce(0, +)
    }
}
