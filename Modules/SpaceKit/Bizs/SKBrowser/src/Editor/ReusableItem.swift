//
//  ReusableItem.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/5/24.
//  

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

public protocol DocReusableItem: AnyObject, Hashable {
    /// 被使用的次数
    var usedCounter: Int { get  set }
    /// 复用池中的index
    var poolIndex: Int { get  set }
    var isInEditorPool: Bool { get set }
    var preloadStatus: ObserableWrapper<PreloadStatus> { get }
    var webviewHasBeenTerminated: ObserableWrapper<Bool> { get }
    var editorIdentity: String { get }
    var openSessionID: String? { get set }
    var reuseState: String { get }
    var attachUserId: String? { get set }

    func canReuse(for type: DocsType) -> Bool

    @discardableResult
    func preload() -> Self
    var isHidden: Bool { get set }
    /// 加到视图层级上，加快预加载速度
    func addToViewHierarchy() -> Self
    func attachToWindow()
    func removeFromViewHierarchy(_ removeSuperView: Bool)

    func loadFailView()

    /// 预加载启动的时刻
    var preloadStartTimeStamp: TimeInterval { get set }

    var preloadEndTimeStamp: TimeInterval { get set }
    /// webview开始loadUrl的时刻
    var webviewStartLoadUrlTimeStamp: TimeInterval { get set }
    
    func prepareForReuse()
    
    /// 是否收到了前端的clearDone通知，代表跟前端的接口调用已结束。复用池会监听这个通知，再将达到使用上限的webview移除
    var webViewClearDone: ObserableWrapper<Bool> { get set }
    
    var isResponsive: Bool { get }
    var isInViewHierarchy: Bool { get }
    var isInVCFollow: Bool { get }
    var isLoadingStatus: Bool { get }
    var isLoadSuccess: Bool { get }
}

extension DocReusableItem {
    func increaseUseCount() {
        usedCounter += 1
    }
    
    var hasPreloadSomething: Bool {
        if DocsUserBehaviorManager.isEnable() {
            return preloadStatus.value.hasLoadSomeThing
        } else {
            return self.canReuse(for: .docX) //原来都是用docx判断
        }
    }
}

protocol DocReusableItemRecorder: AnyObject {
    associatedtype ReusableItem: DocReusableItem
    func remove(_ item: ReusableItem)
}
