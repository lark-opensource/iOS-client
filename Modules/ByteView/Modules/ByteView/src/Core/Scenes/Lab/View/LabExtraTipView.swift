//
//  LabExtraTipView.swift
//  ByteView
//
//  Created by wangpeiran on 2022/11/27.
//

import Foundation
import UIKit

class LabExtraTipView: UIControl {

    private lazy var markingView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var anchorToastView = AnchorToastView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        setupViews()
    }

    func setupViews() {
        addSubview(markingView)
        addSubview(anchorToastView)

        markingView.isUserInteractionEnabled = false
        anchorToastView.isUserInteractionEnabled = false
    }

    func setMarkingFrame(frame: CGRect) {
        markingView.frame = frame
        anchorToastView.setStyle(I18n.View_G_UniBackForThisMeet, on: .top, of: markingView, distance: 0)
    }

    @objc func dismiss() {
        self.removeFromSuperview()
    }
}
