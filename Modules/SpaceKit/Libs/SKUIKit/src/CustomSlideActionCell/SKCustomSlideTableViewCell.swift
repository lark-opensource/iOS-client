//
//  SKCustomSlideTableViewCell.swift
//  SKUIKit
//
//  Created by Weston Wu on 2023/5/19.
//

import UIKit
import SnapKit

open class SKCustomSlideTableViewCell: UITableViewCell {

    private let slideContainerView = SKCustomSlideContentView()
    /// 使用时，要在 containerView 内添加自定义的 UI 元素
    public var containerView: UIView {
        slideContainerView.contentView
    }
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(slideContainerView)
        slideContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        slideContainerView.prepareForReuse()
    }

    public func forceShowSlideActions() {
        slideContainerView.forceShowSlideActions()
    }

    public func configSlideItem(provider: @escaping SKCustomSlideItemProvider) {
        slideContainerView.slideItemProvider = provider
    }
}
