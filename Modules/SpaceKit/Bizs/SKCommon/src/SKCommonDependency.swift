//
//  SKCommonDependency.swift
//  SKCommon
//
//  Created by lijuyou on 2021/1/11.
//  


import Foundation
import RxSwift
import RxRelay
import SKFoundation
import WebKit
import SpaceInterface
import SKUIKit

public protocol SKCommonDependency {

    /// 当前文档editorView
    var currentEditorView: UIView? { get }

    /// 用到这里只是为了查询VC栈是否为空，直接使用下面那个就行了，废弃该使用
    /// 如果需要用到这个场景，请找@lizechuang
//    var docsBrowserVCStack: [UIViewController] { get }

    /// 为了兼容DocsBrowserView的static ViewWidth，但这样用是不对的，使用者移除它！
    @available(*, deprecated, message: "应该通过传递方式获取ViewWidth，重构吧")
    var browserViewWidth: CGFloat { get }
    
    
    var allDocsWebViews: [DocsWebViewV2] { get }

    /// 改变vConsole状态
    func changeVConsoleState(_ isOpen: Bool)

    /// 创建兜底WebView
    func createDefaultWebViewController(url: URL) -> UIViewController

    /// 创建完成后打开文档VC， ps：该接口不合理
    func createCompleteV2(token: String,
                          type: DocsType,
                          source: FromSource?,
                          ccmOpenType: CCMOpenType?,
                          templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                          templateSource: TemplateCenterTracker.TemplateSource?,
                          moduleDetails: [String: Any]?,
                          templateInfos: [String: Any]?,
                          extra: [String: Any]?) -> UIViewController?


    /// 重置Wiki Storage DB
    func resetWikiDB()

    func getWikiStorageObserver() -> SimpleModeObserver?

    /// 保存WikiNodeMeta信息
    func setWikiMeta(wikiToken: String, completion: @escaping (WikiInfo?, Error?) -> Void)

    func getSKOnboarding() -> Observable<[String: Bool]>

    func doneSKOnboarding(keys: [String])
}
