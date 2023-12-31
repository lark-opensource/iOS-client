//
//  DriveUploadAndDonwloadStastic.swift
//  SKECM
//
//  Created by bupozhuang on 2021/3/17.
//

import Foundation
import SKFoundation
import SKCommon

class DriveUploadAndDonwloadStastic: UploadAndDownloadStastis {
    static let shared = DriveUploadAndDonwloadStastic()
    
    func recordUploadInfo(module: String, uploadKey: String, isDriveSDK: Bool) {
        let moduleInfo = DriveStatistic.ModuleInfo(module: module, srcModule: "", subModule: "", isExport: false, isDriveSDK: isDriveSDK, fileID: "")
        DriveStatistic.setKey(uploadKey, moduleInfo: moduleInfo, isUpload: true)
    }
    
    func recordDownloadInfo(module: String, downloadKey: String, fileID: String, fileSubType: String?, isExport: Bool, isDriveSDK: Bool) {
        let moduleInfo = DriveStatistic.ModuleInfo(module: module, srcModule: "", subModule: "", isExport: isExport, isDriveSDK: isDriveSDK, fileID: fileID)
        DriveStatistic.setKey(downloadKey, moduleInfo: moduleInfo, isUpload: false)
    }
}
