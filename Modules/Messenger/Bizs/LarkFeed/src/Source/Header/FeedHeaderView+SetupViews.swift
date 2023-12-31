//
//  FeedHeaderView+SetupViews.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import UIKit
import Foundation
import LarkOpenFeed

extension FeedHeaderView {

    // MARK: 构造/释放各个view
    func setupViews(display: Bool, viewModel: FeedHeaderItemViewModelProtocol) {
        if display {
            if headerViewsMap[viewModel.type] != nil {
                return
            }
            viewModel.fireWidth(self.bounds.size.width)
            guard let view = FeedHeaderFactory.view(for: viewModel) else { return }
            let oldFrame = view.frame
            view.frame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: bounds.width, height: viewModel.viewHeight)
            self.addSubview(view)
            headerViewsMap[viewModel.type] = view
            if viewModel.type == .shortcut {
                self.shortcutsViewModel = viewModel as? ShortcutsViewModel
                self.shortcutsView = view as? ShortcutsCollectionView
            }
        } else {
            if headerViewsMap[viewModel.type] == nil {
                return
            }
            headerViewsMap[viewModel.type]?.removeFromSuperview()
            headerViewsMap.removeValue(forKey: viewModel.type)
            if viewModel.type == .shortcut {
                self.shortcutsViewModel = nil
                self.shortcutsView = nil
            }
        }

        // 排序
        var views = [UIView]()
        var visibleVMs = [FeedHeaderItemViewModelProtocol]()
        var extra = ""
        viewModels.forEach { viewModel in
            guard let view = headerViewsMap[viewModel.type] else { return }
            views.append(view)
            visibleVMs.append(viewModel)
            extra.append("\(viewModel.type)'display = \(viewModel.display),")
        }
        FeedContext.log.info("feedlog/header/setupViews. \(viewModel.type)'display = \(display); extra: \(extra)")
        sortedSubViews = views
        visibleViewModels = visibleVMs
    }
}
