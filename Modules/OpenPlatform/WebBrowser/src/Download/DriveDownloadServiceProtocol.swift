//
//  DriveDownloadServiceProtocol.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/7/18.
//

import Foundation

public protocol DriveDownloadServiceProtocol {
    func canOpen(fileName: String, fileSize: UInt64?, appID: String) -> Bool
    func showDrivePreview(_ filename: String, fileURL: URL, filetype: String?, fileId: String?, thirdPartyAppID: String?, appID: String, from: WebBrowser)
}
