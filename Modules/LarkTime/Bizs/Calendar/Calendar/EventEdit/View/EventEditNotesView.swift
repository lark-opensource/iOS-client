//
//  EventEditNotesView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UniverseDesignIcon
import UIKit
import SnapKit
import CalendarFoundation
import LarkContainer
import CalendarRichTextEditor
import UniverseDesignColor

protocol EventEditNotesViewDataType {
    var notes: EventNotes { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
    var isDeletable: Bool { get }
}

final class EventEditNotesView: EventEditCellLikeView, ViewDataConvertible {

    var clickHandler: (() -> Void)? {
        didSet { onClick = clickHandler }
    }

    var deleteHandler: (() -> Void)? {
        didSet { onAccessoryClick = deleteHandler }
    }

    private typealias RGBComponents = (red: CGFloat, green: CGFloat, blue: CGFloat)

    private var normalColorValues: (red: Int, green: Int, blue: Int) {
        var color: RGBComponents = (0, 0, 0)
        UIColor.ud.textTitle.getRed(&color.red, green: &color.green, blue: &color.blue, alpha: nil)
        return (Int(color.red * 255.0), Int(color.green * 255.0), Int(color.blue * 255.0))
    }

    private var disableColorValues: (red: Int, green: Int, blue: Int) {
        var color: RGBComponents = (0, 0, 0)
        UIColor.ud.textDisable.getRed(&color.red, green: &color.green, blue: &color.blue, alpha: nil)
        return (Int(color.red * 255.0), Int(color.green * 255.0), Int(color.blue * 255.0))
    }

    var viewData: EventEditNotesViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            if let oldValue = oldValue,
               oldValue.isVisible == viewData.isVisible,
               oldValue.isEditable == viewData.isEditable,
               oldValue.isDeletable == viewData.isDeletable,
               oldValue.notes == viewData.notes {
                return
            }
            updateViewsIfNeeded()
        }
    }

    var docsViewHolder: DocsViewHolder
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.slideOutlined).withRenderingMode(.alwaysOriginal)
    private lazy var iconImageDisabled = UDIcon.getIconByKeyNoLimitSize(.slideOutlined).withRenderingMode(.alwaysOriginal).renderColor(with: .n4)

    let docsViewContainerView = UIView()

    private var docsView: UIView = UIView()
    // 容器的背景色和webview的背景色
    private var bgColor: UIColor?

    init(frame: CGRect, bgColor: UIColor? = nil, docsViewHolder: DocsViewHolder) {
        self.docsViewHolder = docsViewHolder
        super.init(frame: frame)
        if let bgColor = bgColor {
            backgroundColors = (bgColor, bgColor)
            self.bgColor = bgColor
        }

        self.docsViewHolder.setEditable(
            false,
            success: nil,
            fail: { [weak self] error in
                self?.docsViewHolder.logger()
                    .error("set setEditable", error: error)
                assertionFailureLog()
            }
        )

        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        icon = .customImage(iconImage)

        content = .customView(docsViewContainerView)

        docsView = docsViewHolder.getDocsView(true, shouldJumpToWebPage: true)
        self.docsViewHolder.disableBecomeFirstResponder = { return true }
        docsView.isUserInteractionEnabled = false

        docsViewContainerView.addSubview(docsView)
        docsView.snp.remakeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(14)
            $0.bottom.lessThanOrEqualToSuperview().offset(-5)
        }
        iconAlignment = .topByOffset(15)
    }

    override var frame: CGRect {
        didSet {
            if abs(oldValue.width - frame.width) > 0.00001 {
                updateViewsIfNeeded()
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            if abs(oldValue.width - bounds.width) > 0.00001 {
                updateViewsIfNeeded()
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateViewsIfNeeded()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateViewsIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateViewsIfNeeded() {
        guard window != nil else { return }

        guard let viewData = viewData else {
            isHidden = true
            return
        }

        isHidden = !viewData.isVisible

        var docsWidth = frame.width
        docsWidth -= (Style.leftInset + Style.iconSize.width + Style.spacingAfterIcon)
        docsWidth -= (Style.rightInset + Style.accessorySize.width + Style.spacingBeforeAccessory)

        guard docsWidth > 0 else { return }

        let themeConfig = ThemeConfig(backgroundColor: bgColor ?? UDColor.bgBody,
                                      foregroundFontColor: UDColor.textTitle,
                                      linkColor: UIColor.ud.textLinkNormal,
                                      listMarkerColor: UIColor.ud.primaryContentDefault)
        docsViewHolder.setThemeConfig(themeConfig)

        switch viewData.notes {
        case .html(let text), .plain(let text):
            docsViewHolder.setDoc(
                html: text,
                displayWidth: docsWidth,
                success: nil,
                fail: { [weak self] error in
                    self?.docsViewHolder.logger()
                        .error("set htmlOrText failed", error: error)
                    assertionFailureLog()
                }
            )
        case .docs(let data, let text):
            docsViewHolder.setDoc(
                data: data.isEmpty ? text : data,
                displayWidth: docsWidth,
                success: nil,
                fail: { [weak self] error in
                    self?.docsViewHolder.logger()
                        .error("set data failed", error: error)
                    assertionFailureLog()
                }
            )
        }

        accessory = .none
        isUserInteractionEnabled = viewData.isEditable
        icon = viewData.isEditable ? .customImage(iconImage) : .customImageWithoutN3(iconImageDisabled)

        if viewData.notes.isEmpty {
            content = .title(ContentTitle(text: BundleI18n.Calendar.Calendar_Edit_PCAddDescription, color: EventEditUIStyle.Color.dynamicGrayText))
            iconAlignment = .centerVertically
        } else {
            content = .customView(docsViewContainerView)
            iconAlignment = .topByOffset(17)
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

}
