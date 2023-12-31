//
//  ReminderTipsItemView.swift
//  SKBrowser
//
//  Created by lijuyou on 2022/10/27.
//  


import SKFoundation
import SKUIKit
import SnapKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignNotice

class ReminderTipsItemView: UIView {
    
    struct Layout {
        static let horizontalMargin = CGFloat(16)
        static let verticalMargin = CGFloat(13)
    }
    
    private var noticeText = ""
    private lazy var noticeView: UDNotice = {
        let attributedText = NSAttributedString(string: noticeText,
                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                             .foregroundColor: UIColor.ud.textTitle])
        let notice = UDNotice(config: UDNoticeUIConfig(type: .warning, attributedText: attributedText))
        notice.layer.cornerRadius = 6
        return notice
    }()

    init(text: String) {
        super.init(frame: .zero)
        self.noticeText = text
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(noticeView)
        noticeView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.verticalMargin)
            make.left.right.equalToSuperview().inset(Layout.horizontalMargin)
        }
    }
    
    func calcHeightWithPreferedWidth(_ preferedWidth: CGFloat) -> CGFloat {
        let width = preferedWidth - Layout.horizontalMargin * 2
        var size = noticeView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        size.height += Layout.verticalMargin * 2
        return size.height
    }
}
