//
//  MeetingRoomUserInfoView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/20.
//

import UIKit
import RustPB
import EENavigator
import LarkContainer
import RxSwift
import RxRelay

final class MeetingRoomUserInfoView: UIView {

    struct ViewData: Avatar {
        var avatarKey: String { creator.avatarKey }
        var userName: String { creator.name }
        var identifier: String { creator.chatterID }

        private let creator: Calendar_V1_EventCreator
        init(creator: Calendar_V1_EventCreator) {
            self.creator = creator
        }
    }

    private(set) lazy var avatarView: AvatarView = {
        let avatar = AvatarView()
        return avatar
    }()

    private(set) lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body0
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        return label
    }()

    private let bag = DisposeBag()

    let userTappedRelay = PublishRelay<String>()

    var viewData: ViewData? {
        didSet {
            if let viewData = viewData {
                avatarView.setAvatar(viewData, with: 32)
                usernameLabel.text = viewData.userName
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(avatarView)
        addSubview(usernameLabel)

        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.leading.centerY.equalToSuperview()
        }

        usernameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(6)
            make.trailing.equalToSuperview()
        }

        avatarView.layer.cornerRadius = 32 / 2
        avatarView.layer.borderWidth = 2
        avatarView.layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill)

        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.rx.event
            .compactMap({ [weak self] _ in self?.viewData?.identifier })
            .bind(to: userTappedRelay)
            .disposed(by: bag)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 32)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
