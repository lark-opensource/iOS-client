//
//  LoadingButton.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/9.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Lottie

extension UIControl.State {
    public static var loading: UIControl.State = UIControl.State(rawValue: 1 << 16)
}

open class LoadingButton: UIButton {

    /// 不同场景下的按钮样式
    public var displayType: DisplayType = .sketch

    public var spacing: CGFloat = 4.0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public var loadingViewSize: CGSize = CGSize(width: 12.0, height: 12.0) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    public override var state: UIControl.State {
        isLoading ? [super.state, UIControl.State.loading] : super.state
    }

    public var isLoading: Bool = false {
        didSet {
            guard oldValue != isLoading else {
                return
            }
            if isLoading {
                isUserInteractionEnabled = false
                loadingView.play()
                loadingView.isHidden = false
            } else {
                isUserInteractionEnabled = true
                loadingView.stop()
                loadingView.isHidden = true
            }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    private let loadingView: LOTAnimationView = {
        let loading = LOTAnimationView(name: "videochat_loading_blue", bundle: .localResources)
        loading.backgroundColor = .clear
        loading.loopAnimation = true
        return loading
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    public convenience init(displayType: DisplayType) {
        self.init(frame: .zero)
        self.displayType = displayType
        switch displayType {
        case .sketch:
            loadingViewSize = CGSize(width: 12.0, height: 12.0)
            titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        case .tab:
            loadingViewSize = CGSize(width: 20.0, height: 20.0)
            titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isLoading {
            loadingView.frame = CGRect(x: self.contentEdgeInsets.left,
                                       y: (self.bounds.height - loadingViewSize.height) * 0.5,
                                       width: loadingViewSize.width,
                                       height: loadingViewSize.height)
            var titleFrame = self.titleLabel?.frame ?? .zero
            titleFrame.origin.x = loadingView.frame.maxX + spacing
            self.titleLabel?.frame = titleFrame
        } else {
            // NOP
        }
    }

    public override var intrinsicContentSize: CGSize {
        if !isLoading {
            return super.intrinsicContentSize
        }
        var size = super.intrinsicContentSize
        size.width += loadingViewSize.width + spacing
        return size
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        if !isLoading {
            return super.sizeThatFits(size)
        }
        var size = super.sizeThatFits(size)
        size.width += loadingViewSize.width + spacing
        return size
    }

    private func setupSubviews() {
        loadingView.isHidden = true
        self.addSubview(self.loadingView)
    }

    public enum DisplayType {
        case sketch // 标注
        case tab // VC-Tab，包括会议统计、投票统计
    }

}
