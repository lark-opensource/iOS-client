//
//  FullTitleView.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/2/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

public final class FullTitleView: UIView {
    let title: String
    private static let maxHeight: CGFloat = 492
    private static let maxHeightForPad: CGFloat = 607

    // 蒙层内的最外层视图，负责阴影
    private let containerView = UIView()
    // textView的直接父视图，负责圆角
    private let textContainer = UIView()
    // 由于设计稿要求 textView 上下左右都要有 16 的内边距，因此让 inset 为 0，手动指定 textView 与父视图的间距
    private let textView = UITextView()
    private let arrowView = TriangleView()

    enum Layout {
        static var ArrowWidth: CGFloat = CGFloat(sin(Double.pi / 4.0) * 13)
        static var ArrowLength: CGFloat = 2 * ArrowWidth
    }

    public init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var hasShown: Bool {
        return superview != nil
    }

    public func show(on label: UIView, from: UIViewController, animated: Bool) {
        guard let labelContainer = label.superview else { return }

        hide(animated: false)

        backgroundColor = .clear
        arrowView.isHidden = false

        let rect = labelContainer.convert(label.frame, to: self)
        textContainer.layer.cornerRadius = 12
        containerView.layer.ud.setShadowColor(.ud.N1000.withAlphaComponent(0.3))
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 100
        containerView.snp.remakeConstraints { (make) in
            make.top.equalTo(rect.maxY + 17)
            make.width.equalTo(375)
            make.centerX.equalTo(rect.midX)
        }
        textView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview().inset(16)
            make.height.lessThanOrEqualTo(FullTitleView.maxHeightForPad)
        }

        show(animated: animated, from: from)
    }

    public func showFullScreen(animated: Bool, from: UIViewController) {
        hide(animated: false)

        backgroundColor = UIColor.ud.bgMask
        arrowView.isHidden = true
        textContainer.layer.cornerRadius = 8
        containerView.layer.ud.setShadowColor(UIColor.clear)
        containerView.layer.shadowOffset = .zero
        containerView.layer.shadowOpacity = 0
        containerView.layer.shadowRadius = 0
        containerView.snp.remakeConstraints { (make) in
            make.left.right.lessThanOrEqualToSuperview().inset(16).priority(999)
            make.center.equalToSuperview()
        }
        textView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview().inset(16)
            make.height.lessThanOrEqualTo(FullTitleView.maxHeight).priority(.low)
        }

        show(animated: animated, from: from)
    }

    private func show(animated: Bool, from: UIViewController) {
        guard let window = from.view.window else { return }
        window.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if animated {
            alpha = 0
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
            }
        }
    }

    public func hide(animated: Bool) {
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        } else {
            removeFromSuperview()
        }
    }

    private func setupSubviews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        containerView.backgroundColor = .clear
        addSubview(containerView)

        textContainer.backgroundColor = UIColor.ud.bgFloat
        containerView.addSubview(textContainer)
        textContainer.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        if traitCollection.isRegular {
            textView.attributedText = NSAttributedString(string: title, config: .bodyAssist)
        } else {
            textView.attributedText = NSAttributedString(string: title, config: .body)
        }
        textView.textColor = UIColor.ud.textTitle
        textView.backgroundColor = .clear
        textView.layer.masksToBounds = true
        textView.isEditable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.usesFontLeading = false
        textView.textContainerInset = .zero
        textView.setContentHuggingPriority(.required, for: .horizontal)
        textContainer.addSubview(textView)

        arrowView.direction = .bottom
        arrowView.color = .white
        arrowView.backgroundColor = .clear
        addSubview(arrowView)
        arrowView.snp.makeConstraints { (make) in
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView.snp.top)
            make.width.equalTo(Layout.ArrowLength)
            make.height.equalTo(Layout.ArrowWidth)
        }

        updateHeight()

        NotificationCenter.default.addObserver(self, selector: #selector(updateHeight), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc private func updateHeight() {
        let textHeight = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 24 - 32, height: .greatestFiniteMagnitude)).height
        textView.isScrollEnabled = textHeight >= FullTitleView.maxHeight
    }

    @objc private func handleTap() {
        hide(animated: true)
    }
}
