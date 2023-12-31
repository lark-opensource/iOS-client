//
//  SpaceEntranceFooterView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import UIKit
import UniverseDesignColor

// 目前只有一个灰色的背景
class SpaceEntranceFooterView: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
    }
}
