//
//  FocusBarButtonItem.swift
//  LarkThread
//
//  Created by 姚启灏 on 2019/2/15.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignTheme
import UniverseDesignIcon

final class FocusBarButton: UIButton {
    private var isFocus: Bool = false

    var buttonImageView: UIImageView? {
        return self.imageView
    }
    private let focusImage = Resources.thread_detal_following()

    var clickBlock: ((Bool) -> Void)?

    init() {
        super.init(frame: .zero)
        setImage(Resources.thread_detail_follow, for: .normal)
        addTarget(self, action: #selector(click), for: .touchUpInside)
        tintColor = UIColor.ud.iconN1
        contentHorizontalAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.snp.remakeConstraints { (make) in
            make.width.height.equalTo(24)
        }
    }
    func updateFocusBarButton(isFocus: Bool) {
        self.isFocus = isFocus
        setImage(isFocus ? focusImage : Resources.thread_detail_follow, for: .normal)
    }

    @objc
    private func click() {
        self.clickBlock?(isFocus)
    }
}
