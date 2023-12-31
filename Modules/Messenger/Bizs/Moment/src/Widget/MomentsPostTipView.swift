//
//  MomentsPostTipView.swift
//  Moment
//
//  Created by liluobin on 2023/9/19.
//

import UIKit
import SnapKit
import UniverseDesignNotice

class MomentsPostTipView: UIView {
    let style: PostTipStyle

    init(style: PostTipStyle) {
        self.style = style
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        var text = ""
        var type: UniverseDesignNotice.UDNoticeType = .success
        switch style {
        case .success:
            text = BundleI18n.Moment.Moments_ContentUpdated_Toast
            type = .success
        case .empty:
            text = BundleI18n.Moment.Moments_NoNewContent_Toast
            type = .info
        case .fail:
            text = BundleI18n.Moment.Moments_UnableToRefreshTryAgain_Toast
            type = .error
        }
        var config = UDNoticeUIConfig(type: type, attributedText: NSAttributedString(string: text))
        config.alignment = .left
        config.lineBreakMode = .byTruncatingTail
        let udNoticeView = UDNotice(config: config)
        self.addSubview(udNoticeView)
        udNoticeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
