//
//  DocSessionDelegate.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/12.
//

import Alamofire

class DocSessionDelegate: SessionDelegate {
    override func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        super.urlSession(session, task: task, didFinishCollecting: metrics)
        self[task]?.delegate.netMetrics = metrics
    }
}

// MARK: - add metrics get/set method
extension TaskDelegate {
    private static var metricsKey: UInt8 = 0
    var netMetrics: URLSessionTaskMetrics? {
        get { return objc_getAssociatedObject(self, &TaskDelegate.metricsKey) as? URLSessionTaskMetrics }
        set { objc_setAssociatedObject(self, &TaskDelegate.metricsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

}

extension Timeline: DocsNetTimeLine {
}
