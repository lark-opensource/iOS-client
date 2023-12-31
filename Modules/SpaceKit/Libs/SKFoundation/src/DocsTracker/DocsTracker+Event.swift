//
//  DocsTracker+Event.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/12/17.
//

import Foundation

public protocol DocsTrackerEventType {
    var stringValue: String { get }
    var shouldAddPrefix: Bool { get }
}

extension DocsTracker {
    public enum InnerEventType: String, DocsTrackerEventType {
        case fetchServerResponse         = "dev_performance_native_network_request" //客户端发起网络请求，开始到结束
        case fetchServerSubResponse      = "dev_performance_native_network_stage" //客户端发起网络请求，某次请求（可能会重试）
        case pictureUpload               = "dev_performance_native_picture_upload"
        case offlineResFirstUnzipStatus  = "offline_res_unzip"
        case offlineResRetryUnzipStatus  = "offline_res_unzip_retry"
        case offlineResUnzipFailReason   = "offline_res_unzip_fail"

        public var stringValue: String {
            self.rawValue
        }

        public var shouldAddPrefix: Bool {
            return true
        }
    }
}
