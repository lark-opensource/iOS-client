//
//  UDBadge.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/26.
//

import Foundation
import UIKit

extension UDBadge {
    enum Layout {
        static let labelPadding: CGFloat = 4.0
    }
    enum Style {
        static let defaultFontSize = UIFont.systemFont(ofSize: 12.0, weight: .medium)
    }
}

/// UDBadge
public final class UDBadge: UIView {

    /// badge config default value is dot
    /// change config will auto update UI
    public var config: UDBadgeConfig {
        didSet { didUpdateConfig() }
    }

    let contentView = UIView(frame: .zero)
    let label = UILabel(frame: .zero)
    let icon = UIImageView(frame: .zero)

    internal var lastRefreshId: AnyHashable?

    public override var intrinsicContentSize: CGSize {
        return currentSize
    }

    public init(config: UDBadgeConfig) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil && superview?.badge != nil {
            superview?.badge = nil
        }
    }

    private func setupView() {
        layer.masksToBounds = true
        isUserInteractionEnabled = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(contentView)
        contentView.addSubview(label)
        contentView.addSubview(icon)

        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        layer.allowsEdgeAntialiasing = true
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        label.font = Style.defaultFontSize
        label.textColor = config.contentStyle.color

        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        icon.setContentHuggingPriority(.defaultHigh, for: .vertical)
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
}
