//
//  LKAssetNumericPageIndicator.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

open class LKAssetNumericPageIndicator: UILabel, LKAssetPageIndicator {

    ///  页码与顶部的距离
    open lazy var topPadding: CGFloat = {
        if #available(iOS 11.0, *),
           let window = superview?.window {
            return window.safeAreaInsets.top
        }
        return 20
    }()

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        config()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        config()
    }

    private func config() {
        font = UIFont.systemFont(ofSize: 17)
        textAlignment = .center
        textColor = UIColor.ud.primaryOnPrimaryFill
        backgroundColor = LKAssetBrowserView.Cons.buttonColor
        layer.masksToBounds = true
    }

    public func setup(with assetBrowser: LKAssetBrowser) {

    }

    private var total: Int = 0

    public func reloadData(numberOfItems: Int, pageIndex: Int) {
        total = numberOfItems
        text = "\(pageIndex + 1) / \(total)"
        sizeToFit()
        frame.size.height = 32
        frame.size.width += frame.height
        layer.cornerRadius = 8
        if let view = superview {
            center.x = view.bounds.width / 2
            frame.origin.y = topPadding
        }
        isHidden = numberOfItems <= 1
    }

    public func didChanged(pageIndex: Int) {
        text = "\(pageIndex + 1) / \(total)"
    }
}
