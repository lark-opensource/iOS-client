//
//  ASRStatusView.swift
//  ByteView
//
//  Created by chentao on 2020/1/6.
//

import UIKit

class ASRStatusView: UIView {
    let loadingTipView: LoadingTipView = {
        var view = LoadingTipView()
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        backgroundColor = .clear
        addSubview(loadingTipView)

        loadingTipView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }
    }
}
