//
//  EditorManager+Interface.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/3/26.
//

import SKFoundation
import SKCommon
import SKUIKit

public protocol EditorManagerDelegate: AnnouncementDelegate, LarkOpenAgent {
    func editorManager(_ editorManager: EditorManager, requiresToHandleOpen url: String, in browser: BrowserViewControllerAbility)
    func editorManager(_ editorManager: EditorManager, syncFinished browser: BrowserViewControllerAbility?)

    func editorManagerRequestShareAccessory(_ editorManager: EditorManager, browser: BrowserViewControllerAbility) -> UIView?
    func editorManager(_ editorManager: EditorManager, markFeedMessagesRead params: [String: Any], in browser: BrowserViewControllerAbility?)
    func editorManagerMakeVC(_ editorManager: EditorManager, url: URL) -> UIViewController?

    func editorManager(_ editorManager: EditorManager, markFeedCardShortcut feedId: String, isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?)
    func editorManager(_ editorManager: EditorManager, getShortcutFor feedId: String) -> Bool
}

public protocol BrowserControllable: AnyObject {
    var browerEditor: BrowserView? { get }
    var navigationBar: SKNavigationBar { get }
    func updateUrl(_ url: URL)
    func setDismissDelegate(_ newDelegate: BrowserViewControllerDelegate?)
    func setNavigationBarHidden(_ hidden: Bool, animated: Bool)
    func setToggleSwipeGestureEnable(_ enable: Bool)
    func setLandscapeStrategyWhenAppear(_ enable: Bool)
}

public typealias BrowserViewControllerAbility = BrowserControllable & UIViewController

// 保留当前BrowerVC栈，弱引用
public final class WeakBrowserVCAbility {
    private(set) weak var value: BrowserViewControllerAbility?
    init(_ value: BrowserViewControllerAbility?) {
        self.value = value
    }
}
