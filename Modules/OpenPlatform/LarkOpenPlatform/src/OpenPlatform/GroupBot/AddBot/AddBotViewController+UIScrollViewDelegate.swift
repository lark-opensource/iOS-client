//
//  AddBotViewController+UIScrollViewDelegate.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/4/7.
//

import UIKit

// MARK: - UIScrollViewDelegate
extension AddBotViewController {
    func _scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
}
