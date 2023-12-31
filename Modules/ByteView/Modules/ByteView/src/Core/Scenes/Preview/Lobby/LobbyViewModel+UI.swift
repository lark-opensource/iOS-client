//
//  LobbyViewModel+UI.swift
//  ByteView
//
//  Created by Prontera on 2020/6/29.
//

import Foundation
import RxSwift
import RxCocoa
import AVFoundation
import UniverseDesignIcon
import ByteViewCommon

extension LobbyViewModel {
    var microphoneImage: Driver<UIImage?> {
        Observable.combineLatest(isMicrophoneMuted,
                                 Privacy.micAccess,
                                 joinTogetherRoomRelay.asObservable(),
                                 isPadMicSpeakerDisabled.asObservable())
        .map { [weak self] isMuted, authorize, room, micDisabled -> UIImage? in
            if room != nil {
                return BundleResources.ByteView.JoinRoom.room_mic_on.withRenderingMode(.alwaysTemplate)
            } else if self?.audioMode == .noConnect {
                return UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 22, height: 22))
            } else if !authorize.isAuthorized || micDisabled {
                return UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 22, height: 22))
            } else if isMuted {
                return UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 22, height: 22))
            } else {
                let color = Display.phone ? UIColor.ud.iconN1 : UIColor.ud.iconN2
                return UDIcon.getIconByKey(.micFilled, iconColor: color, size: CGSize(width: 22, height: 22))
            }
        }.asDriver(onErrorRecover: { _ in .empty() })
    }

    var cameraImage: Driver<UIImage?> {
        return Observable.combineLatest(isCameraMutedObservable, Privacy.cameraAccess)
            .map({ cameraMuted, authorize -> UIImage? in
                if cameraMuted {
                    if !authorize.isAuthorized {
                        return UDIcon.getIconByKey(.videoOffFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 22, height: 22))
                    } else {
                        return UDIcon.getIconByKey(.videoOffFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 22, height: 22))
                    }
                } else {
                    let color = Display.phone ? UIColor.ud.iconN1 : UIColor.ud.iconN2
                    return UDIcon.getIconByKey(.videoFilled, iconColor: color, size: CGSize(width: 22, height: 22))
                }
            })
            .asDriver(onErrorRecover: { _ in return .empty() })
    }

    var warningImage: Driver<UIImage?> {
        return Driver.just(BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: CGSize(width: 16, height: 16)))
    }

    var avatarInfo: Driver<AvatarInfo> {
        return caller.map { $0.avatarInfo }
            .asDriver(onErrorRecover: { _ in return .empty() })
    }
}
