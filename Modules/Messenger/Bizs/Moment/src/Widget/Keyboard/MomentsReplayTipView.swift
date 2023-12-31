//
//  MomentsReplayTipView.swift
//  Moment
//
//  Created by bytedance on 2021/1/12.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import RichLabel

final class MomentsReplayTipView: UIView {

    var replyText: NSAttributedString? {
        get {
            return self.textLabel.attributedText
        }
        set {
            self.textLabel.attributedText = newValue
        }
    }
    var closeButton: UIButton!
    var textLabel: LKLabel = .init()
    var contentView: UIView = UIView()
    let closeCallBack: (() -> Void)?

    init(closeCallBack: (() -> Void)? = nil) {
        self.closeCallBack = closeCallBack
        super.init(frame: .zero)
        self.layer.masksToBounds = true

        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 4
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(Cons.contentInset)
            maker.top.bottom.equalToSuperview().inset(0)
            maker.height.equalTo(0)
        }
        // 关闭回复按钮
        closeButton = self.buildButton(normalImage: Resources.replyClose, selectedImage: Resources.replyClose)
        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.size.equalTo(Cons.buttonSize)
            make.left.centerY.equalToSuperview()
        }
        closeButton.addTarget(self, action: #selector(closeTipView), for: .touchUpInside)

        // 分割线
        let split = UIView()
        split.backgroundColor = UIColor.ud.commonTableSeparatorColor
        contentView.addSubview(split)
        split.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 1 / UIScreen.main.scale, height: Cons.separatorHeight))
            make.right.equalTo(closeButton.snp.right).offset(2)
            make.centerY.equalToSuperview()
        }

        // 回复label
        let fontColor = UIColor.ud.N500
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
        textLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 100
        contentView.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(split.snp.right).offset(10)
            make.right.equalTo(-8)
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

    func show(_ show: Bool) {
        if show {
            contentView.snp.updateConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(Cons.contentInset)
                make.height.equalTo(Cons.contentHeight)
            }
        } else {
            contentView.snp.updateConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(0)
                make.height.equalTo(0)
            }
        }
    }

    @objc
    private func closeTipView() {
        self.closeCallBack?()
    }

}

fileprivate extension MomentsReplayTipView {

    enum Cons {
        static var textFont: UIFont { UIFont.systemFont(ofSize: 14) }
        static var contentInset: CGFloat { 7 }
        static var contentHeight: CGFloat { 30 }
        static var separatorHeight: CGFloat { 14 }
        static var buttonSize: CGSize { CGSize(width: 32, height: 32) }
    }

}
