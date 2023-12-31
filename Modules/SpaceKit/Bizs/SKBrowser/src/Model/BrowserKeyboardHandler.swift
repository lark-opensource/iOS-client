//
//  BrowserKeyboardHandler.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/29.
//  

import SKFoundation
import SKUIKit
import SKCommon
import EENavigator
import WebKit
import LarkUIKit

protocol BrowserKeyboardHandlerDelegate: AnyObject {
    var docsInfo: DocsInfo? { get }
    var currentTrigger: String? { get }
    func onKeyboardChanged(_ isShow: Bool, innerHeight: CGFloat, trigger: String)
}

public enum DocsKeyboardTrigger: String { // 触发键盘弹起
    case keyboard = "keyboard" // 键盘遮挡webview高度
    case editor = "editor"     // 编辑器
    case comment = "comment"   // 评论
    case sheet = "sheet"   // 表格
    case sheetEditor = "sheet_editor"   // sheet redesign
    case sheetFAB = "fab"               // 表格fab面板
    case sheetOperation = "oppanel"
    case menuEvent = "menuEvent"  // 显示自定义菜单
    case search = "search"
    case blockEquation = "equation"
    case NOTShowToolBar = "notShowToolBar"
    case reminderTextView = "reminder_text_edit"
    case sheetFilterSearch = "sheet_filter"
    case codeBlock = "codeBlockLanguagePicker"
    case catalog = "catalog"
}

class BrowserKeyboardHandler {
    unowned var editorView: DocsEditorViewProtocol
    var maxKeyboardHeight: CGFloat = 0.0
    weak var delegate: BrowserKeyboardHandlerDelegate?
    var editorViewKeyboard: Keyboard?
    // 记录当前键盘状态
    var keyboardIsShow: Bool = false

    init(editorView: DocsEditorViewProtocol) {
        self.editorView = editorView
        self.editorViewKeyboard = Keyboard(listenTo: [editorView])
    }

    public func startMonitorKeyboard() {
        editorViewKeyboard?.start()
    }

    public func stopMonitorKeyboard() {
        editorViewKeyboard?.stop()
    }

    func setKeyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) {
        if let webview = editorView as? WKWebView {
            webview.scrollView.keyboardDismissMode = mode
        }
    }
}

// MARK: - BrowserViewResponder
extension BrowserKeyboardHandler: BrowserUIResponder {
    var inputAccessory: SKInputAccessory {
        return self.editorView.skEditorViewInputAccessory
    }

    @discardableResult
    func becomeFirst(trigger: String) -> Bool {
        setTrigger(trigger: trigger)
        return becomeFirst()
    }

    func becomeFirst() -> Bool {
        return editorView.becomeFirst()
    }

    func addKeyboardResponder(_ responder: UIResponder) {
        editorViewKeyboard?.addReponder(responder)
    }

    func setTrigger(trigger: String) {
        editorViewKeyboard?.trigger = trigger
    }

    func getTrigger() -> String? {
        return editorViewKeyboard?.trigger
    }

    @discardableResult
    func resign() -> Bool {
        return editorView.resign()
    }
}

// 以下是xurunkang写的，bianjunlin只是copy过来
// FIX FUCKING KEYBOARD EVENT
extension BrowserKeyboardHandler {
    func listenKeyboardEvent() {
        editorViewKeyboard?.on(events: [.didHide, .willShow, .willHide, .didShow, .willChangeFrame, .didChangeFrame]) { [weak self] (options) in
            self?.fixKeyboardEvent(options: options)
        }
    }

    private func fixKeyboardEvent(options: Keyboard.KeyboardOptions) {
        let event = options.event
        DocsLogger.info("BrowserKeyboardHandler keyboad event: \(options)", component: LogComponents.toolbar)
        if options.beginFrame == .zero && options.endFrame == .zero { return }
        if options.displayType == .floating {
            //ipad悬浮键盘没有大部分情况下没有hide和show事件，使用changeFrame事件结合beginFrame、endFrame判断状态
            switch event {
            case .willChangeFrame:
                handleFloatKeyboardWillChangeFrameEvent(options)
            case .didChangeFrame:
                handleFloatKeyboardDidChangeFrameEvemt(options)
            default:
                return
            }
        } else {
            switch event {
            case .willShow:
                handleWillShowEvent(options)
            case .didShow:
                editorViewKeyboard?.isShow = true
                keyboardIsShow = true
                handleWillShowEvent(options)
            case .willHide:
                if !(editorViewKeyboard?.isHiding ?? true) {
                    handleWillHideEvent(options)
                }
                maxKeyboardHeight = 0.0
                editorViewKeyboard?.isHiding = true
            case .didHide:
                editorViewKeyboard?.isHiding = false
                keyboardIsShow = false
                handleDidHideEvent(options)
            case .didChangeFrame:
                if  #available(iOS 16.0, *),
                    SKDisplay.pad,
                    options.trigger == DocsKeyboardTrigger.blockEquation.rawValue,
                    keyboardIsShow,
                    options.endFrame != .zero {
                    handleWillShowEvent(options)
                }

            default:
                return
            }
        }
    }

    private func handleWillShowEvent(_ options: Keyboard.KeyboardOptions) {

        var endKeyboardHeight = options.endFrame.size.height

        let beginKeyboardY = options.beginFrame.origin.y
        let endKeyboardY = options.endFrame.origin.y

        if  SKDisplay.phone,
            beginKeyboardY <= endKeyboardY,
            options.beginFrame != .zero {
            //规避特殊case，willshow发过来的begainFrame是zero，但是endFrame是正常值
            //https://meego.feishu.cn/larksuite/issue/detail/5128079?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
            return
        }
        
        // 妙控键盘,iOS16时，endKeyboardHeight也返回了全键盘的高度，需要用键盘hostView来计算实际的键盘高度
        if  #available(iOS 16.0, *),
            SKDisplay.pad, options.trigger == DocsKeyboardTrigger.blockEquation.rawValue,
            let hostView = Keyboard.keyboardHostView {
            endKeyboardHeight = SKDisplay.activeWindowBounds.height - hostView.frame.origin.y
        }
        
        if #available(iOS 14.0, *), SKDisplay.pad {
            if #unavailable(iOS 15.0) {
                //iPadOS14 妙控键盘点击工具栏收起按钮，还会有show事件
                //原因是webview.resignFirstResponder被hook了，调用之后又会触发becomeFirstResponder
                //导致有键盘show事件发生，特征为y值等于window高度
                //https://meego.feishu.cn/larksuite/issue/detail/7904836
                if endKeyboardY >= SKDisplay.activeWindowBounds.height { return }
            }
        }

        // 获取键盘触发者
        guard let trigger = DocsKeyboardTrigger(rawValue: options.trigger) else {
            DocsLogger.info("browser keyboard trigger 为 nil")
            return
        }

        // 通知前端键盘高度
        let innerHeight = fixInnerHeight(endKeyboardHeight, trigger: trigger, keyboardType: options.displayType)
        delegate?.onKeyboardChanged(true, innerHeight: innerHeight, trigger: trigger.rawValue)
    }

    private func handleWillHideEvent(_ options: Keyboard.KeyboardOptions) {
        _handleHideEvent(options)
    }

    private func handleDidHideEvent(_ options: Keyboard.KeyboardOptions) {
        _handleHideEvent(options)
    }
    
    private func handleFloatKeyboardWillChangeFrameEvent(_ options: Keyboard.KeyboardOptions) {
        guard Display.pad, options.displayType == .floating else {
            return
        }
        if options.beginFrame == .zero, options.endFrame != .zero {
            //ipad悬浮键盘出现
            handleWillShowEvent(options)
        } else if options.beginFrame != .zero, options.endFrame == .zero {
            editorViewKeyboard?.isHiding = true
        }
    }
    
    
    private func handleFloatKeyboardDidChangeFrameEvemt(_ options: Keyboard.KeyboardOptions) {
        guard Display.pad, options.displayType == .floating else {
            return
        }
        if options.beginFrame == .zero, options.endFrame != .zero {
            //ipad悬浮键盘出现
            editorViewKeyboard?.isShow = true
            keyboardIsShow = true
            handleWillShowEvent(options)
        } else if options.beginFrame != .zero, options.endFrame == .zero, options.beginFrame.size.height > 180 {
            //ipad悬浮键盘消失
            keyboardIsShow = false
            notifyKeyboardHide()
        }
        editorViewKeyboard?.isHiding = false
    }

    private func _handleHideEvent(_ options: Keyboard.KeyboardOptions) {
        let endKeyboardMinY = options.endFrame.minY
        let windowHeight = (editorView.window?.bounds.height ?? SKDisplay.activeWindowBounds.height)
        if SKDisplay.pad,
           windowHeight - endKeyboardMinY == 69 {

            //iPad妙控键盘下打开图片面板，然后再关闭图片面板，系统会发送键盘hide事件，但是其实这个时候键盘并没有正真的下掉，焦点也还在，所以需要屏蔽这种情况下的通知，避免前端关闭工具栏同时下掉键盘
            DocsLogger.info("BrowserKeyboardHandler _handleHideEvent ignor event", component: LogComponents.toolbar)
            // 获取键盘触发者
            guard keyboardIsShow,
                  let trigger = DocsKeyboardTrigger(rawValue: options.trigger) else {
                DocsLogger.info("browser keyboard trigger 为 nil")
                return
            }

            // 键盘高度发生变化, 通知前端
            let innerHeight = fixInnerHeight(options.endFrame.size.height, trigger: trigger, keyboardType: options.displayType)
            delegate?.onKeyboardChanged(true, innerHeight: innerHeight, trigger: trigger.rawValue)
            return
        }

        if options.event == .didHide {
            keyboardIsShow = false
        }
        
        //ipad键盘模式由固定切换到悬浮态时有hide事件传出，会导致文档退出编辑态，这里过滤一下，另外，悬浮键盘消失时又不会有hide事件传出
        if options.displayType != .floating {
            notifyKeyboardHide()
        }
    }

    private func notifyKeyboardHide() {
        guard let trigger = delegate?.currentTrigger else { return }
        delegate?.onKeyboardChanged(false, innerHeight: editorView.frame.height, trigger: trigger)
    }

    private func fixInnerHeight(_ keyboardHeight: CGFloat, trigger: DocsKeyboardTrigger, keyboardType: Keyboard.DisplayType) -> CGFloat {
        var toolBarHeight = DocsToolBar.Const.inherentHeight
        
        let noToolBarTriggers: [DocsKeyboardTrigger] = [.comment, .blockEquation, .NOTShowToolBar, .keyboard]
        if trigger == .sheet {
            toolBarHeight += DocsToolBar.Const.sheetInputViewHeight
        } else if noToolBarTriggers.contains(trigger) {
            toolBarHeight = 0
        }
        
        var keyboardHeight = keyboardHeight + toolBarHeight

        if let firstResponder = UIView.currentFirstResponder as? UIView {
            if firstResponder.isDescendant(of: editorView) {
                if let view = inputAccessory.realInputAccessoryView {
                    keyboardHeight -= view.frame.height
                }
            } else if let view = firstResponder.inputAccessoryView {
                keyboardHeight -= view.frame.height

                // fix: 全文评论触发的键盘，需要减去 webview 的 inputAccessoryView 的高度再加上评论框的高度
                if firstResponder is SKUDBaseTextView && trigger == .comment {
                    keyboardHeight += 80
                }
            }
        }

        maxKeyboardHeight = max(keyboardHeight, maxKeyboardHeight)
        if trigger == .blockEquation {
            //这里不知道为什么要自己记住历史的maxHeight...新增的blockEquation，不使用旧的逻辑
            let pointInWindow = editorView.convert(CGPoint(x: 0, y: 0), to: nil) //browserView可能不是全屏的，所以需要减去original.y
            let originalY = pointInWindow.y
            if keyboardType == .floating { keyboardHeight = 0 }
            let innerHeight = SKDisplay.activeWindowBounds.height - keyboardHeight - originalY
            return innerHeight
        }

        //根据键盘和工具栏高度计算webview的视口高度
        //获取webview上.zero在屏幕上的坐标
        //webview顶部到屏幕底部的距离减去键盘高度
        let zeroPointInScreen = editorView.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
        let innerHeight = UIScreen.main.bounds.height - zeroPointInScreen.y - maxKeyboardHeight
        
        if trigger == .keyboard {
            //返回webview被键盘遮挡住的高度（统一逻辑，一般情况下等于键盘高度，vc等场景下webview底部和屏幕底部不对齐）
            return editorView.frame.height - innerHeight
        } else {
            return innerHeight
        }
    }
}

private extension UIResponder {

    private static weak var _currentFirstResponder: UIResponder?

    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    @objc
    func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}
