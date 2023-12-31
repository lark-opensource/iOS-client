//
//  BrowserViewController+Scene.swift
//  SKBrowser
//
//  Created by 邱沛 on 2021/1/25.
//

import LarkSceneManager
import SKCommon
import SpaceInterface
import LarkDocsIcon

extension BrowserViewController: SceneProvider {
    public var docsTitle: String? {
        self.editor.docsInfo?.title
    }

    public var objToken: String {
        self.editor.docsInfo?.urlToken ?? ""
    }

    public var objType: DocsType {
        return self.editor.docsInfo?.urlType ?? .unknownDefaultType
    }
    
    public var userInfo: [String: String] {
        return [:]
    }

    public var currentURL: URL? {
        return self.editor.currentURL
    }
    
    public var version: String? {
        return self.editor.docsInfo?.versionInfo?.version
    }
}
