//
//  LarkInterface+Browser.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/4/20.
//  从SKEditorPlugin迁移

import Foundation
import WebKit
import LarkWebViewContainer

public protocol SKEditorDocsViewObserverProtocol {
    func startObserver()
    func removeObserver()
}

public protocol SKEditorDocsViewRequestProtocol: AnyObject {
    func editorRequestMentionData(with key: String, success: @escaping ([MentionInfo]) -> Void)
}

// 提供给小程序使用
public protocol SKEditorDocsViewCreateInterface {
    func createEditorDocsView(jsEngine: LarkWebView?, uiContainer: UIView, delegate: SKEditorDocsViewRequestProtocol? , bridgeName: String) -> SKEditorDocsViewObserverProtocol
}
