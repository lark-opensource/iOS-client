//
//  OpenPluginDriveTests+Mock.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/6.
//

import Foundation
@testable import OPPlugin
import OPUnitTestFoundation
@available(iOS 13.0, *)
extension OpenPluginDriveTests {
    
    typealias APIName = OpenPluginDriveCloudAPI.APIName
    
    // MARK: Params
    
    struct Params {
        struct DownloadFile {
            static let noFilePath: [AnyHashable: Any] = [
                "fileToken" : "testFileToken",
                "mountPoint" : "testMountPoint",
                "mountNodePoint" : "testMountNodePoint",
                "taskID" : "testTaskID",
            ]
        }
        
        struct UploadFile {
            
            static let testFilePath = "ttfile://user/testPath"
            
            static let validFilePath: [AnyHashable: Any] = [
                "filePath" : testFilePath,
                "mountPoint" : "testMountPoint",
                "mountNodePoint" : "testMountNodePoint",
                "taskID" : "testTaskID",
            ]
        }
    }
    
    // MARK: Setting
    
    struct Setting {
        static let key = "gadget_drive_api"
        
        static let mockValueDefaultTrueTestAppIDFalse = """
        {
            "downloadFileFromCloud": {
                "testAppID": false,
                "default": true
            },
            "uploadFileToCloud": {
                "testAppID": false,
                "default": true
            },
            "openFileFromCloud": {
                "testAppID": false,
                "default": true
            }
        }
        """
        
        static let mockValueDefaultFalseTestAppIDTrue = """
        {
            "downloadFileFromCloud": {
                "testAppID": true,
                "default": false
            },
            "uploadFileToCloud": {
                "testAppID": true,
                "default": false
            },
            "openFileFromCloud": {
                "testAppID": true,
                "default": false
            }
        }
        """
        
        static let mockValueEnable = """
        {
            "downloadFileFromCloud": {
                "default": true
            },
            "uploadFileToCloud": {
                "default": true
            },
            "openFileFromCloud": {
                "default": true
            }
        }
        """
        
        static let mockValueDisable = """
        {
            "downloadFileFromCloud": {
                "default": false
            },
            "uploadFileToCloud": {
                "default": false
            },
            "openFileFromCloud": {
                "default": false
            }
        }
        """
    }
}
