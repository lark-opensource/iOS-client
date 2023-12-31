//
//  DetailTopNoticeView.swift
//  Todo
//
//  Created by wangwanxin on 2022/7/14.
//

import Foundation
import UniverseDesignNotice
import UniverseDesignIcon

final class DetailTopNoticeView: UIView {

    var config: DetailModuleEvent.NoticeConfig? {
        didSet {
            guard let config = config, !config.text.isEmpty else {
                isHidden = true
                return
            }
            isHidden = false
            var noticeConfig = UDNoticeUIConfig(
                type: config.type,
                attributedText: AttrText(string: config.text)
            )
            if config.type == .error {
            noticeConfig.leadingIcon = UDIcon.getIconByKey(
                    .deleteTrashFilled,
                    iconColor: UIColor.ud.functionDangerContentDefault
                )
            }
            noticeView.updateConfigAndRefreshUI(noticeConfig)
        }
    }

    private lazy var noticeView: UDNotice = {
        var config = UDNoticeUIConfig(
            type: .info,
            attributedText: AttrText(string: "")
        )
        let notice = UDNotice(config: config)
        return notice
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(noticeView)
        noticeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = noticeView.sizeThatFits(bounds.size)
        return CGSize(width: Self.noIntrinsicMetric, height: size.height)
    }
}
