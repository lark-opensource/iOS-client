//
//  ActivityRecordContentCell.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/29.
//

import Foundation
import UniverseDesignColor
import LKRichView
import LarkRichTextCore

protocol ActivityRecordContentCellDelegate: AnyObject {
    func didTapUser(with userId: String, from cell: ActivityRecordContentCell)
    func didTapUrl(with url: String, from cell: ActivityRecordContentCell)
    func didTapGridImage(index: Int, images: [Rust.ImageSet], sourceView: UIImageView, from cell: ActivityRecordContentCell)
    func didTapAttachment(with fileToken: String, from cell: ActivityRecordContentCell)
    func didExpandAttachment(from cell: ActivityRecordContentCell)
    func didExpandContent(from cell: ActivityRecordContentCell)
}

final class ActivityRecordContentCell: UICollectionViewCell {

    weak var delegate: ActivityRecordContentCellDelegate?

    var viewData: ActivityRecordContentData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            subView.viewData = viewData
        }
    }

    /// 分割线
    var showSeparateLine: Bool = false {
        didSet {
            separateLine.isHidden = !showSeparateLine
        }
    }

    private weak var targetElement: LKRichElement?
    private lazy var subView = ActivityRecordContentView()

    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(subView)
        addSubview(separateLine)
        bingViewAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subView.frame = bounds
        let lintHeight = CGFloat(1.0 / UIScreen.main.scale)
        separateLine.frame = CGRect(
            x: 0,
            y: frame.height - lintHeight,
            width: frame.width,
            height: lintHeight
        )
    }
}

extension ActivityRecordContentCell: DetailAttachmentContentCellDelegate, LKRichViewDelegate {

    private func bingViewAction() {
        subView.user.onTap = { [weak self] userId in
            guard let self = self else { return }
            self.delegate?.didTapUser(with: userId, from: self)
        }

        subView.middle.gridImage.onItemTap = { [weak self] (index, sourceView) in
            guard let self = self, let imageData = self.viewData?.content.images else { return }
            self.delegate?.didTapGridImage(
                index: index,
                images: imageData.images,
                sourceView: sourceView,
                from: self
            )
        }

        subView.middle.attachment.actionDelegate = self
        subView.middle.attachment.footerView.expandMoreClickHandler = { [weak self] in
            guard let self = self else { return }
            self.delegate?.didExpandAttachment(from: self)
        }

        subView.middle.text.title.delegate = self
        subView.middle.text.content.delegate = self

        subView.showMore.onShowTap = { [weak self] in
            guard let self = self else { return }
            self.delegate?.didExpandContent(from: self)
        }

    }

    // attachment
    func onClick(_ cell: DetailAttachmentContentCell) {
        guard let fileToken = cell.viewData?.fileToken,
              !fileToken.isEmpty else {
            return
        }
        delegate?.didTapAttachment(with: fileToken, from: self)
    }

    func onRetryBtnClick(_ cell: DetailAttachmentContentCell) { }

    func onDeleteBtnClick(_ cell: DetailAttachmentContentCell) { }

    // richView
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {}

    func getTiledCache(_ view: LKRichView) -> LKTiledCache? { return nil }

    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {}

    func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard let event = event else {
            targetElement = nil
            return
        }
        if targetElement !== event.source { targetElement = nil }
    }

    func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }
        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID:
            needPropagation = handleTagAtEvent(element: element, event: event, view: view)
        case RichViewAdaptor.Tag.a.typeID:
            needPropagation = handleTagAEvent(element: element, event: event)
        default: break
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    /// Return - 事件是否需要继续冒泡
    private func handleTagAtEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        guard !element.id.isEmpty else { return true }
        var userId: String?
        if view == subView.middle.text.title {
            // title的数据是自己构造的，复用了elementId，为空的时候是群组
            userId = element.id
        } else if view == subView.middle.text.content {
            userId = viewData?.content.text.contentAtElements?[element.id]
        } else {
            userId = nil
        }
        if let userId = userId {
            delegate?.didTapUser(with: userId, from: self)
            return false
        }
        return true
    }

    /// Return - 事件是否需要继续冒泡
    private func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if let href = anchor.href {
            delegate?.didTapUrl(with: href, from: self)
            return false
        }
        return true
    }

}
