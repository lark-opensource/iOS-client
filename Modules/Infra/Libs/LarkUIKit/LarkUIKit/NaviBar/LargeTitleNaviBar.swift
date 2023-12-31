//
//  LargeTitleNaviBar.swift
//  Lark
//
//  Created by ChalrieSu on 21/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

open class LargeTitleNaviBar: TitleNaviBar {
    public override var titleFontSize: CGFloat {
        return 24
    }

    public override var naviBarHeight: CGFloat {
        return 60
    }

    public override var titleView: UIView {
        didSet {
            titleView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
            }
        }
    }

    public override init(titleView: UIView,
                         leftBarItems: [TitleNaviBarItem] = [],
                         rightBarItems: [TitleNaviBarItem] = []) {
        super.init(titleView: titleView, leftBarItems: leftBarItems, rightBarItems: rightBarItems)

        titleView.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
