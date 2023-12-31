//
//  WorkPlaceBubbleView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/11/27.
//

import Foundation
import UniverseDesignFont

/// 工作台气泡组件
final class WorkPlaceBubbleView: UIView {
    /// 文案行数
    var textLines: Int = 0
    /// 文案宽度
    var textWidth: CGFloat = 0
    /// 气泡主体x-偏移量
    var bubbleXOffset: CGFloat = 0
    /// 文案字体
    let textFont: UIFont = UIFont.ud.headline
    /// 行高
    let lineHeight: CGFloat = 19.5
    /// 气泡最大宽度
    let bubbleMaxWidth: CGFloat = 280
    /// 气泡内边距(水平）
    let bubblePaddingHorizontal: CGFloat = 20
    /// 气泡内边距（垂直）
    let bubblePaddingVertical: CGFloat = 16
    /// 气泡安全边距（距离屏幕边缘）
    let safeInset: CGFloat = 8
    /// 箭头高度
    let arrowHeight: CGFloat = 10
    /// 箭头宽度
    let arrowWidth: CGFloat = 20

    /// 箭头视图
    private lazy var arrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.blue_bubble_arrow.ud.withTintColor(UIColor.ud.primaryFillHover)
        return imageView
    }()
    /// 气泡主体
    private lazy var bubbleView: UIView = {
        let bubble = UIView()
        bubble.backgroundColor = UIColor.ud.primaryFillHover
        bubble.layer.cornerRadius = 8
        bubble.layer.ud.setShadowColor(UIColor.ud.primaryContentPressed)
        bubble.layer.shadowOpacity = 0.3
        bubble.layer.shadowRadius = 24
        bubble.layer.shadowOffset = CGSize(width: 0, height: 12)
        return bubble
    }()
    /// 文案
    private lazy var textView: UILabel = {
        let textView = UILabel()
        textView.font = textFont
        textView.textColor = UIColor.ud.primaryOnPrimaryFill
        textView.textAlignment = .left
        textView.numberOfLines = 0
        return textView
    }()

    init(anchorPoint: CGPoint, text: String, windowMaxWidth: CGFloat) {
        super.init(frame: .zero)
        setupViews()
        updateLayout(anchorPoint: anchorPoint, text: text, windowMaxWidth: windowMaxWidth)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新布局和视图
    func updateLayout(anchorPoint: CGPoint, text: String, windowMaxWidth: CGFloat) {
        self.textView.text = text
        self.frame = getBubbleFrame(anchor: anchorPoint, text: text, windowMaxWidth: windowMaxWidth)
        updateConstraints()
    }

    /// 刷新布局
    override func updateConstraints() {
        arrowView.snp.updateConstraints { (make) in
            make.centerX.equalToSuperview().offset(bubbleXOffset)
        }
        super.updateConstraints()
    }

    private func setupViews() {
        self.clipsToBounds = false
        self.backgroundColor = .clear
        addSubview(bubbleView)
        addSubview(arrowView)
        bubbleView.addSubview(textView)
        arrowView.snp.makeConstraints { (make) in
            make.width.equalTo(arrowWidth)
            make.height.equalTo(arrowHeight)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview().offset(bubbleXOffset)
        }
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(arrowHeight)
            make.left.right.bottom.equalToSuperview()
        }
        textView.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualTo(bubbleMaxWidth - bubblePaddingHorizontal * 2)
            make.top.equalToSuperview().offset(bubblePaddingVertical)
            make.left.equalToSuperview().offset(bubblePaddingHorizontal)
        }
    }

    /// 计算text展示行数和宽度
    private func calculateText(text: String) {
        let string: NSString = text as NSString
        let width = string.size(withAttributes: [.font: textFont]).width
        if width + bubblePaddingHorizontal * 2 > bubbleMaxWidth {
            self.textWidth = bubbleMaxWidth - bubblePaddingHorizontal * 2
            self.textLines = Int(width / textWidth) + 1
        } else {
            self.textWidth = width
            self.textLines = 1
        }
    }

    /// 计算气泡frame
    private func getBubbleFrame(anchor: CGPoint, text: String, windowMaxWidth: CGFloat) -> CGRect {
        calculateText(text: text)   // 根据text算出需要 展示的行数 和 每行宽度
        let halfBubbleWidth = textWidth / 2 + bubblePaddingHorizontal
        if anchor.x + halfBubbleWidth > (windowMaxWidth - safeInset) {    // 气泡边缘超出安全边距（右）
            self.bubbleXOffset = (anchor.x + halfBubbleWidth) - windowMaxWidth + safeInset
        }
        return CGRect(
            x: anchor.x - halfBubbleWidth - self.bubbleXOffset,    //  anchor偏移 一半宽度 到origin（注意箭头的偏移）
            y: anchor.y,                                           //  和anchor的y对齐
            width: textWidth + bubblePaddingHorizontal * 2,
            height: lineHeight * CGFloat(textLines) + bubblePaddingVertical * 2 + arrowHeight
        )
    }
}
