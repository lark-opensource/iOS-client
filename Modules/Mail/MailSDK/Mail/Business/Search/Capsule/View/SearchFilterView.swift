//
//  SearchFilterView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import LarkModel
//import LarkSDKInterface

 protocol SearchFilterViewDelegate: AnyObject {
    func filterViewDidClick(_ filterView: MailSearchFilterView)
}

 final class MailSearchFilterView: UIView {
     struct AvatarInfo: Equatable {
        let avatarKey: String
        let avatarID: String
    }
     weak var delegate: SearchFilterViewDelegate?
     private(set) var filter: MailSearchFilter

    private let stackView = UIStackView()
    private let label = UILabel()
    private let avatarStackView = RoundAvatarStackView(avatarViews: [])

     init(filter: MailSearchFilter) {
        self.filter = filter
        super.init(frame: .zero)

        defer {
            set(filter: filter)
        }

        clipsToBounds = true
        layer.cornerRadius = 4

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 2
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.top.equalTo(6)
            make.bottom.equalTo(-6)
        }

        label.font = UIFont.systemFont(ofSize: 16)
        stackView.addArrangedSubview(label)

        stackView.addArrangedSubview(avatarStackView)

        lu.addTapGestureRecognizer(action: #selector(filterDidClick), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

     func set(filter: MailSearchFilter) {
        self.filter = filter

        label.text = filter.title
//
//        if let avatarViews = filter.getAvatarViews() {
//            avatarStackView.set(avatarViews)
//        }
        avatarStackView.isHidden = avatarStackView.avatarViews.isEmpty
        if filter.isEmpty {
            label.textColor = UIColor.ud.textTitle
            backgroundColor = UIColor.ud.bgFloatOverlay
            layer.borderWidth = 1
            layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        } else {
            label.textColor = UIColor.ud.primaryPri500
            backgroundColor = UIColor.ud.functionInfo100
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    @objc
    private func filterDidClick() {
        delegate?.filterViewDidClick(self)
    }
}
