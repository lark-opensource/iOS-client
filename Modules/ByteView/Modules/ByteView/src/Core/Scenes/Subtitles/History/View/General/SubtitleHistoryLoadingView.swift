//
//  SubtitleHistoryLoadingView.swift
//  ByteView
//
//  Created by fakegourmet on 2020/11/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

class SubtitleHistoryLoadingView: UIView {

    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(style: .blue)
        return loadingView
    }()

    private lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_VM_Loading
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(loadingView)
        addSubview(loadingLabel)

        loadingView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.height.equalTo(40)
        }

        loadingLabel.snp.makeConstraints {
            $0.top.equalTo(loadingView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        loadingView.play()
    }

    func stop() {
        loadingView.stop()
    }
}
