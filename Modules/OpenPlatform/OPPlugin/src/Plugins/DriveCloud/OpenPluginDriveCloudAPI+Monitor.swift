//
//  OpenPluginDriveCloudAPI+Monitor.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/9/6.
//

import Foundation

// MARK: - Monitor
extension OpenPluginDriveCloudAPI {
    struct MonitorEventName {
        static let UploadStart = "op_upload_file_to_cloud_start"
        static let UploadResult = "op_upload_file_to_cloud_result"
        static let DownloadStart = "op_download_file_from_cloud_start"
        static let DownloadResult = "op_download_file_from_cloud_result"
        static let PreviewStart = "op_open_file_from_cloud_start"
        static let PreviewResult = "op_open_file_from_cloud_result"
    }
}
