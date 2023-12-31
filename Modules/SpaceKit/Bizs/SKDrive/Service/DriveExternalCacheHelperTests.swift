//
//  DriveExternalCacheHelperTests.swift
//  SKDrive-Unit-Tests
//
//  Created by zenghao on 2023/12/21.
//

import XCTest
@testable import SKFoundation
@testable import SKDrive

final class DriveExternalCacheHelperTests: XCTestCase {


    // Downgrade video playing to origin online playing
    // Do not check video meta
    // update state: endTranscoding -> endTranscoding -> setupPreview
    func testDisableUseDriveExternalCacheFG() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.drive.add_preview_cache_enable",
                                      value: false)
        let fileInfo = DKFileInfo(appId: "1001",
                                 fileId: "fileid",
                                 name: "test.ogg",
                                 size: 1024,
                                 fileToken: "fileToken",
                                 authExtra: authExtra())

        DriveExternalCacheHelper.getLocalIMVideoCache(fileInfo: fileInfo) { previewInfo in
            XCTAssertTrue(previewInfo == nil)
        }
    }

    func testNoAuthExtra() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.drive.add_preview_cache_enable",
                                      value: true)
        
        let fileInfo = DKFileInfo(appId: "1001",
                                 fileId: "fileid",
                                 name: "test.ogg",
                                 size: 1024,
                                 fileToken: "fileToken",
                                 authExtra: nil)

        DriveExternalCacheHelper.getLocalIMVideoCache(fileInfo: fileInfo) { previewInfo in
            XCTAssertTrue(previewInfo == nil)
        }
    }
    
    func testNoMsgID() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.drive.add_preview_cache_enable",
                                      value: true)
        
        let fileInfo = DKFileInfo(appId: "1001",
                                 fileId: "fileid",
                                 name: "test.ogg",
                                 size: 1024,
                                 fileToken: "fileToken",
                                 authExtra: authExtraWithoutMsgID())

        DriveExternalCacheHelper.getLocalIMVideoCache(fileInfo: fileInfo) { previewInfo in
            XCTAssertTrue(previewInfo == nil)
        }
        
    }
    
    func testNotIMFile() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.drive.add_preview_cache_enable",
                                      value: true)
        
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)

        DriveExternalCacheHelper.getLocalIMVideoCache(fileInfo: fileInfo) { previewInfo in
            XCTAssertTrue(previewInfo == nil)
        }
    }


    
    private func authExtra() -> String {
        return "{\"msg_id\":\"7311272410442301468\",\"chat_id\":\"6581293340594012430\",\"auth_file_key\":\"file_v3_0061_3690a819-8a9c-4655-8214-94d01cf1020g\"}"
    }
    
    private func authExtraWithoutMsgID() -> String {
        return "{\"chat_id\":\"6581293340594012430\",\"auth_file_key\":\"file_v3_0061_3690a819-8a9c-4655-8214-94d01cf1020g\"}"
    }


}
