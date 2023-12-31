//
//  GuideCustomView.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/08/13.
//

import Foundation
import UIKit

public protocol GuideCustomViewDelegate: AnyObject {
    func didCloseView(customView: GuideCustomView)
}

open class GuideCustomView: UIView {
    public weak var delegate: GuideCustomViewDelegate?
    public init(delegate: GuideCustomViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func closeGuideCustomView(view: GuideCustomView) {
        self.delegate?.didCloseView(customView: self)
    }
}
