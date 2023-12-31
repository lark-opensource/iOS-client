//
//  SKPlacehoderTextView.swift
//  SKUIKit
//
//  Created by zengsenyuan on 2022/7/4.
//  


import UIKit

/// 允许设置占位符TextView
open class SKPlacehoderTextView: SKBaseTextView {
    
   public var placeholder: String = "" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var placeholderColor: UIColor = .lightGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var placeholderFont: UIFont? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override var text: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override var attributedText: NSAttributedString? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setUp()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setUp()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func draw(_ rect: CGRect) {
        // 如果有文字，就直接返回，不需要画占位文字
        guard !self.hasText else { return }
        if placeholderFont == nil {
            placeholderFont = self.font
        }
        // 属性
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: placeholderColor]
        if let placeholderFont = placeholderFont {
            attributes.updateValue(placeholderFont, forKey: .font)
        }
        
        let width = rect.width - self.textContainer.lineFragmentPadding * 2 - self.textContainerInset.left - self.textContainerInset.right
        let placeholderRect = CGRect(x: self.textContainer.lineFragmentPadding + self.textContainerInset.left,
                                     y: self.textContainerInset.top,
                                     width: width,
                                     height: rect.height - self.textContainerInset.top - self.textContainerInset.bottom)
        let placeholder = self.placeholder as NSString
        placeholder.draw(in: placeholderRect, withAttributes: attributes)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    @objc
    func textDidChange(_ notification: NSNotification) {
        self.setNeedsDisplay()
    }
    
    func setUp() {
        self.spellCheckingType = .no
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textDidChange(_:)),
                                               name: UITextView.textDidChangeNotification, object: self)
    }
}
