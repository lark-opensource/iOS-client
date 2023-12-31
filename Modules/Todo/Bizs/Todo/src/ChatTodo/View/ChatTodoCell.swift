//
//  ChatTodoCell.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/25.
//

import Foundation
import UniverseDesignFont

protocol ChatTodoCellActionDelegate: AnyObject {
    func disabledAction(for checkbox: Checkbox, from sender: ChatTodoCell) -> CheckboxDisabledAction
    func enabledAction(for checkbox: Checkbox, from sender: ChatTodoCell) -> CheckboxEnabledAction
    func didTapDetail(from sender: ChatTodoCell)
    func didTapSender(from sender: ChatTodoCell)
}

extension ChatTodoCellData {

    func preferredHeight(maxWidth: CGFloat) -> CGFloat {
        guard let contentData = contentData else {
            return .leastNormalMagnitude
        }
        return contentData.preferredHeight(maxWidth: maxWidth) + ChatTodoCell.actionViewHeight
    }

}

final class ChatTodoCell: UICollectionViewCell {

    static let actionViewHeight: CGFloat = 36.0

    weak var actionDelegate: ChatTodoCellActionDelegate?

    var viewData: ChatTodoCellData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            subView.viewData = viewData.contentData
            actionView.updateTitle(viewData.senderTitle)
            setNeedsLayout()
        }
    }

    /// 分割线
    var showSeparateLine: Bool = true {
        didSet {
            separateLine.isHidden = !showSeparateLine
        }
    }

    private lazy var subView = V3ListContentView()
    private lazy var actionView = ActionView()

    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(subView)
        contentView.addSubview(actionView)
        contentView.addSubview(separateLine)
        let detailTap = UITapGestureRecognizer(target: self, action: #selector(handleDetailClick))
        // 如果 Checkbox 的 superView 有添加 gesture，需要实现该 gesture 的 delegate 中的
        // gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        // 来放开 gesture 对 subView 中的 touch 事件的屏蔽
        detailTap.delegate = self
        contentView.addGestureRecognizer(detailTap)
        let actionTap = UITapGestureRecognizer(target: self, action: #selector(handleSenderClick))
        actionView.addGestureRecognizer(actionTap)
        subView.checkbox.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleDetailClick() {
        actionDelegate?.didTapDetail(from: self)
    }

    @objc
    private func handleSenderClick() {
        actionDelegate?.didTapSender(from: self)
    }

    private let greatestSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

    override func layoutSubviews() {
        super.layoutSubviews()
        subView.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: bounds.height - ChatTodoCell.actionViewHeight
        )
        let left = ListConfig.Cell.leftPadding + ListConfig.Cell.checkBoxSize.width + ListConfig.Cell.horizontalSpace
        actionView.frame = CGRect(
            x: left,
            y: subView.frame.bottom,
            width: bounds.width - left,
            height: ChatTodoCell.actionViewHeight
        )

        if !separateLine.isHidden {
            let lineHeight = CGFloat(1.0 / UIScreen.main.scale)
            separateLine.frame = CGRect(
                x: left,
                y: bounds.height - lineHeight,
                width: bounds.width - left,
                height: lineHeight
            )
        }
    }

}

extension ChatTodoCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view, view.isKind(of: UIControl.self) {
            return false
        }
        return true
    }
}

extension ChatTodoCell: CheckboxDelegate {

    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction {
        return actionDelegate?.disabledAction(for: checkbox, from: self) ?? {}
    }

    func enabledAction(for checkbox: Checkbox) -> CheckboxEnabledAction {
        return actionDelegate?.enabledAction(for: checkbox, from: self) ?? .immediate {}
    }

}

private final class ActionView: UIView {

    private let separateLine = UIView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(separateLine)
        addSubview(titleLabel)
        separateLine.backgroundColor = UIColor.ud.lineDividerDefault
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.font = UDFont.systemFont(ofSize: 12)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separateLine.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width - ListConfig.Cell.rightPadding,
            height: CGFloat(1.0 / UIScreen.main.scale)
        )
        titleLabel.frame = CGRect(
            x: 0,
            y: (bounds.height - 20) * 0.5,
            width: bounds.width - ListConfig.Cell.rightPadding,
            height: 20
        )
    }

    func updateTitle(_ title: String?) {
        titleLabel.text = title
    }

}
