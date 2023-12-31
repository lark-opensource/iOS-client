//
//  MomentsNickNameHeaderView.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import Foundation
import RxSwift
import SnapKit
import LarkBizAvatar
import UIKit
import ByteWebImage
import LKCommonsLogging

final class MomentsNickNameHeaderView: UIView {
    static let logger = Logger.log(MomentsNickNameHeaderView.self, category: "Module.Moments.MomentsNickNameHeaderView")
    lazy var avatarImageView: BizAvatar = BizAvatar()
    lazy var nameLabel: UILabel = UILabel()
    private let avatarWidth: CGFloat = 102

    var avatarBottom: CGFloat {
        return avatarImageView.frame.maxY
    }

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.backgroundColor = UIColor.ud.bgBody
        nameLabel.numberOfLines = 3
        nameLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.textAlignment = .left
        self.addSubview(avatarImageView)
        self.addSubview(nameLabel)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: avatarWidth, height: avatarWidth))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(avatarImageView.snp.right).offset(24)
            make.centerY.equalTo(avatarImageView)
        }
    }

    func updateUIWith(avatarKey: String, avatarId: String, name: String) {
        nameLabel.text = name
        avatarImageView.setAvatarByIdentifier(avatarId,
                                              avatarKey: avatarKey,
                                              scene: .Moments,
                                              options: [.downsampleSize(CGSize(width: avatarWidth,
                                                                                      height: avatarWidth))],
                                              avatarViewParams: .init(sizeType: .size(avatarWidth)),
                                              completion: { result in
            if case let .failure(error) = result {
                Self.logger.error("MomentsNickNameHeaderView error setAvatarByIdentifier \(avatarKey)", error: error)
            }
        })
    }
}
