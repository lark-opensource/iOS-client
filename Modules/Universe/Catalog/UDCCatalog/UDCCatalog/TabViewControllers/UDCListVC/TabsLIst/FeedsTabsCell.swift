//
//  FeedsTabsCell.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/22.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTabs

class FeedsTabsCell: UDTabsTitleCell {
    private var moreTap: UITapGestureRecognizer?

    var tapCallBack: (() -> Void)?

    var tapView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(tapView)

        tapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let moreTap = UITapGestureRecognizer(target: self, action: #selector(tap))

        moreTap.numberOfTapsRequired = 2
//        moreTap.cancelsTouchesInView = false
//        moreTap.delaysTouchesBegan = true
        tapView.addGestureRecognizer(moreTap)
        self.moreTap = moreTap
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tap() {
        self.tapCallBack?()
    }
}

extension FeedsTabsCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
