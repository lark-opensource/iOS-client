//
//  EmotionProgressView.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/13.
//

import UIKit
import Foundation
import SnapKit

final class EmotionProgressView: UIView {
    var processView = UIView()
    var process = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        self.backgroundColor = UIColor.ud.N200
        self.layer.cornerRadius = 1.5
        self.layer.masksToBounds = true

        self.addSubview(processView)
        processView.backgroundColor = UIColor.ud.colorfulBlue
        processView.layer.masksToBounds = true
        update(percent: 0)
    }

    public func update(percent: Double) {
        guard percent >= 0 && percent <= 1 else {
            assert(false, "progress无效,必须0到1之间")
            return
        }
        self.processView.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(percent)
        }
    }
}
