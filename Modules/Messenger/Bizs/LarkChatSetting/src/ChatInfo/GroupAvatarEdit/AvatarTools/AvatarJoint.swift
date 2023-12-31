//
//  AvatarJoint.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation
import LarkBizAvatar
import UniverseDesignColor
import LKCommonsLogging
import ByteWebImage
import RustPB

final class AvatarJointService {
    private static let logger = Logger.log(AvatarJointService.self, category: "LarkSetting.AvatarJointService")
    static let maxAvatarCount: Int = 7
    struct AvatarImageLayout {
        var xCoordinate: CGFloat
        var yCoordinate: CGFloat
        var radius: CGFloat
    }

    /// 头像拼接规则：给定每种场景下每个子头像的位置和大小信息
    // disable-lint: magic_number
    static let avatarJointLayoutInfo: [[AvatarImageLayout]] = [
        [AvatarImageLayout(xCoordinate: 0.5, yCoordinate: 0.5, radius: 0.5)],
        [
            AvatarImageLayout(xCoordinate: (44 - sqrt(2) * 19) / 80, yCoordinate: (44 - sqrt(2) * 19) / 80, radius: 9.0 / 20.0),
            AvatarImageLayout(xCoordinate: (44 + sqrt(2) * 19) / 80, yCoordinate: (44 + sqrt(2) * 19) / 80, radius: 9.0 / 20.0)
        ],
        [
            AvatarImageLayout(xCoordinate: 7.0 / 12, yCoordinate: 1.0 / 18, radius: 5.0 / 12),
            AvatarImageLayout(xCoordinate: (42 + sqrt(3) * 19) / 72, yCoordinate: 61.0 / 72, radius: 5.0 / 12),
            AvatarImageLayout(xCoordinate: (42 - sqrt(3) * 19) / 72, yCoordinate: 61.0 / 72, radius: 5.0 / 12)
        ],
        [
            AvatarImageLayout(xCoordinate: 9.0 / 40, yCoordinate: 9.0 / 40, radius: 3.0 / 8),
            AvatarImageLayout(xCoordinate: 41.0 / 40, yCoordinate: 9.0 / 40, radius: 3.0 / 8),
            AvatarImageLayout(xCoordinate: 41.0 / 40, yCoordinate: 41.0 / 40, radius: 3.0 / 8),
            AvatarImageLayout(xCoordinate: 9.0 / 40, yCoordinate: 41.0 / 40, radius: 3.0 / 8)
        ],
        [
            AvatarImageLayout(xCoordinate: 2.0 / 3, yCoordinate: 1.0 / 18, radius: 1.0 / 3),
            AvatarImageLayout(xCoordinate: (2.0 / 3 + 11.0 / 18 * cos(0.1 * Double.pi)), yCoordinate: (2.0 / 3 - 11.0 / 18 * sin(0.1 * Double.pi)), radius: 1.0 / 3),
            AvatarImageLayout(xCoordinate: (2.0 / 3 + 11.0 / 18 * sin(0.2 * Double.pi)), yCoordinate: (2.0 / 3 + 11.0 / 18 * cos(0.2 * Double.pi)), radius: 1.0 / 3),
            AvatarImageLayout(xCoordinate: (2.0 / 3 - 11.0 / 18 * sin(0.2 * Double.pi)), yCoordinate: (2.0 / 3 + 11.0 / 18 * cos(0.2 * Double.pi)), radius: 1.0 / 3),
            AvatarImageLayout(xCoordinate: (2.0 / 3 - 11.0 / 18 * cos(0.1 * Double.pi)), yCoordinate: (2.0 / 3 - 11.0 / 18 * sin(0.1 * Double.pi)), radius: 1.0 / 3)
        ],
        [
            AvatarImageLayout(xCoordinate: 25.0 / 36, yCoordinate: 1.0 / 18, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: (25.0 / 36 + 23.0 / 36 * cos(0.1 * Double.pi)), yCoordinate: (25.0 / 36 - 23.0 / 36 * sin(0.1 * Double.pi)), radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: (25.0 / 36 + 23.0 / 36 * sin(0.2 * Double.pi)), yCoordinate: (25.0 / 36 + 23.0 / 36 * cos(0.2 * Double.pi)), radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: (25.0 / 36 - 23.0 / 36 * sin(0.2 * Double.pi)), yCoordinate: (25.0 / 36 + 23.0 / 36 * cos(0.2 * Double.pi)), radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: (25.0 / 36 - 23.0 / 36 * cos(0.1 * Double.pi)), yCoordinate: (25.0 / 36 - 23.0 / 36 * sin(0.1 * Double.pi)), radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 25.0 / 36, yCoordinate: 25.0 / 36, radius: 11.0 / 36)
        ],
        [
            AvatarImageLayout(xCoordinate: 3.0 / 8, yCoordinate: (50 - 23 * sqrt(3)) / 72, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 73.0 / 72, yCoordinate: (50 - 23 * sqrt(3)) / 72, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 4.0 / 3, yCoordinate: 25.0 / 36, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 73.0 / 72, yCoordinate: (50 + 23 * sqrt(3)) / 72, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 3.0 / 8, yCoordinate: (50 + 23 * sqrt(3)) / 72, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 1.0 / 18, yCoordinate: 25.0 / 36, radius: 11.0 / 36),
            AvatarImageLayout(xCoordinate: 25.0 / 36, yCoordinate: 25.0 / 36, radius: 11.0 / 36)
        ]
    ]
    // enable-lint: magic_number

    static func getAvatarImage(frame: CGRect, entityID: String, avatarKey: String, completion: @escaping (UIImage) -> Void) {
        let avatarResource: LarkImageResource = .avatar(key: avatarKey, entityID: entityID)
        LarkImageService.shared.setImage(with: avatarResource, completion: { imageResult in
            switch imageResult {
            case .success(let result):
                completion(result.image ?? Self.getDefaultImage())
                Self.logger.info("get avatar image success, key: \(avatarKey)")
            case .failure(_):
                completion(Self.getDefaultImage())
                Self.logger.error("get avatar image failed, key: \(avatarKey), entityID: \(entityID)")
            }
        })
    }

    static func setupImage(avatars: [UIImage], frameSize: CGSize) -> UIImage? {
        // 数组越界保护
        guard !avatars.isEmpty, frameSize.width > 0, frameSize.height > 0 else {
            return nil
        }

        let filterAvatars = avatars.count > Self.maxAvatarCount ? Array(avatars.prefix(Self.maxAvatarCount)) : avatars
        let layoutInfo = AvatarJointService.avatarJointLayoutInfo[filterAvatars.count - 1]
        let renderer = UIGraphicsImageRenderer(size: frameSize)

        let combinedImage = renderer.image { context in
            // 底色 #9F9F9F
            let backgroundColor = UDColor.rgb(0x9F9F9F).withAlphaComponent(0.15)
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: frameSize))

            for (index, avatar) in filterAvatars.enumerated() {
                // 拼接的子图
                let circularImage = AvatarJointService.cropToCircle(avatar)
                let r = min(frameSize.height, frameSize.width) / 2
                let radius = layoutInfo[index].radius * r
                circularImage?.draw(in: CGRect(x: layoutInfo[index].xCoordinate * r, y: layoutInfo[index].yCoordinate * r, width: radius * 2, height: radius * 2))
            }
        }
        // 返回拼接后的图片
        return combinedImage
    }

    /// 渲染为圆形
    static func cropToCircle(_ avatarView: UIImage) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: avatarView.size)
        let circularImage = renderer.image { _ in
            let bounds = CGRect(x: 0, y: 0, width: avatarView.size.width, height: avatarView.size.height)
            UIBezierPath(roundedRect: bounds, cornerRadius: avatarView.size.width / 2).addClip()
            avatarView.draw(in: bounds)
        }

        return circularImage
    }

    /// 返回值 icon和底色比例为1:2的兜底图
    static func getDefaultImage() -> UIImage {
        let image = Resources.defaultAvatar
        let newSize = CGSize(width: image.size.width * 2.0, height: image.size.height * 2.0)

        let renderer = UIGraphicsImageRenderer(size: newSize)

        let newImage = renderer.image { context in
            let backgroundColor = UDColor.rgb(0x8F959E)
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: newSize))

            // 缩放并绘制图像a
            let scaledRect = CGRect(x: image.size.width * 0.5, y: image.size.width * 0.5, width: newSize.width * 0.5, height: newSize.height * 0.5)
            image.draw(in: scaledRect)
        }

        return newImage
    }
}
