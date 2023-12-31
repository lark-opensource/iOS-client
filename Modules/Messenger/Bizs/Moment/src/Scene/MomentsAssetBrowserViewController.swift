//
//  MomentsAssetBrowserViewController.swift
//  Moment
//
//  Created by bytedance on 3/11/22.
//

import Foundation
import LarkAssetsBrowser

final class MomentsAssetBrowserViewController: LKAssetBrowserViewController {
    var currentPageIndexWillChangeCallBack: ((_ newValue: Int) -> Void)?
    override func currentPageIndexWillChange(_ newValue: Int) {
        super.currentPageIndexWillChange(newValue)
        currentPageIndexWillChangeCallBack?(newValue)
    }
}
