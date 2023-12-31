//
//  SceneListTableView.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import UIKit

/// 我的场景，表格视图
final class SceneListTableView: UITableView {
    /// 进入我的场景时，首屏加载数据的loading
    lazy var loadingView = SceneListLoadingView(frame: .zero)
    /// 加载数据后，空态图
    lazy var emptyView = SceneListEmptyView(frame: .zero)
    /// 加载数据后，错误图
    lazy var errorView = SceneListErrorView(frame: .zero)

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.backgroundColor = UIColor.clear
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.separatorStyle = .none
        self.lu.register(cellWithClass: SceneListTableViewCell.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addTo(viewController: SceneListViewController) {
        viewController.view.addSubview(self)
        self.delegate = viewController
        self.dataSource = viewController
        self.snp.makeConstraints { make in
            make.top.equalTo(viewController.viewTopConstraint).offset(60)
            make.left.right.equalTo(viewController.view)
            make.bottom.equalTo(viewController.viewBottomConstraint).offset(-70)
        }
    }
}
