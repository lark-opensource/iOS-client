//
//  MeetingNotesPermissionView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/9/22.
//

import Foundation
import LarkUIKit
import LKRichView
import SnapKit

enum MeetingNotesTag: Int8, LKRichElementTag {
    case clickable
    case normal

    public var typeID: Int8 {
        return rawValue
    }
}

/// 尾部可点击 View，当 clickView 无法一行显示下时，会自动整体换行至Prompt下一行
///
///     +--------------------------------------------------------------+
///     |          |                                   |               |
///     |-- Icon --|------------- Prompt --------------|- Click  View -|
///     |          |   (Click View)                    |   (可整体换行)  |
///     +--------------------------------------------------------------+
///

class TrailClickableView: UIView {

    fileprivate typealias Tag = MeetingNotesTag

    struct UIConfig {
        var text: String = ""
        var style: LKRichStyle = .init()
    }

    lazy var iconImageView: UIImageView = UIImageView(image: nil)

    let trailClickableLabel: LKRichView

    var clickAction: (() -> Void)?

    init() {
        trailClickableLabel = LKRichView(frame: .zero, options: ConfigOptions([.debug(true)]))
        trailClickableLabel.bindEvent(selectors: [CSSSelector(value: Tag.clickable)], isPropagation: true)
        super.init(frame: .zero)
        trailClickableLabel.delegate = self
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isUserInteractionEnabled = true
        addSubview(iconImageView)
        addSubview(trailClickableLabel)

        trailClickableLabel.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.leading).offset(6)
        }

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.leading.equalToSuperview()
            make.size.equalTo(16)
        }
    }

    func updateContent(icon: UIImage? = nil, promptConfig: UIConfig, trailView: UIView, trailViewSize: CGSize) {
        setNeedsLayout()
        layoutIfNeeded()
        let promptLabel = LKTextElement(text: promptConfig.text)
        let promptInlineElement = LKInlineElement(tagName: Tag.normal).style(promptConfig.style).children([promptLabel])

        let attachment = LKAsyncRichAttachmentImp(
            size: trailViewSize,
            viewProvider: { trailView },
            verticalAlign: .middle)
        let attachmentInlineBlockElement = LKInlineBlockElement(tagName: Tag.clickable).children([LKAttachmentElement(attachment: attachment)])

        /// 控制单行展示时，文本垂直居中，高度等于 lineHeight
        let empty = LKInlineBlockElement(tagName: Tag.normal).style(.init().minHeight(promptConfig.style.lineHeight).width(.point(0)))

        let documentElement = LKInlineElement(tagName: Tag.normal)
            .children([empty, promptInlineElement, attachmentInlineBlockElement])
            .style(.init().verticalAlign(.middle))
        let core = LKRichViewCore()
        let renderer = core.createRenderer(documentElement)
        core.load(renderer: renderer)
        trailClickableLabel.setRichViewCore(core)
        trailClickableLabel.documentElement = documentElement

        iconImageView.isHidden = icon == nil
        if let icon = icon {
            iconImageView.image = icon
        }

        trailClickableLabel.snp.remakeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            if icon == nil {
                make.leading.equalTo(iconImageView)
            } else {
                make.leading.equalTo(iconImageView.snp.trailing).offset(6)
            }
        }
    }
}

extension TrailClickableView: LKRichViewDelegate {
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {

    }

    func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        nil
    }

    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {

    }

    func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        clickAction?()
    }

    func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

}
