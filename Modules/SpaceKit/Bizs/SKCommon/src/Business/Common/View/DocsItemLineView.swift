//
//  DocsItemLineView.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

public final class DocsItemLine: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.lineDividerDefault
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class DocsItemArrow: UIImageView {
    public init() {
        super.init(frame: .zero)
        image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        tintColor = UDColor.iconN3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
