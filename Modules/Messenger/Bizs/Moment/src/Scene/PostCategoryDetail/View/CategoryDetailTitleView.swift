//
//  BaseInfoNavTitleView.swift
//  Moment
//
//  Created by liluobin on 2021/4/27.
//

import Foundation
import UIKit
import SnapKit
import LKCommonsLogging
import LarkBizAvatar
import AvatarComponent

final class BaseInfoNavTitleView: UIView {
    static let logger = Logger.log(BaseInfoNavTitleView.self, category: "Module.Moments.BaseInfoNavTitleView")
    let titleLabel = UILabel()
    let avatarWidth: CGFloat = 24
    let style: AvatarComponentUIConfig.Style
    let cornerRadius: CGFloat

    public lazy var avatarView: BizAvatar = {
        let view = BizAvatar()
        view.layer.cornerRadius = self.cornerRadius
        view.clipsToBounds = true
        let config = AvatarComponentUIConfig(style: self.style)
        view.setAvatarUIConfig(config)
        return view
    }()

    init(style: AvatarComponentUIConfig.Style = .square,
         cornerRadius: CGFloat = 0) {
        self.style = style
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(avatarView)
        addSubview(titleLabel)
        avatarView.backgroundColor = UIColor.ud.N300
        titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        avatarView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    func updateUIWith(title: String,
                      entityId: String,
                      imageKey: String) {
        avatarView.setAvatarByIdentifier(entityId,
                                         avatarKey: imageKey,
                                         scene: .Moments,
                                         avatarViewParams: .init(sizeType: .size(avatarWidth)),
                                         backgroundColorWhenError: UIColor.ud.N300) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                Self.logger.error("update image error----\(String(describing: error))")
            }
        }
        titleLabel.text = title
    }

}
