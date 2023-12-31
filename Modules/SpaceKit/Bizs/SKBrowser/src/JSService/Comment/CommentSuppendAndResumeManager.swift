//
//  CommentSuppendAndResumeManager.swift
//  SKBrowser
//
//  Created by zengsenyuan on 2022/7/22.
//  


import SKCommon

public final class CommentSuppendAndResumeManager {

    static public func suppendIfNeed(_ checkVC: UIViewController,
                                     by jsEngine: BrowserJSEngine?,
                                     isInMagicShare: Bool,
                                     source: String = #fileID) {
        if /*Self.isCommentVC(checkVC)*/false, isInMagicShare {
            jsEngine?.simulateJSMessage(DocsJSService.simulateSuppendComment.rawValue, params: ["source": source])
        }
    }

    static public func resume(by jsEngine: BrowserJSEngine?,
                              isInMagicShare: Bool,
                              source: String = #fileID) {
        if isInMagicShare {
            jsEngine?.simulateJSMessage(DocsJSService.simulateResumeComment.rawValue, params: ["source": source])
        }
    }
}
