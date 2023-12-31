//
//  SpaceWebViewRecorder.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/5/17.
//  

import Foundation
import SKCommon
import SKFoundation

class SpaceWebViewRecorder<ReusableItem: DocReusableItem>: DocReusableItemRecorder {

    private(set) var webViewList: [ReusableItem] = []

    var count: Int {
        return webViewList.count
    }

    func add(_ webview: ReusableItem) {
        DocsLogger.info("add webview to spaceWebViewRecorder \(ObjectIdentifier(webview))")
        webViewList.append(webview)
    }

    func remove(_ webview: ReusableItem) {
        DocsLogger.info("remove webview from spaceWebViewRecorder \(ObjectIdentifier(webview))")
        webViewList.removeAll(where: {
            $0 == webview
        })
    }
    
    func contains(_ webview: ReusableItem) -> Bool {
        return webViewList.contains(webview)
    }
    
    func docsOpenFinish(vcfollow: Bool) -> Bool {
        for webview in webViewList {
            if webview.isInEditorPool == false {
                if vcfollow {
                    if webview.isInVCFollow, !webview.isLoadSuccess {
                        return false
                    }
                } else if !webview.isLoadSuccess {
                    return false
                }
            }
        }
        return true
    }
    
    func hasOpenDocs() -> Bool {
        for webview in webViewList {
            if webview.isInEditorPool == false {
                return true
            }
        }
        return false
    }

//    func removeAll() {
//        DocsLogger.info("remove all webviews from spaceWebViewRecorder")
//        webViewList.removeAll()
//    }
}
