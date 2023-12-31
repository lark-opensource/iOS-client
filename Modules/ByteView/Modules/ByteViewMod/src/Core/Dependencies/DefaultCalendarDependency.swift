//
//  DefaultCalendarDependency.swift
//  LarkByteView
//
//  Created by kiri on 2021/6/28.
//

import Foundation
import ByteView

final class DefaultCalendarDependency: CalendarDependency {
    func formatDateTimeRange(startTime: TimeInterval, endTime: TimeInterval, isAllDay: Bool) -> String {
        DefaultDateUtil.formatCalendarDateTimeRange(startTime: startTime, endTime: endTime)
    }

    /// 显示日历详情简介
    func createDocsView() -> CalendarDocsViewHolder {
        DefaultCalendarDocsView()
    }
}

private class DefaultCalendarDocsView: CalendarDocsViewHolder {
    private lazy var label = UILabel()
    weak var delegate: CalendarDocsViewDelegate?
    var customHandle: ((URL, [String: Any]?) -> Void)?

    private lazy var docsView: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return view
    }()

    func getDocsView(_ autoUpdateHeight: Bool, shouldJumpToWebPage: Bool) -> UIView {
        return docsView
    }

    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        success?()
    }

    func setDoc(data: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        self.label.text = data
        success?()
    }

    func setThemeConfig(backgroundColor: UIColor, foregroundFontColor: UIColor, linkColor: UIColor, listMarkerColor: UIColor) {}
}
