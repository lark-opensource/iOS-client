//
//  WebViewProgressView.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2017/2/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

open class WebViewProgressView: UIView {
    private var progressBarView: UIView = .init()

    private var progress: Double = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        self.autoresizingMask = [.flexibleWidth]

        self.progressBarView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.bounds.height))
        self.progressBarView.autoresizingMask = [.flexibleHeight]
        if let window = self.window {
            self.progressBarView.backgroundColor = window.tintColor
        }
        self.addSubview(progressBarView)

        self.setProgress(0, animated: false)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setInitialProgress(animated: Bool) {
        UIView.animate(withDuration: TimeInterval(animated ? 0.25 : 0), delay: 0, options: .curveEaseInOut, animations: {
            self.progressBarView.frame.size.width = CGFloat(0.1) * self.bounds.width
        })
    }

    public func setProgress(_ progress: Double, animated: Bool) {
        self.progress = progress

        if progress <= 1 {
            UIView.animate(withDuration: TimeInterval(animated ? 0.25 : 0), delay: 0, options: .curveEaseInOut, animations: {
                self.progressBarView.frame.size.width = CGFloat(progress) * self.bounds.width
            })
        }

        if progress == 1 {
            UIView.animate(withDuration: TimeInterval(animated ? 0.25 : 0), delay: 0.1, options: .curveEaseInOut, animations: {
                self.progressBarView.alpha = 0
            })
        }
    }

    public var progressBarColor: UIColor? {
        get {
            return progressBarView.backgroundColor
        }

        set {
            progressBarView.backgroundColor = newValue
        }
    }
}
