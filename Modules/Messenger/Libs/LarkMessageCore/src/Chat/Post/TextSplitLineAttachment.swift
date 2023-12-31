//
//  TextSplitLineAttachment.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/3/1.
//

import Foundation
import UIKit
import EditTextView

public final class TextSplitLineAttachment: UIView, AttachmentPreviewableView {
    /// 缓存一份，UIGraphicsImageRenderer构造失败时使用
    private var cachePreviewImage: UIImage?

    public lazy var previewImage: () -> UIImage? = { [weak self] in
        guard let `self` = self else { return nil }
        let rendererImage = UIGraphicsImageRenderer(bounds: self.bounds).image { context in
            self.layer.render(in: context.cgContext)
        }
        if rendererImage.cgImage != nil {
            self.cachePreviewImage = rendererImage
            return rendererImage
        }
        return self.cachePreviewImage
    }

    public override var frame: CGRect {
        didSet {
            guard frame.height > 0 else {
                return
            }
            let y = (self.frame.height - 10) / 2.0
            self.splitView.frame = CGRect(x: 0, y: y, width: frame.width, height: 10)
        }
    }

    let splitView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        splitView.backgroundColor = UIColor.ud.iconN3
        self.addSubview(splitView)
        self.clipsToBounds = true
        self.backgroundColor = .clear
    }
}

public final class TextSplitConstructor {
    public static func splitTextAttributeStringFor(font: UIFont) -> NSAttributedString {
        let muAttr = NSMutableAttributedString(string: "  ")
        let height = font.lineHeight
        let attachment = TextSplitLineAttachment()
        attachment.frame = CGRect(x: 0, y: 0, width: 1, height: height)
        let textAttachment = CustomTextAttachment(customView: attachment, bounds: CGRect(x: 0,
                                                                                         y: font.descender,
                                                                                         width: 1,
                                                                                         height: height))
        muAttr.append(NSAttributedString(attachment: textAttachment))
        muAttr.append(NSAttributedString(string: "  "))
        return muAttr
    }
}
