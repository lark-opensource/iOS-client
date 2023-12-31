//
//  EmptyDataView.swift
//  Lark
//
//  Created by Yuguo on 2017/9/10.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public final class EmptyDataView: UIView {
    public static let defaultEmptyImage: UIImage = Resources.empty_data_icon
    public var contentView: UIView { return _contentView }
    private let _contentView: ContentView

    // empty content 默认使用 距离windows顶部 1/3 的布局
    // 当把 useCenterConstraints 设置为 true 的时候 content 使用中心布局
    public var useCenterConstraints: Bool = false {
        didSet {
            contentView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
            }
        }
    }

    public var topToWindow: CGFloat { UIScreen.main.bounds.height / 3 }

    public var useCustomConstraints: Bool = false

    public var label: UILabel { return _contentView.label }

    public var placeholderImage: UIImage {
        get { return _contentView.imageView.image! }
        set { _contentView.imageView.image = newValue }
    }

    public init(content: String? = nil, placeholderImage: UIImage = EmptyDataView.defaultEmptyImage) {
        _contentView = ContentView(placeholderImage: placeholderImage)
        _contentView.label.text = content
        super.init(frame: .zero)
        self.addSubview(contentView)
    }

    public init(content: NSAttributedString, placeholderImage: UIImage = EmptyDataView.defaultEmptyImage) {
        _contentView = ContentView(placeholderImage: placeholderImage)
        _contentView.label.attributedText = content
        super.init(frame: .zero)
        self.addSubview(contentView)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window,
            !self.useCenterConstraints,
            !self.useCustomConstraints else { return }
        contentView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(16)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.top.equalTo(window).offset(self.topToWindow).priorityMedium()
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private final class ContentView: UIView {
        let label = UILabel()
        let imageView = UIImageView()

        init(placeholderImage: UIImage) {
            super.init(frame: .zero)

            imageView.image = placeholderImage
            self.addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.top.centerX.equalToSuperview()
            }

            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = UIColor.ud.textPlaceholder
            label.numberOfLines = 0
            label.textAlignment = .center
            self.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.top.equalTo(imageView.snp.bottom).offset(10)
                make.centerX.bottom.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
