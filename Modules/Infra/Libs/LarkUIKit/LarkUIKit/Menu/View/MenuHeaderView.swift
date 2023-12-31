//
//  MenuHeaderView.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/24.
//

import Foundation
import UIKit

/// 头部视图
final class MenuHeaderView: UIView {

    /// 内容视图
    private var contentView: MenuAdditionView?

    /// 分割线
    private var lineView: UIView?

    /// 分割线高度
    private let lineHeight: CGFloat = 0.5

    /// 初始化头部视图
    /// - Parameter headerView: 附加视图
    init(headerView: MenuAdditionView?) {
        super.init(frame: .zero)

        setupLineView()
        setupLineViewStaticConstrain()

        setupContentView(for: headerView)
        setupContentViewStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新头部视图
    /// - Parameter view: 附加视图
    func updateHeaderView(for view: MenuAdditionView?) {
        setupContentView(for: view)
        setupContentViewStaticConstrain()
    }

    /// 初始化分割线
    private func setupLineView() {
        if let line = self.lineView {
            line.removeFromSuperview()
            self.lineView = nil
        }
        let newLineView = UIView()
        newLineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.lineView = newLineView
        newLineView.isHidden = true
        self.addSubview(newLineView)
    }

    /// 初始化附加视图
    /// - Parameter view: 附加视图
    private func setupContentView(for view: MenuAdditionView?) {
        if let contentView = self.contentView {
            contentView.removeFromSuperview()
            self.contentView = nil
        }
        guard let nowView = view else {
            // 如果当前没有附加视图，则去掉分割线
            self.lineView?.isHidden = true
            return
        }
        self.addSubview(nowView)
        self.contentView = nowView
        self.lineView?.isHidden = false
    }

    private func setupContentViewStaticConstrain() {
        if let contentView = self.contentView {
            contentView.snp.remakeConstraints {
                make in
                if contentView.contentType == .custom {
                    make.top.trailing.leading.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-self.lineHeight)
                } else {
                    make.top.bottom.trailing.leading.equalToSuperview()
                }
            }
        }
    }

    /// 初始化分割线的约束
    private func setupLineViewStaticConstrain() {
        guard let line = self.lineView else {
            return
        }
        line.snp.remakeConstraints {
            make in
            make.height.equalTo(self.lineHeight)
            make.bottom.trailing.leading.equalToSuperview()
        }
    }

}
