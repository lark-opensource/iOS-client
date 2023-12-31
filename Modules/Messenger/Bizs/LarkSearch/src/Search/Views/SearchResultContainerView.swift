//
//  SearchResultContainerView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import UIKit
import SnapKit
import LarkBizAvatar
import RxSwift

// 默认容器 image + 3行label + button
class SearchResultDefaultView: UIView, SearchResultContentView {
    static let searchAvatarImageDefaultSize: CGFloat = 48
    static let searchJumpButtonDefaultSize: CGFloat = 48
    private let baseStackView: UIStackView = {
        let baseStackView = UIStackView()
        baseStackView.axis = .horizontal
        baseStackView.alignment = .top
        baseStackView.spacing = 12
        return baseStackView
    }()
    let avatarView = LarkMedalAvatar()
    let infoView = SearchResultDefaultInfoView()
    let jumpButton = UIButton()
    public var nameStatusView: SearchResultNameStatusView {
        return infoView.nameStatusView
    }
    public var firstDescriptionLabel: SearchLabel {
        return infoView.firstDescriptionLabel
    }
    public var secondDescriptionLabel: SearchLabel {
        return infoView.secondDescriptionLabel
    }
    public var extraView: UIView {
        return infoView.extraView
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(baseStackView)
        baseStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        baseStackView.addArrangedSubview(avatarView)
        let infoConatinerView = UIView()
        infoConatinerView.addSubview(infoView)
        infoView.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview().priority(.required)
            make.top.greaterThanOrEqualToSuperview().priority(.required)
            make.bottom.lessThanOrEqualToSuperview().priority(.required)
        }
        baseStackView.addArrangedSubview(infoConatinerView)
        infoConatinerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().priority(.required)
        }
        baseStackView.addArrangedSubview(jumpButton)
        jumpButton.isHidden = true
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: Self.searchAvatarImageDefaultSize, height: Self.searchAvatarImageDefaultSize))
        }
        jumpButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: Self.searchJumpButtonDefaultSize, height: Self.searchJumpButtonDefaultSize))
        }
    }

    public func restoreViewsContent() {
        avatarView.image = nil
        avatarView.setMiniIcon(nil)
        avatarView.backgroundColor = UIColor.clear
        infoView.restoreViewsContent()
        jumpButton.imageView?.image = nil
        jumpButton.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
