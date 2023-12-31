//
//  OPMockDriveAPI.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/3.
//

import Foundation
import RxSwift
import LarkContainer
import OPPlugin

struct OPMockDriveAPI {
    @InjectedSafeLazy var downloader: OpenPluginDriveDownloadProxy
    @InjectedSafeLazy var uploader: OpenPluginDriveUploadProxy
    @InjectedSafeLazy var previewProxy: OpenPluginDrivePreviewProxy
}
