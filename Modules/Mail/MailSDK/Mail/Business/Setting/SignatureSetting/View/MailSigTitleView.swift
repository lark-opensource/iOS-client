//
//  MailSigTitleView.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/11/5.
//

import Foundation
import LarkTag

class MailSigTitleView: UITextView {
    var title: String?
    var tagTitle: String?
    var needLock: Bool = false
    let lineNum: Int = 2
    let tagSpace: CGFloat = 4
    let lockWidth: CGFloat = 18
    let titleFontSize: CGFloat = 16
    private var titleHeight: CGFloat = 0

    lazy var tagLabel: PaddingUILabel = {
        let tag = PaddingUILabel()
        tag.color = UIColor.ud.udtokenTagBgBlue
        tag.paddingLeft = 4
        tag.paddingRight = 4
        tag.paddingTop = 2
        tag.paddingBottom = 2
        tag.layer.cornerRadius = 4
        tag.clipsToBounds = true
        tag.textColor = UIColor.ud.udtokenTagTextSBlue
        tag.textAlignment = .center
        tag.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        return tag
    }()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.isScrollEnabled = false
        self.isEditable = false
        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func configView(title: String, tagTitle: String?, needLock: Bool, totalWidth: CGFloat) {
        self.title = title
        self.tagTitle = tagTitle
        self.needLock = needLock
        let totalWidth = totalWidth - 32
        if let tagStr = tagTitle {
            self.tagLabel.text = tagStr
            self.tagLabel.sizeToFit()
            let size = self.tagLabel.bounds
            self.tagLabel.sizeThatFits(CGSize(width: size.width, height: 22))
        }
        let mutableString = NSMutableAttributedString(string: title)
        mutableString.addAttributes([.font: UIFont.systemFont(ofSize: titleFontSize), .foregroundColor: UIColor.ud.textTitle], range: NSRange(location: 0, length: mutableString.length))

        // add tag
        if tagTitle != nil {
            let tagAttachment = NSTextAttachment()
            tagAttachment.image = tagLabel.asImage()
            tagAttachment.bounds = CGRect(x: 0, y: -3, width: tagLabel.bounds.width, height: tagLabel.bounds.height)
            let tagAttachmentString = NSAttributedString(attachment: tagAttachment)
            mutableString.append(tagAttachmentString)
            // add space
            mutableString.insert(NSAttributedString.init(string: " "), at: mutableString.length - 1)
            mutableString.insert(NSAttributedString.init(string: "  "), at: mutableString.length)
        }
        if needLock {
            let attachment = NSTextAttachment()
            attachment.image = Resources.mail_sig_lock
            attachment.bounds = CGRect(x: 0, y: -3, width: lockWidth, height: lockWidth)
            let attachmentString = NSAttributedString(attachment: attachment)
            mutableString.append(attachmentString)
        }
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 4
        para.alignment = .left
        mutableString.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: mutableString.length))
        self.textContainer.maximumNumberOfLines = self.lineNum
        self.textContainer.lineBreakMode = .byTruncatingTail
        self.attributedText = caculateOmit(needLock: needLock,
                                           needTag: tagTitle != nil,
                                           origin: mutableString,
                                           totalWidth: totalWidth)
        let height = self.sizeThatFits(CGSize(width: totalWidth, height: CGFloat(MAXFLOAT))).height
        self.titleHeight = ceil(height) + 4
    }
    
    func caculateOmit(needLock: Bool,
              needTag: Bool,
              origin: NSAttributedString,
              totalWidth: CGFloat) -> NSAttributedString {
        var leave = 0
        if needLock && needTag {
            leave = 5
        } else if needLock {
            leave = 1
        } else if needTag {
            leave = 4
        } else {
            // 没有tag或者lock标记的无需计算直接返回
            return origin
        }
        let lineHeight = UIFont.systemFont(ofSize: titleFontSize).lineHeight + 4
        let testView = UITextView()
        testView.textContainer.maximumNumberOfLines = 0
        testView.attributedText = origin
        let lineNum = floor(testView.sizeThatFits(CGSize(width: totalWidth, height: CGFloat(MAXFLOAT))).height / lineHeight)
        if lineNum <= 2 {
            //没有超出两行的无需计算直接返回
            return origin
        }
        // 超出两行的用二分法做截断处理
        var begin = 0, end = origin.length - 1 - leave
        var mid = (begin + end) / 2
        while(begin <= end) {
            mid = (begin + end) / 2
            let copy = NSMutableAttributedString.init(attributedString: origin)
            copy.replaceCharacters(in: NSRange(location: mid, length: origin.length - leave - mid), with: "...")
            testView.attributedText = copy
            let totalHeight = testView.sizeThatFits(CGSize(width: totalWidth, height: CGFloat(MAXFLOAT))).height
            let lineNum = floor(totalHeight / lineHeight)
            if lineNum > 2 {
                end = mid - 1
            } else if lineNum < 2 {
                begin = mid + 1
            } else {
                if begin < mid {
                    begin = mid
                } else {
                    begin = begin + 1
                }
            }
        }
        let copy = NSMutableAttributedString.init(attributedString: origin)
        if mid < origin.length - 1 - leave {
            // 为了防止计算出现误差，抛掉两个字符
            let mid = mid - 2 > 0 ? mid - 2 : mid
            copy.replaceCharacters(in: NSRange(location: mid, length: origin.length - leave - mid), with: "...")
        }
        return copy
    }
    
    func getSigTitleHeight() -> CGFloat {
        return self.titleHeight
    }
}

extension UIView {
   func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: frame.size)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
