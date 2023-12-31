//
//  CalendarDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/26.
//

import Foundation

/// 日历相关依赖
public protocol CalendarDependency {

    /// 格式化日程时间
    /// - parameter startTime: 日程开始时间，timeIntervalSince1970
    /// - parameter endTime: 日程结束时间，timeIntervalSince1970
    /// - parameter isAllDay: 是不是一个全天的日程
    func formatDateTimeRange(startTime: TimeInterval, endTime: TimeInterval, isAllDay: Bool) -> String

    /// 显示日历详情简介
    func createDocsView() -> CalendarDocsViewHolder
}

/// 日程详情页
public protocol CalendarDocsViewHolder {
    var delegate: CalendarDocsViewDelegate? { get set }
    var customHandle: ((_ url: URL, _ docInfo: [String: Any]?) -> Void)? { get set }

    /// set should auto update the height of docs
    ///
    /// - Parameter autoUpdateHeight: should auto update the height of docsView
    ///             shouldJumpToWebPage: should go to thw url
    /// - Returns: the docsView
    func getDocsView(_ autoUpdateHeight: Bool, shouldJumpToWebPage: Bool) -> UIView

    /// set the editable status of docs view
    ///
    /// - Parameters:
    ///   - enable: is editable
    ///   - success: success call back
    ///   - fail: error call back
    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// set content of docs view in DOCS format
    ///
    /// - Parameters:
    ///   - data: DOCS format string
    ///   - success: success call back
    ///   - fail: on error call back
    func setDoc(data: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void)

    /// set theme config of docs view in DOCS format
    ///
    /// - Parameters:
    ///   - backgroundColor: DOCS backgroundColor
    ///   - foregroundFontColor: DOCS foregroundFontColor
    func setThemeConfig(backgroundColor: UIColor, foregroundFontColor: UIColor, linkColor: UIColor, listMarkerColor: UIColor)
}

/// 日程详情页回调
public protocol CalendarDocsViewDelegate: AnyObject {
    func docsView(requireOpen url: URL)
}
