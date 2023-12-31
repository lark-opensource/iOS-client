//
//  CalendarDocsView.swift
//  Action
//
//  Created by jiayi zou on 2018/10/23.
//

import UIKit
import Foundation
import LKCommonsLogging
import Swinject
import EENavigator
import LarkUIKit
import UniverseDesignFont
import CalendarRichTextEditor

private final class HodlderView: UIView {
    private let docView: UIView
    init(docView: UIView) {
        self.docView = docView
        super.init(frame: .zero)
        self.addSubview(docView)
        docView.frame = self.bounds
        self.clipsToBounds = true
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var autoLayoutHeight: CGFloat = 20.0 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    func setWidth(_ width: CGFloat) {
        var frame = self.docView.frame
        frame.size.width = width
        self.docView.frame = frame
        self.docView.setNeedsLayout()
        self.docView.layoutIfNeeded()
    }

    func shouldAutoResizing() {
        docView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = self.autoLayoutHeight
        return size
    }
}

final class CalendarDocsView: DocsViewHolder {
    var onPasteDocsCallBack: ((_ accessInfo: [Bool]) -> Void)?

    var openSelectTranslateHandler: ((String) -> Void)? {
        didSet {
            docsAPI.openSelectTranslateHandler = openSelectTranslateHandler
        }
    }

    var customHandle: ((URL, [String: Any]?) -> Void)? {
        didSet {
            docsAPI.customHandle = customHandle
        }
    }

    var disableBecomeFirstResponder: (() -> Bool)? {
        didSet {
            docsAPI.disableBecomeFirstResponder = disableBecomeFirstResponder
        }
    }

    var autoLayoutHeight: Bool = false
    func setDoc(html: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        if let width = displayWidth {
            wrapper.setWidth(width)
        }
        self.docsAPI.set(content: html, success: success, fail: fail)
    }

    func setDoc(data: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        if let width = displayWidth {
            wrapper.setWidth(width)
        }
        self.docsAPI.setDoc(data: data, success: success, fail: fail)
    }

    private let _logger = Logger.log(CalendarDocsView.self, category: "CalendarDocsView")

    private var shouldUpdateHeight = false

    private var shouldJumpToURL = false

    private var viewDidGet = false

    func logger() -> Log {
        return _logger
    }

    func set(placeHolder: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        var _placeHolder = DocsRichTextParam.PlaceholderProps()
        _placeHolder.text = placeHolder
        docsAPI.setPlaceholder(_placeHolder, success: success, fail: fail)
    }

    func getDocHtml(complete: @escaping (String?, Error?) -> Void) {
        docsAPI.getDocHtml(completion: complete)
    }

    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        docsAPI.setEditable(enable, success: success, fail: fail)
        docsAPI.setTextMenu(type: enable ? .readWrite : .readOnly)
    }

    func getPainText(complete: @escaping (String?, Error?) -> Void) {
        docsAPI.getText(completion: complete)
    }

    private var wrapper: HodlderView
    private var docsAPI: DocsRichTextViewAPI

    required init(docsRichTextViewAPI: DocsRichTextViewAPI) {
        self.docsAPI = docsRichTextViewAPI
        wrapper = HodlderView(docView: docsAPI.view)
        docsAPI.delegate = self
        docsAPI.loadCalendar()

        let styleString = "16"
        var style = DocsEditStyle()
        style.isSysBold = UDFontAppearance.isBoldTextEnabled
        style.fontSize = styleString
        self.setStyle(style, success: {
            print("set style success")
        }) { [weak self] (_) in
            self?.logger().error("set docs style failed")
        }
    }

    func getDocsView(_ autoUpdateHeight: Bool, shouldJumpToWebPage: Bool) -> UIView {
        _logger.info("object CalendarDocsView - \(ObjectIdentifier(self)), getDocsView:(autoUpdateHeight:\(autoUpdateHeight))")
        self.autoLayoutHeight = autoUpdateHeight
        if !autoUpdateHeight {
            wrapper.shouldAutoResizing()
        }
        shouldJumpToURL = shouldJumpToWebPage
        viewDidGet = true
        return wrapper
    }

    func getDocData(complete: @escaping (String?, Error?) -> Void) {
        docsAPI.getDocData(completion: complete)
    }

    func setStyle(_ style: DocsEditStyle, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        var customStyle = DocsRichTextParam.AditStyle()
        customStyle.heading = style.heading
        customStyle.fontSize = style.fontSize
        customStyle.fontWeight = style.fontWeight
        customStyle.fontFamily = style.fontFamily
        customStyle.textAlign = style.textAlign
        customStyle.listMarginText = style.listMarginText
        customStyle.horizontalLRSpace = style.horizontalLRSpace
        customStyle.docBodyPadding = style.docBodyPadding
        customStyle.innerHeight = style.innerHeight
        customStyle.color = style.color
        customStyle.minHeight = style.minHeight
        customStyle.maxHeight = style.maxHeight
        customStyle.background = style.background
        customStyle.isSysBold = style.isSysBold
        docsAPI.setStyle(customStyle, success: success, fail: fail)
    }

    func setColor(_ red: Int, _ green: Int, _ blue: Int, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        let styleStr = "rgb(\(red),\(green),\(blue))"
        var style = DocsRichTextParam.AditStyle()
        style.color = styleStr
        style.isSysBold = UDFontAppearance.isBoldTextEnabled
        docsAPI.setStyle(style, success: success, fail: fail)
    }

    func setThemeConfig(_ config: ThemeConfig) {
        docsAPI.setThemeConfig(config)
    }

    func isNotChanged(complete: @escaping (Bool?, Error?) -> Void) {
        docsAPI.checkKeep(completion: complete)
    }

    var bridgeInvalid: Bool {
        return docsAPI.bridgeInvalid
    }

    func becomeFirstResponder() {
        docsAPI.becomeFirstResponder()
    }
}

extension CalendarDocsView: DocsRichTextViewDelegate {
    func richTextView(requireOpen url: URL) -> Bool {
        if let customHandle = customHandle, shouldJumpToURL == true {
            customHandle(url, nil)
            return false
        }
        return true
    }

    func richTextViewJSContextDidReady() { }

    func richTextViewContentSizeDidChange(_ size: CGSize) {
        _logger.info("object CalendarDocsView - \(ObjectIdentifier(self)), sizeChange:(size:\(size)), autoLayoutHeight:\(autoLayoutHeight), viewDidGet:\(viewDidGet)")
        if self.autoLayoutHeight && viewDidGet {
            // 为了解一行状态下编辑编辑页docsview底部高度过高问题
            docsAPI.view.frame = CGRect(origin: .zero, size: size)
            wrapper.autoLayoutHeight = size.height - 5
            wrapper.superview?.layoutIfNeeded()
            docsAPI.setCanScroll(false)
        }
    }

    func onPasteDetectedDocLinks(accessInfos: [Bool]) {
        self.onPasteDocsCallBack?(accessInfos)
    }

    var clientInfos: [String: String]? {
        return [
            "Docs": "0.2.5",
            "Core": "1.0.0"
        ]
    }
}

extension UIViewController {
    class func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }
}
