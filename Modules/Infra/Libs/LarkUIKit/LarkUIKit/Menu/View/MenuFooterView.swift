//
//  MenuFooterView.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/24.
//

import Foundation
import UIKit

/// 底部视图
final class MenuFooterView: UICollectionReusableView {
    /// 附加视图
    private var contentView: MenuAdditionView?

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupContentViewStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新底部视图
    /// - Parameter view: 新的附加视图
    func updateFooterView(for view: MenuAdditionView?) {
        setupContentView(for: view)
        setupContentViewStaticConstrain()
    }

    /// 设置底部视图
    /// - Parameter view: 新的附加视图
    private func setupContentView(for view: MenuAdditionView?) {
        if let contentView = self.contentView {
            contentView.removeFromSuperview()
            self.contentView = nil
        }
        guard let nowView = view else {
            return
        }
        self.addSubview(nowView)
        self.contentView = nowView
    }

    /// 设置附加视图的约束
    private func setupContentViewStaticConstrain() {
        if let contentView = self.contentView {
            // 当有附加视图时移除自己的高度约束
            contentView.snp.remakeConstraints {
                make in
                make.top.bottom.trailing.leading.equalToSuperview()
            }
        }
    }

    /// 计算底部视图的预期大小
    /// - Parameter contentView: 附加视图
    /// - Returns: 底部视图的预期大小
    static func prepareContentSize(for contentView: MenuAdditionView?) -> CGSize {
        guard let content = contentView else {
            return .zero
        }
        return content.forecastSize()
    }

    /// 计算底部视图调整后的预期大小
    /// - Parameters:
    ///   - contentView: 附加视图
    ///   - suggestionSize: 父视图的建议大小
    /// - Returns: 经过父视图建议后的大小
    static func suggestionContentSize(for contentView: MenuAdditionView?, suggestionSize: CGSize) -> CGSize {
        guard let content = contentView else {
            return .zero
        }
        return content.reallySize(for: suggestionSize)
    }
}
