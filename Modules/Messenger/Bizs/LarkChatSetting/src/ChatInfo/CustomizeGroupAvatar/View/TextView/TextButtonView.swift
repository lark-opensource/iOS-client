//
//  TextButtonView.swift
//  LarkChatSetting
//
//  Created by 李勇 on 2020/4/22.
//

import UIKit
import Foundation

/// 推荐文字区域代理事件，由外部去处理点击事件，内部只做展示
protocol TextButtonDelegate: AnyObject {
    func buttonDidSelect(button: UIButton)
}

/// 推荐文字区域，height = 12 + buttons高度 + 12，buttons距离上下12
final class TextButtonView: UIView {
    weak var delegate: TextButtonDelegate?

    static let buttonBeginTag = 500
    private(set) var buttonArray = [UIButton]()
    /// 用户当前选中颜色按钮的tag，值为-1表示未选中任何项
    var selectButtonTag = -1

    func layoutTheButton(textArray: [String]) {
        // 清空标记位
        self.subviews.forEach({ $0.removeFromSuperview() })
        self.buttonArray = []
        self.selectButtonTag = -1

        // 没有内容
        guard !textArray.isEmpty else {
            // 高度设置为0
            self.snp.makeConstraints { $0.height.equalTo(0) }
            return
        }

        var row = 0
        var currButtonOffset = CGFloat(16)
        for (index, item) in textArray.enumerated() {
            let nameButton = UIButton()
            nameButton.setTitle(item, for: .normal)
            nameButton.setTitleColor(UIColor.ud.N900, for: .normal)
            nameButton.tag = TextButtonView.buttonBeginTag + index
            nameButton.layer.masksToBounds = true
            nameButton.layer.cornerRadius = 16
            nameButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            nameButton.titleLabel?.lineBreakMode = .byTruncatingTail
            // button文字距离左右边距为18.5
            nameButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 18.5 / 2, bottom: 0, right: 18.5 / 2)
            nameButton.backgroundColor = UIColor.ud.N200
            nameButton.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
            self.addSubview(nameButton)
            // 当前按钮应该展示多宽，每个button最长不超过UIScreen.main.bounds.width - 32，fix：服务端数据返回异常导致显示超出边界
            var buttonWidth = item.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]).width + 37
            buttonWidth = min(buttonWidth, UIScreen.main.bounds.width - 32)
            if currButtonOffset + buttonWidth + CGFloat(16) > UIScreen.main.bounds.width {
                row += 1
                currButtonOffset = 16
                // 最多显示两行
                if row == 2 { break }
            }
            // 两行button间距为12
            nameButton.frame = CGRect(x: currButtonOffset, y: CGFloat(12 + (32 + 12) * row), width: buttonWidth, height: CGFloat(32))
            buttonArray.append(nameButton)
            currButtonOffset += buttonWidth + 8
        }
        // 撑开自身高度
        let lastButtonFrame = buttonArray.last?.frame ?? .zero
        self.snp.makeConstraints { $0.height.equalTo(lastButtonFrame.maxY) }
    }

    /// 让指定tag的按钮处于选中态
    func setButtonSelected(tag: Int) {
        let index = tag - TextButtonView.buttonBeginTag
        setButtonSelected(button: buttonArray[index])
    }

    /// 让指定tag的按钮处于非选中态
    func setButtonNormal(tag: Int) {
        let index = tag - TextButtonView.buttonBeginTag
        setButtonNormal(button: buttonArray[index])
    }

    /// 让按钮处于选中态
    func setButtonSelected(button: UIButton) {
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.colorfulBlue
    }

    /// 让按钮处于非选中态
    func setButtonNormal(button: UIButton) {
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        button.backgroundColor = UIColor.ud.N200
    }

    @objc
    private func buttonClick(button: UIButton) {
        self.delegate?.buttonDidSelect(button: button)
    }
}
