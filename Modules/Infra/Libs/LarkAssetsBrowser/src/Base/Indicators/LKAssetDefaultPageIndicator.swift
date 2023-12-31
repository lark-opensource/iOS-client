//
//  LKAssetDefaultPageIndicator.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

open class LKAssetDefaultPageIndicator: UIPageControl, LKAssetPageIndicator {

    /// 页码与底部的距离
    open lazy var bottomPadding: CGFloat = {
        if #available(iOS 11.0, *),
            let window = UIApplication.shared.keyWindow,
            window.safeAreaInsets.bottom > 0 {
            return 20
        }
        return 15
    }()

    public func setup(with assetBrowser: LKAssetBrowser) {
        isEnabled = false
    }

    public func reloadData(numberOfItems: Int, pageIndex: Int) {
        numberOfPages = numberOfItems
        currentPage = min(pageIndex, numberOfPages - 1)
        sizeToFit()
        isHidden = numberOfPages <= 1
        if let view = superview {
            center.x = view.bounds.width / 2
            frame.origin.y = view.bounds.maxY - bottomPadding - bounds.height
        }
    }

    public func didChanged(pageIndex: Int) {
        currentPage = pageIndex
    }
}
