//
//  LarkSplitViewController+Content.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/11/3.
//

import UIKit
import Foundation
import SnapKit

class SplitContentView: UIView {
    var blurView = SplitPanMaskView()

    var contentView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurView.alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showBlurView() {
        guard blurView.alpha == 0 else { return }

        UIView.animate(withDuration: 0.1) {
            self.blurView.blurView.alpha = 1
        }

        self.blurView.alpha = 1

        self.contentView.isHidden = true
        self.contentView.snp.remakeConstraints { make in
            make.size.equalTo(self.contentView.bounds.size)
            make.top.leading.equalToSuperview()
        }

        let snapshot = self.snapshotView(afterScreenUpdates: false)
        blurView.setContent(view: snapshot)
        self.bringSubviewToFront(blurView)
    }

    func hiddenBlurView() {
        guard blurView.alpha != 0 else { return }

        self.contentView.isHidden = false
        self.contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        UIView.animate(withDuration: 0.2, delay: 0.3) {
            self.blurView.blurView.alpha = 0
            self.blurView.alpha = 0
        }
    }

    func clearContent() {
        contentView.snp.removeConstraints()
        contentView.removeFromSuperview()

        contentView = UIView()
        self.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
