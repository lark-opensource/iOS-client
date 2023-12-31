//
//  DocsProtocol.swift
//  Calendar
//
//  Created by jiayi zou on 2018/10/10.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LKCommonsLogging
import CalendarRichTextEditor

public protocol DocsViewHolder {
    var customHandle: ((_ url: URL, _ docInfo: [String: Any]?) -> Void)? { get set }
    var openSelectTranslateHandler: ((_ selectText: String) -> Void)? { get set }
    var disableBecomeFirstResponder: (() -> Bool)? { get set }
    var onPasteDocsCallBack: ((_ accessInfos: [Bool]) -> Void )? { get set }

    func logger() -> Log

    /// set should auto update the height of docs
    ///
    /// - Parameter autoUpdateHeight: should auto update the height of docsView
    ///             shouldJumpToWebPage: should go to thw url
    /// - Returns: the docsView
    func getDocsView(_ autoUpdateHeight: Bool, shouldJumpToWebPage: Bool) -> UIView

    /// load docsview for calendar
    ///
    /// - Parameter callback: after the call back success(asnyc), the callback will be triggered
    /// - Returns: after load request send to sdk(snyc), if the request have no syntax error, return true, else false
    //    @discardableResult
    //    func loadCalendar(callback: @escaping () -> Void) -> Bool

    /// set style of docs view
    ///
    /// - Parameters:
    ///   - style: DocsEditStyle, the same struct as AditStyle in docsSDK 2.0
    ///   - success: success call back
    ///   - fail: failed call back
    func setStyle(_ style: DocsEditStyle, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// set placeHolder of the docs view
    ///
    /// - Parameters:
    ///   - placeHolder: the string to display
    ///   - success: success call back
    ///   - fail: error call back
    func set(placeHolder: String, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// set the editable status of docs view
    ///
    /// - Parameters:
    ///   - enable: is editable
    ///   - success: success call back
    ///   - fail: error call back
    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// get content of docs view in HTML format
    ///
    /// - Parameter complete: success call back
    func getDocHtml(complete: @escaping (String?, Error?) -> Void)

    /// set the content of docs view in HTML format
    ///
    /// - Parameters:
    ///   - html: HTML format string
    ///   - success: success call back
    ///   - fail: error call back
    func setDoc(html: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// get content of docs view in DOCS format
    ///
    /// - Parameter complete: success call back
    /// - Returns: nil
    func getDocData(complete: @escaping (String?, Error?) -> Void)

    /// set content of docs view in DOCS format
    ///
    /// - Parameters:
    ///   - data: DOCS format string
    ///   - success: success call back
    ///   - fail: on error call back
    func setDoc(data: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// get content of DOCS view in pain text
    ///
    /// - Parameter complete: success call back
    func getPainText(complete: @escaping (String?, Error?) -> Void)

    /// check if the content had been changed
    ///
    /// - Parameter complete: (is the content not changed, error)
    func isNotChanged(complete: @escaping (Bool?, Error?) -> Void)

    /// set the color of text in RGB format
    ///
    /// - Parameters:
    ///   - red: red value
    ///   - green: green value
    ///   - blue: blue value
    ///   - success: success callback
    ///   - fail: failure callback
    func setColor(_ red: Int, _ green: Int, _ blue: Int, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    func setThemeConfig(_ config: ThemeConfig)

    func becomeFirstResponder()
}

public struct DocsEditStyle {
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
       // 系统粗体模式
       public var isSysBold: Bool?

       public init() { }
}
