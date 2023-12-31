//
//  RelatedMessageTipsView.swift
//  Pods
//
//  Created by lichen on 2018/8/13.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import RichLabel

//输入框上方展示关联消息的那个条；比如会用来展示被回复的消息、被二次编辑消息的parentMassage等

final class RelatedMessageTipsView: UIView {

    private let space: CGFloat = 10
    private let textLabelRightMargin: CGFloat = 8
    private var preferredMaxLayoutWidth: CGFloat {
        return self.frame.width - Cons.contentInset - (2 * space + 1) - Cons.buttonSize.width - textLabelRightMargin
    }
    override var bounds: CGRect {
        didSet {
            self.textLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        }
    }

    var tipsContent: NSAttributedString? {
        get {
            return self.textLabel.attributedText
        }
        set {
            self.textLabel.attributedText = newValue
        }
    }

    var currentHeight: CGFloat = 0
    var showContentInset: Bool = true
    var closeButton: UIButton!
    lazy var closeButtonAndSplitContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    var textLabel: LKLabel = .init()
    var contentView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.masksToBounds = true

        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 2
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(Cons.contentInset)
            maker.top.bottom.equalToSuperview().inset(0)
            maker.height.equalTo(0)
        }
        contentView.addSubview(closeButtonAndSplitContainer)
        closeButtonAndSplitContainer.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        // 关闭回复按钮
        closeButton = self.buildButton(normalImage: Resources.reply_close, selectedImage: Resources.reply_close)
        closeButtonAndSplitContainer.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.size.equalTo(Cons.buttonSize)
            make.left.centerY.equalToSuperview()
        }

        // 分割线
        let split = UIView()
        split.backgroundColor = UIColor.ud.lineDividerDefault
        closeButtonAndSplitContainer.addSubview(split)
        split.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 1, height: Cons.separatorHeight))
            make.left.equalTo(closeButton.snp.right).offset(space)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        // 回复label
        let fontColor = UIColor.ud.textPlaceholder
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: fontColor,
            .font: Cons.textFont
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        textLabel = LKLabel(frame: .zero).lu.setProps(
            fontSize: Cons.textFont.pointSize,
            numberOfLine: 1,
            textColor: fontColor
        )
        textLabel.autoDetectLinks = false
        textLabel.outOfRangeText = outOfRangeText
        textLabel.backgroundColor = UIColor.clear
        /// 这里粗暴的使用UIScreen.main.bounds.width - 100 会导iPad上的文字截断
        contentView.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(closeButtonAndSplitContainer.snp.right).offset(space)
            make.right.equalTo(-textLabelRightMargin)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func buildButton(normalImage: UIImage, selectedImage: UIImage) -> UIButton {
        let button = UIButton()
        button.setImage(normalImage, for: .normal)
        button.setImage(selectedImage, for: .selected)
        button.setImage(selectedImage, for: .highlighted)
        return button
    }

    func show(_ show: Bool, showCloseButton: Bool) {
        var contentInset: CGFloat = 0
        if show {
            contentInset = self.showContentInset ? Cons.contentInset : 0
            contentView.snp.updateConstraints { (make) in
                make.top.equalToSuperview().inset(contentInset)
                make.height.equalTo(Cons.contentHeight)
            }
            if showCloseButton {
                closeButtonAndSplitContainer.snp.remakeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                }
            } else {
                closeButtonAndSplitContainer.snp.remakeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                    make.width.equalTo(0).priority(.required)
                }
            }
        } else {
            contentView.snp.updateConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(0)
                make.height.equalTo(0)
            }
        }
        currentHeight = show ? (Cons.contentHeight + contentInset) : 0
    }
}

/// Define constants here

extension RelatedMessageTipsView {

    enum Cons {
        static var textFont: UIFont { UIFont.ud.body2 }
        static var contentInset: CGFloat { 8 }
        static var contentHeight: CGFloat { textFont.pointSize + 16 }
        static var separatorHeight: CGFloat { textFont.rowHeight }
        static var buttonSize: CGSize { .square(16) }
    }

}
