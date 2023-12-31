//
//  ParticipantImageView.swift
//  ByteView
//
//  Created by wulv on 2022/5/20.
//

import Foundation
import UniverseDesignIcon

typealias ParticipantImgKey = ParticipantImageView.ImageKey
extension ParticipantImageView {

    enum ImageKey: Equatable {
        case empty
        case mobileDevice
        case webDevice
        case videoOffDisabled
        case videoOff
        case video
        case share
        case conveniencePstn
        case disturbed
        case expandDownN1
        case expandDownN2
        case expandRightN2
        case handsUp(String?)
        case leave
        case systemCalling
        case localRecord
    }

    // ---- UDIcon 暂用静态变量保存 -----
    // 主端 UniverseDesign 库，在 iOS 14 上存在必现内存泄露，通过 UDIcon 等API 动态创建的支持深色模式的图片，都无法被释放
    static var VideoOffDisabledImg = UDIcon.getIconByKey(.videoOffFilled, iconColor: UIColor.ud.iconDisabled)
    static var VideoOffImg = UDIcon.getIconByKey(.videoOffFilled, iconColor: UIColor.ud.functionDangerContentDefault)
    static var VideoImg = UDIcon.getIconByKey(.videoFilled, iconColor: UIColor.ud.iconN3)
    static var PstnDeviceImg = UDIcon.getIconByKey(.officephoneFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20))
    static var webDeviceImg = UDIcon.getIconByKey(.winsFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
    static var ExpandDownImgN1 = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: 8, height: 8))
    static var ExpandDownImgN2 = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 12, height: 12))
    static var ExpandRightImgN2 = UDIcon.getIconByKey(.expandRightFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 12, height: 12))
    static var SystemCallingImg = Display.phone ? UDIcon.getIconByKey(.callSystemFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)) : UDIcon.getIconByKey(.callSystemFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20))
    static var LocalRecordImg = UDIcon.getIconByKey(.recordingColorful, iconColor: UIColor.ud.functionDangerFillDefault, size: CGSize(width: 20, height: 20))
    static var deniedImg = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 20, height: 20))

}

/// 图片基件
class ParticipantImageView: UIImageView {

    var key: ImageKey = .empty {
        didSet {
            if key != oldValue {
                updateImage(key)
            }
        }
    }

    private func updateImage(_ key: ImageKey) {
        switch key {
        case .empty:
            image = nil
        case .mobileDevice:
            image = UDIcon.getIconByKey(.cellphoneFilled, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        case .webDevice:
            image = ParticipantImageView.webDeviceImg
        case .videoOffDisabled:
            image = ParticipantImageView.VideoOffDisabledImg
        case .videoOff:
            image = ParticipantImageView.VideoOffImg
        case .video:
            image = ParticipantImageView.VideoImg
        case .share:
            image = UDIcon.getIconByKey(.shareScreenFilled, iconColor: .ud.functionSuccessFillDefault, size: CGSize(width: 20, height: 20))
        case .conveniencePstn:
            image = ParticipantImageView.PstnDeviceImg
        case .disturbed:
            image = BundleResources.ByteView.Participants.Dndisturbed
        case .expandDownN1:
            image = ParticipantImageView.ExpandDownImgN1
        case .expandDownN2:
            image = ParticipantImageView.ExpandDownImgN2
        case .expandRightN2:
            image = ParticipantImageView.ExpandRightImgN2
        case .handsUp(let handsUpEmojiKey):
            image = EmojiResources.getEmojiSkin(by: handsUpEmojiKey)
        case .leave:
            image = EmojiResources.emoji_quickleave
        case .systemCalling:
            image = ParticipantImageView.SystemCallingImg
        case .localRecord:
            image = ParticipantImageView.LocalRecordImg
        }
    }
}
