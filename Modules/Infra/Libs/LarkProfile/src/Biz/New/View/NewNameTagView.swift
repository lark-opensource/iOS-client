//
//  NewNameTagView.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/26.
//

import Foundation
import UIKit

final class NewNameTagView: NameTagView {

    private var name: String?
    func update(name: String, tagViews: [UIView]) {
        copyName = name
        var tagName = name
        if self.name != tagName {
            /// 处理含有特殊字符时计算字符位置不准问题
            if ProfileProcessStringUtil.hasSpecialCharacters(tagName) {
                tagName += " "
            }
            attributedName = NSAttributedString(
                string: tagName,
                attributes: [.font: Cons.nameFont]
            )
            nameLabel.text = tagName
            nameLabel.lineBreakMode = .byTruncatingTail
        }
        self.name = tagName
        
        hasTag = !tagViews.isEmpty
        userTagView.arrangedSubviews.forEach {
            userTagView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for tag in tagViews {
            userTagView.addArrangedSubview(tag)
        }
        self.adjustUserTagsIfNeeded(self.bounds.width)
    }
    
    override func adjustUserTagsIfNeeded(_ maxWidth: CGFloat) {
        guard let text = attributedName else { return }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            var hMargin: CGFloat = 8
            if ProfileProcessStringUtil.hasSpecialCharacters(self.attributedName?.string ?? ""), ProfileProcessStringUtil.isToProcessLanguage() {
                /// 处理特殊语言下添加额外margin
                hMargin = 20
            } else if ProfileProcessStringUtil.isChinese(),
                        ProfileProcessStringUtil.countBracketsMoreThanApair(self.attributedName?.string ?? ""),
                        let margin = ProfileProcessStringUtil.getSpecialTypeNameTagReplenishHMargin() {
                hMargin = margin
            }
            let labelEnd = self.lastLineWidth(message: text, labelWidth: maxWidth) + hMargin
            DispatchQueue.main.async {
                let availableWidth = maxWidth - labelEnd
                if availableWidth >= self.userTagView.frame.width {
                    self.nameLabel.addSubview(self.userTagView)
                    self.userTagView.snp.remakeConstraints { make in
                        make.bottom.equalToSuperview().offset(-(Cons.nameFont.lineHeight - Cons.tagViewHeight) / 2)
                        make.leading.equalToSuperview().offset(labelEnd)
                        make.height.equalTo(self.hasTag ? Cons.tagViewHeight : 0)
                    }
                } else {
                    self.addArrangedSubview(self.userTagView)
                    self.userTagView.snp.remakeConstraints { make in
                        make.width.lessThanOrEqualToSuperview()
                        make.height.equalTo(self.hasTag ? Cons.tagViewHeight : 0)
                    }
                }
            }
        }
        
    }
}
