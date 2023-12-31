//
//  AvatarView.swift
//  Calendar
//
//  Created by zhuchao on 2018/1/23.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import Foundation
import CalendarFoundation
import Kingfisher
import RustPB
import LarkBizAvatar

public protocol Avatar {
    var avatarKey: String { get }
    var userName: String { get }
    var identifier: String { get }
}

class AvatarView: UIView {
    private let imageView = BizAvatar()

    init() {
        super.init(frame: .zero)
        self.layoutAvatarImageView(imageView)
    }

    private func layoutAvatarImageView(_ imageView: UIView) {
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imageView.clipsToBounds = true
        self.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
        self.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .vertical)
    }

    func setAvatar(seed: AvatarSeed, size: CGFloat) {
        // 清理掉旧的image, 否则复用的话会有问题
        nameImageView.image = nil
        imageView.image = nil
        imageView.layer.cornerRadius = size / 2.0
        switch seed {
        case .lark(let identifier, let avatarKey):
            var identifier = identifier
            if identifier == "0" {
                assertionFailure("identifier 不能为 0")
                // 兜底逻辑
                identifier = ""
            }
            imageView.setAvatarByIdentifier(identifier,
                                            avatarKey: avatarKey,
                                            avatarViewParams: .init(sizeType: .size(size), format: .webp),
                                            completion: nil)
        case .local(let title):
            var avatarImage: UIImage?
            if title.isEmpty {
                avatarImage = self.generateGreyImage()
            } else {
                avatarImage = AvatarView.generateAvatarImage(withNameString: title.abbreviation())
            }
            self.nameImageView.image = avatarImage
            self.insertSubview(self.nameImageView, aboveSubview: imageView)
            imageView.image = nil
        }
    }

    func setAvatar(_ avatar: Avatar, with size: CGFloat) {
        // 清理掉旧的image, 否则复用的话会有问题
        nameImageView.image = nil
        imageView.image = nil
        imageView.clearsContextBeforeDrawing = true
        imageView.layer.cornerRadius = size / 2.0

        func setBgImage() {
            let avatarImage = AvatarView.generateAvatarImage(withNameString: avatar.userName.abbreviation())
            self.nameImageView.image = avatarImage
            self.insertSubview(self.nameImageView, aboveSubview: imageView)
            imageView.image = nil
        }
        if avatar.avatarKey.isEmpty {
            setBgImage()
        } else {
            var identifier = avatar.identifier
            if identifier == "0" {
                assertionFailure("identifier 不能为 0")
                // 兜底逻辑
                identifier = ""
            }
            imageView.setAvatarByIdentifier(identifier,
                                            avatarKey: avatar.avatarKey,
                                            avatarViewParams: .init(sizeType: .size(size), format: .webp),
                                            completion: { response in
                if case let .failure(_) = response {
                    // 兜底
                    setBgImage()
                }
            })
        }

    }

    lazy var nameImageView: UIImageView = {
        let imgView = UIImageView()
        self.addSubview(imgView)
        self.bringSubviewToFront(imgView)
        imgView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return imgView
    }()

    static func generateAvatarImage(withNameString string: String, round: Bool = true) -> UIImage? {
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.white
        attribute[NSAttributedString.Key.font] = UIFont.cd.mediumFont(ofSize: 20)
        let nameString = NSAttributedString(string: string, attributes: attribute)
        let stringSize = nameString.boundingRect(with: CGSize(width: 100.0, height: 100.0),
                                                 options: .usesLineFragmentOrigin,
                                                 context: nil)
        let padding: CGFloat = 10.0
        let width = max(stringSize.width, stringSize.height) + padding * 2
        let size = CGSize(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: round ? size.width / 2.0 : size.width)
        UIColor.ud.primaryContentDefault.setFill()
        path.fill()
        nameString.draw(at: CGPoint(x: (size.width - stringSize.width) / 2.0,
                                    y: (size.height - stringSize.height) / 2.0))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func generateGreyImage() -> UIImage? {
        let size = CGSize(width: 36, height: 36)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: size.width / 2.0)
        UIColor.ud.N50.setFill()
        path.fill()
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return self.frame.size
    }
}

/// 详情页使用的avatarView
final class EventDetailAvatarView: UIView {
    private lazy var dotView: UIImageView = {
        let dotView = UIImageView()

        return dotView
    }()
    private let avatarView = AvatarView()

    init() {
        super.init(frame: .zero)
        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(dotView)
        self.addSubview(dotView)
        dotView.snp.makeConstraints({ (make) in
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
            make.width.height.equalTo(14)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStatusImage(_ image: UIImage?) {
        dotView.image = image
    }

    func setAvatar(_ avatar: Avatar, with size: CGFloat) {
        avatarView.setAvatar(avatar, with: size)
    }

}

/// 忙闲页使用的AvatarView
final class FreeBusyAvatarView: UIView {

    private let avatarView = AvatarView()
    private let displaySize: CGSize
    var avatar: Avatar? {
        didSet {
            guard let avatar = avatar else {
                return
            }
            avatarView.setAvatar(avatar, with: displaySize.width)
        }
    }

    init(displaySize: CGSize) {
        self.displaySize = displaySize
        super.init(frame: .zero)

        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(iconWrapper)
        iconWrapper.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(2)
            make.centerX.equalTo(self.snp.right).offset(-6)
        }
        iconWrapper.addArrangedSubview(busyIcon)
        iconWrapper.addArrangedSubview(notWorkingIcon)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var busyIcon: UIView = {
        let view = getIconView(image: UDIcon.getIconByKeyNoLimitSize(.conflictColorful))
        view.isHidden = true
        return view
    }()

    private lazy var notWorkingIcon: UIView = {
        let view = getIconView(image: UDIcon.getIconByKeyNoLimitSize(.workTimeColorful))
        view.isHidden = true
        return view
    }()

    private lazy var iconWrapper: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = -4
        return stackView
    }()

    private lazy var coverView: UIView = {
        let width: CGFloat = 40.0
        let coverView = UIView()
        self.addSubview(coverView)
        coverView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        coverView.layer.cornerRadius = width / 2.0
        coverView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.setLeftOutlined).renderColor(with: .primaryOnPrimaryFill))
        coverView.addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.width.height.equalTo(24)
            make.center.equalToSuperview()
        })
        return coverView
    }()

    private func getIconView(image: UIImage) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.backgroundColor = UIColor.ud.bgBody
        view.snp.makeConstraints({ (make) in
            make.width.height.equalTo(16)
        })

        let icon = UIImageView(image: image.withRenderingMode(.alwaysOriginal))
        view.addSubview(icon)
        icon.snp.makeConstraints({ (make) in
            make.width.height.equalTo(14)
            make.center.equalToSuperview()
        })
        return view
    }

    func setCover(isHidden: Bool) {
        coverView.isHidden = isHidden
    }

    func setIconStatus(showBusyIcon: Bool, showNotWorkingIcon: Bool) {
        busyIcon.isHidden = !showBusyIcon
        notWorkingIcon.isHidden = !showNotWorkingIcon
    }
}

// 日程参与人审批页使用的avatarView
class AttendeeApproverAvatarView: UIView {
    private let avatarView = AvatarView()
    private let nameLabel = UILabel()

    var avatar: Avatar? {
        didSet {
            guard let avatar = avatar else { return }
            avatarView.setAvatar(avatar, with: 20)
            nameLabel.text = avatar.userName
        }
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = UDColor.udtokenTagNeutralBgNormal
        layer.cornerRadius = 12

        addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(2)
            make.size.equalTo(20)
        }

        nameLabel.font = UIFont.cd.font(ofSize: 14)
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(8)
            make.height.equalTo(22)
            make.centerY.equalTo(avatarView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate extension String {
    /// 获取缩写
    func abbreviation() -> String {
        let words = self.components(separatedBy: .whitespaces)

        guard words.count >= 2 else {
            return String(self.prefix(1).uppercased())
        }

        let firstWord = words[0]
        let lastWord = words[words.count - 1]

        let abbreviation = String(firstWord.prefix(1)).uppercased() + String(lastWord.prefix(1)).uppercased()

        return abbreviation
    }
}
