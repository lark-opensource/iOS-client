//
//  SearchSplitViewController.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/11/30.
//

import Foundation
import LarkSplitViewController

public protocol SearchSplitViewControllerDelegate: AnyObject {
    func searchSplitVCDidDisapper()
    func searchSplitVCWillAppear()
}

class SearchSplitViewController: SplitViewController {
    weak var searchSplitVCDelegate: SearchSplitViewControllerDelegate?
    override func isCustomShowTabBar(_ viewController: UIViewController) -> Bool? {
        if self.isCollapsed {
            return false
        }
        return super.isCustomShowTabBar(viewController)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.searchSplitVCDelegate?.searchSplitVCDidDisapper()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchSplitVCDelegate?.searchSplitVCWillAppear()
    }
}
