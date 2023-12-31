//
//  MoreActionHandler.swift
//  SpaceKit
//
//  Created by liujinwei on 2023/2/10.
//  


import Foundation
import SKCommon
import SKBrowser
import EENavigator

class UtilMoreActionHandler: InsideMoreActionHandler {

    override func openCopyFileWith(_ fileUrl: URL, from: UIViewController) {
        let browser = EditorManager.shared.currentEditor
        if browser?.vcFollowDelegate == nil {
            Navigator.shared.push(fileUrl, from: from)
        } else {
            guard let browser = browser else { return }
            _ = EditorManager.shared.requiresOpen(browser, url: fileUrl)
        }
    }
    
}
