//
//  SpaceVerticalGridFooterView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import UIKit
import UniverseDesignColor

class SpaceVerticalGridFooterView: UICollectionReusableView {
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
