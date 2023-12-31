//
//  DKFilePreviewState+Equatable.swift
//  SKDrive-Unit-Tests
//
//  Created by ByteDance on 2022/12/29.
//

import Foundation
@testable import SKDrive


extension DKFilePreviewState: Equatable {
    public static func == (lhs: SKDrive.DKFilePreviewState, rhs: SKDrive.DKFilePreviewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
            (.endLoading, .endLoading),
            (.transcoding, .transcoding),
            (.endTranscoding, .endTranscoding),
            (.showDownloading, .showDownloading),
            (.downloading, .downloading),
            (.downloadCompleted, .downloadCompleted),
            (.setupPreview, .setupPreview),
            (.setupUnsupport, .setupUnsupport),
            (.forbidden, .forbidden),
            (.setupFailed, .setupFailed),
            (.deleteFileRestore, .deleteFileRestore),
            (.noPermission, .noPermission),
            (.showPasswordInputView, .showPasswordInputView),
            (.willChangeMode, .willChangeMode),
            (.changingMode, .changingMode),
            (.didChangeMode, .didChangeMode):
            return true
        default:
            return false
            
        }
    }
    
    
}

