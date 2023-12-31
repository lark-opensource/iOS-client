//
//  GroupAvatarView.swift
//  LarkChatSetting
//
//  Created by kangsiwan on 2020/4/17.
//

import Foundation
import UIKit
import LarkExtensions
import LarkCore
import LarkBizAvatar
import AvatarComponent
import LarkMessengerInterface

/// 头像设置类型
enum AvatarSetType {
    /// 设置群头像
    case avatarKey(entityId: String, key: String)
    /// 设置图片
    case image(image: UIImage)
    /// 设置文本+颜色，文本总字符数不超过8&清除了前后空格
    case text(text: String, textColor: UIColor, borderColor: UIColor, backgroundColor: UIColor? = nil)
    /// 设置图片+颜色
    case imageColor(image: UIImage,
                    contentMode: UIView.ContentMode = .center,
                    color: UIColor,
                    backgroundColor: UIColor? = nil)
}

/// 展示群头像
final class GroupAvatarView: UIView {
    /// 展示头像
    private let imageView = BizAvatar()
    private let avatarSize: CGFloat = 96
    var avatarSetType: AvatarSetType?
    /// 相机按钮
    private var cameraButton = UIButton(type: .custom)
    /// 展示文字
    private var avatarLabel = UILabel()
    /// 拍照icon被点击
    var cameraButtonClick: ((_ sender: UIView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        // 展示头像
        imageView.setAvatarUIConfig(AvatarComponentUIConfig(backgroundColor: UIColor.ud.primaryOnPrimaryFill))
        imageView.lastingColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5)
        imageView.avatar.layer.masksToBounds = true
        imageView.avatar.layer.borderColor = UIColor.clear.cgColor
        imageView.avatar.layer.borderWidth = 3
        imageView.avatar.ud.removeMaskView()
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(tapAvatarImageView)))
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(20)
            maker.bottom.equalTo(-26)
            maker.height.width.equalTo(avatarSize)
        }
        // 展示文字
        imageView.addSubview(avatarLabel)
        avatarLabel.textAlignment = .center
        avatarLabel.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        // 相机按钮
        self.addSubview(cameraButton)
        cameraButton.setImage(Resources.icon_camera, for: .normal)
        cameraButton.layer.masksToBounds = true
        cameraButton.layer.cornerRadius = 18.5
        cameraButton.addTarget(self, action: #selector(buttonCliek(sender:)), for: .touchUpInside)
        cameraButton.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(37)
            maker.right.equalTo(imageView).offset(4)
            maker.bottom.equalToSuperview().offset(-23.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapAvatarImageView() {
        self.cameraButtonClick?(imageView)
    }

    @objc
    private func buttonCliek(sender: UIView) {
        self.cameraButtonClick?(sender)
    }

    /// 展示指定文字
    private func setTextInAvatar(string: String) {
        let newString = string.replacingOccurrences(of: "\n", with: "")
        // 总字符数，中文/日文占两个字符，其他占一个
        var countOfChar: Int = 0
        // 插入换行符的位置，-1表示不需要换行
        var indexOfInsert = -1
        // 中文/日文/表情算2字符长度，其他算1字符长度
        for (index, item) in newString.enumerated() {
            if item.isChinese() || item.isJapanese() || item.isEmoji() {
                countOfChar += 2
            } else {
                countOfChar += 1
            }
            // 第一行只显示4个字符长度，其余内容放在第二行
            if countOfChar > 4, indexOfInsert == -1 {
                indexOfInsert = index
            }
        }
        // 获取当前字符数对应的字体大小
        avatarLabel.font = self.getFontForCharCount(count: countOfChar)
        // 不需要换行则直接显示，否则需要插入换行符
        if indexOfInsert == -1 {
            avatarLabel.text = newString
            avatarLabel.numberOfLines = 1
        } else {
            var str = newString
            // 插入换行符，让内容展示成两行
            str.insert("\n", at: str.index(str.startIndex, offsetBy: indexOfInsert))
            avatarLabel.text = str
            avatarLabel.numberOfLines = 2
            }
    }

    /// 获取当前字符数对应的字体大小
    private func getFontForCharCount(count: Int) -> UIFont {
        var sizeOfLabelText = 0
        switch count {
        case 1:
            sizeOfLabelText = 54
        case 2:
            sizeOfLabelText = 42
        case 3...4:
            sizeOfLabelText = 34
        case 5...8:
            sizeOfLabelText = 28
        default:
            sizeOfLabelText = 28
        }
        // 字号加粗
        return UIFont.boldSystemFont(ofSize: CGFloat(sizeOfLabelText))
    }
}

/// 对外提供的接口
extension GroupAvatarView {
    /// 提供当前定制的群头像，可能比较耗时，调用方应在子线程调用
    func getAvatarImage() -> UIImage {
        if case .image(let image) = avatarSetType {
            return image // 如果是用户上传的照片，原尺寸返回，保证清晰度，对齐安卓
        } else {
            return self.imageView.lu.screenshot() ?? UIImage()
        }
    }

    /// 设置当前头像
    func setAvatar(type: AvatarSetType) {
        self.avatarSetType = type
        var config = AvatarComponentUIConfig(backgroundColor: UIColor.ud.primaryOnPrimaryFill)
        switch type {
        case .avatarKey(let entityId, let key):
            config.contentMode = .scaleAspectFill
            self.imageView.setAvatarByIdentifier(entityId, avatarKey: key, avatarViewParams: .init(sizeType: .size(avatarSize)))
            self.imageView.avatar.layer.borderColor = UIColor.clear.cgColor
            self.avatarLabel.text = ""
        case .image(let image):
            config.contentMode = .scaleAspectFill
            self.imageView.image = image
            self.imageView.avatar.layer.borderColor = UIColor.clear.cgColor
            self.avatarLabel.text = ""
        case .text(let text, let textColor, let borderColor, let backgroundColor):
            config.contentMode = .center
            config.backgroundColor = backgroundColor ?? UIColor.ud.primaryOnPrimaryFill
            self.imageView.avatar.layer.borderColor = borderColor.cgColor
            self.imageView.setAvatarByIdentifier("", avatarKey: "")
            self.imageView.image = nil
            self.avatarLabel.textColor = textColor
            // 展示指定文字
            self.setTextInAvatar(string: text)
        case .imageColor(let image, let contentMode, let color, let backgroundColor):
            config.contentMode = contentMode
            config.backgroundColor = backgroundColor ?? UIColor.ud.primaryOnPrimaryFill
            self.imageView.image = image
            self.imageView.avatar.layer.borderColor = color.cgColor
            self.avatarLabel.text = ""
        }
        self.imageView.setAvatarUIConfig(config)
    }
}
