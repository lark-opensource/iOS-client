//
//  LoadingTipView.swift
//  ByteView
//
//  Created by chentao on 2019/10/21.
//

import UIKit
import SnapKit

public final class LoadingTipView: UIView {

    private let smallLoadingView: LoadingView
    public let tipLabel: UILabel = {
        var label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    private let contentStackView: UIStackView = {
        var stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()

    private let padding: CGFloat

    public init(frame: CGRect = .zero, padding: CGFloat = 8.0, style: LoadingView.Style = .blue) {
        self.padding = padding
        contentStackView.spacing = padding
        smallLoadingView = LoadingView(style: style)
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(smallLoadingView)
        contentStackView.addArrangedSubview(tipLabel)
        autolayoutSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func autolayoutSubviews() {
        contentStackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        smallLoadingView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(24)
        }
    }

    public func setTip(_ tip: String) {
        tipLabel.text = tip
    }

    public func start(with tip: String = "") {
        setTip(tip)
        smallLoadingView.play()
    }

    public func stop() {
        setTip("")
        smallLoadingView.stop()
    }
}
