//
//  LoadFailPlaceholderView.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

open class LoadFailPlaceholderView: LoadingPlaceholderView {
    open override var image: UIImage? {
        return Resources.load_fail
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.text = BundleI18n.LarkUIKit.Lark_Legacy_LoadFailedRetryTip
        self.backgroundColor = UIColor.ud.bgBody
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class LoadFaildRetryView: LoadFailPlaceholderView {
    public var retryAction: (() -> Void)?
    public init() {
        super.init(frame: UIScreen.main.bounds)
        let control = UIControl()
        self.addSubview(control)
        control.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        control.addTarget(self, action: #selector(taped), for: .touchUpInside)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    public func taped() {
        // retryAction可以为空，为空时说明不提供重试
        if retryAction != nil {
            // 不为空时，可重试，重试时隐藏失败界面
            self.isHidden = true
        }
        retryAction?()
    }
}
