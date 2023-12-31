//
//  MinutesSubtitlesTransformingView.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/1/27.
//

import UIKit
import UniverseDesignColor
import LarkUIKit

class MinutesSubtitlesTransformingView: UIView {

    private lazy var loadingView: LoadingPlaceholderView = {
        let view = LoadingPlaceholderView(frame: .zero)
        view.isHidden = false
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_TranscriptionInProgress
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame

        addSubview(loadingView)
        addSubview(titleLabel)

        loadingView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.height.equalTo(150)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(20)
            maker.top.equalTo(loadingView.snp.bottom).offset(20)
            maker.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
