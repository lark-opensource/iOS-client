//
//  MenuAdditionView.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/24.
//

import Foundation
import UIKit
import SnapKit

/// 菜单附加视图
public final class MenuAdditionView: UIView {
    /// 菜单附加视图的类型
    var contentType: MenuAdditionViewType

    /// 菜单附加视图内部的视图
    private var contentView: UIView & MenuForecastSizeProtocol

    /// 用自定义视图初始化附加视图
    /// - Parameter customView: 自定义视图
    @objc
    public init(customView: UIView & MenuForecastSizeProtocol) {
        self.contentType = .custom
        self.contentView = customView
        super.init(frame: .zero)

        setupView()
        setupViewStaticConstrain()
    }

    /// 用标题视图初始化附加视图
    /// - Parameter titleView: 标题视图
    @objc
    public init(titleView: MenuTitleAdditionView) {
        self.contentType = .title
        self.contentView = titleView
        super.init(frame: .zero)

        setupView()
        setupViewStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(self.contentView)
    }

    private func setupViewStaticConstrain() {
        self.contentView.snp.makeConstraints {
            make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}

extension MenuAdditionView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        contentView.forecastSize()
    }

    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        contentView.reallySize(for: suggestionSize)
    }
}
