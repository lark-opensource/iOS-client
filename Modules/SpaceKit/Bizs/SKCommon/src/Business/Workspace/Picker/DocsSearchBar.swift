//
//  DocsSearchBar.swift
//  SpaceKit
//
//  Created by 边俊林 on 2018/12/7.
//

import UIKit
import LarkUIKit
import SKFoundation
import SKResource

public final class DocsSearchBar: UIView {
    public let textField = LarkUIKit.SearchUITextField()
    public var tapBlock: ((LarkUIKit.SearchUITextField) -> Void)? {
        didSet {
            textField.tapBlock = tapBlock
        }
    }
    private var isAnimating: Bool = false

    public var inherentHeight: CGFloat {
        return 35.0
    }

    public var preferedHeight: CGFloat {
        guard self.isHidden == false else {
            return 0
        }
        return inherentHeight
    }

    public init() {
        super.init(frame: .zero)
        textField.canEdit = false
        addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
            make.top.equalToSuperview()
        }
        clipsToBounds = true
        textField.placeholder = BundleI18n.SKResource.Doc_Facade_Search
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let alpha = max(min(1 - (32 - frame.height) / 8, 1), 0)
        textField.subviews.forEach { $0.alpha = alpha }
    }

    @discardableResult
    public func setHeight(to height: CGFloat, animated: Bool) -> CGFloat {
        @inline(__always)
        func restrainHeight(from origin: CGFloat) -> CGFloat {
            return min(inherentHeight, max(0, origin))
        }

//        let animDuration: TimeInterval = 0.25
        let targetHeight = restrainHeight(from: height)
        self.snp.updateConstraints({ (make) in
            make.height.equalTo(targetHeight)
        })
        self.superview?.dongOut()
        return targetHeight
    }

//    private func changeContentOffset(by distance: CGFloat, withScrollView scrollView: UIScrollView) {
//        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y - distance)
//    }
}
