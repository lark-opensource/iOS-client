//
//  LKRichContainerView.swift
//  LKRichView
//
//  Created by 白言韬 on 2022/1/11.
//

import UIKit
import Foundation

open class LKRichContainerView: UIView {

    public let richView: LKRichView

    public init(frame: CGRect = .zero, options: ConfigOptions = ConfigOptions()) {
        richView = LKRichView(frame: frame, options: options)
        super.init(frame: frame)
        richView.containerView = self
        addSubview(richView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        richView.frame = self.bounds
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return richView.hitTest(point, with: event)
    }
}
