//
//  CalendarRichTextViewAPI.swift
//  LarkInterface
//
//  Created by 张威 on 2020/7/20.
//

import UIKit
import Foundation

public enum RichTextContentViewMenuType {
    case readOnly
    case readWrite
}

public protocol DocsRichTextViewDelegate: AnyObject {

    @discardableResult
    func richTextView(requireOpen url: URL) -> Bool

    func richTextViewJSContextDidReady()

    func richTextViewContentSizeDidChange(_ size: CGSize)

    func onPasteDetectedDocLinks(accessInfos: [Bool])
}

public extension DocsRichTextViewDelegate {
    func onPasteDetectedDocLinks(accessInfos: [Bool]) {}
}

public protocol DocsRichTextViewAPI {

    var view: UIView { get }

    var delegate: DocsRichTextViewDelegate? { get set }
    var disableBecomeFirstResponder: (() -> Bool)? { get set }
    var customHandle: ((URL, [String: Any]?) -> Void)? { get set }
    var openSelectTranslateHandler: ((String) -> Void)? { get set }

    func becomeFirstResponder()

    /**
     Load calendar js page.

     You should only calls it once, multiple invocations may produce unknown representations.
     */
    @discardableResult
    func loadCalendar() -> Bool

    /// 因WK进程被系统terminate，导致会清空已经注册的bridge callback回调，上层决定是否继续使用
    var bridgeInvalid: Bool { get }

    /**
     Start observing keyboard notification.

     RichTextEdtitor should observe keyboard notification to modify H5 page state (like scroll, offset logic).
     It will automaticlly start observing after initialized. For performance reasons, you can control
     it manually.

     Multiple invokes won't cause any problems.
     */
    func startObservingKeyboard()

    /**
     Stop observing keyboard notification.

     RichTextEdtitor should observe keyboard notification to modify H5 page state (like scroll, offset logic).
     It will automaticlly start observing after initialized. For performance reasons, you can control
     it manually.

     Multiple invokes won't cause any problems.
     */
    func stopObservingKeyboard()

    // sdk 1.0 接口
    func getDocData(completion: @escaping (String?, Error?) -> Void)
    func getDocHtml(completion: @escaping (String?, Error?) -> Void)
    func set(content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    func setDoc(data: String, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    /// 已经废弃，请使用setStyle:"
    // func setCustomizedStyle(_ style: String, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    /// 已经废弃，请使用setPlaceholder:"
    // func set(placeHolder: String, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    func checkKeep(completion: @escaping (Bool?, Error?) -> Void)

    // sdk 2.0 接口
    func setDomains(domainPool: [String], spaceApiDomain: String, mainDomain: String)
    func setStyle(_ style: DocsRichTextParam.AditStyle, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    func getContent(completion: @escaping (String?, Error?) -> Void)
    func getHtml(completion: @escaping (String?, Error?) -> Void)
    func render(_ content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    func getRect(completion: @escaping (String?, Error?) -> Void) // 2.0 only
    func clearContent(success: (() -> Void)?, fail: @escaping (Error) -> Void) // 2.0 only
    func getIsChanged(completion: @escaping (Bool?, Error?) -> Void)
    func setPlaceholder(_ props: DocsRichTextParam.PlaceholderProps, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    func setThemeConfig(_ config: ThemeConfig)

    // 版本无差别通用接口
    func setCanScroll(_ canScroll: Bool)
    func setTextMenu(type: RichTextContentViewMenuType)
    func getText(completion: @escaping (String?, Error?) -> Void)
    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void)
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)

}

public final class DocsRichTextParam {
    // 以下定义与前端SDK API同步，具体含义请咨询前端
    // API doc: https://bytedance.feishu.cn/space/doc/doccnKborZ42znZ3ox8oRpWrF3b

    public struct AditStyle: Encodable {
        public var heading: [String]?
        public var fontSize: String?       // number or string
        public var fontWeight: String?       // number or string
        public var fontFamily: String?
        public var textAlign: String?
        public var listMarginText: String?
        public var horizontalLRSpace: String?
        public var docBodyPadding: [String]?       // number or string
        public var innerHeight: String?       // number or string
        public var color: String?
        public var minHeight: String?       // number or string
        public var maxHeight: String?       // number or string
        public var background: String?
        public var isSysBold: Bool?
        public var linkColor: String?
        public var listMarkerColor: String?

        public init() { }
    }

    struct AditContent: Encodable {
        public var initialAttributedText: BaseAText?
        public var initialAttributedTexts: BaseZatext?
        public var apool: WireApool?
        public var style: AditStyle?

        public init() { }
    }

    public struct BaseAText: Encodable {
        public var attribs: String = ""
        public var text: String = ""

        public init() { }
    }

    public struct BaseZatext: Encodable {
        public var rows: [String: String]?
        public var cols: [String: String]?
        public var text: [String: String] = [:]
        public var attribs: [String: String] = [:]

        public init() { }
    }

    public struct WireApool: Encodable {
        public var numToAttrib: String = ""
        public var nextNum: String = ""

        public init() { }
    }

    public struct PlaceholderProps: Encodable {
        public var text: String?
        public var color: String?
        public var bold: Bool?
        public var italic: Bool?
        public var fontSize: String?
        public var fontFamily: String?
        public var underline: Bool?
        public var strikeThrough: Bool?
        public var backgroundColor: String?
        public var opacity: String?
        public var lineHeight: String?
        public var hiddenWhileFocusing: Bool?

        public init() { }
    }
}
