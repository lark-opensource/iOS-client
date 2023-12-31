//
//  MagicShareDirectionViewModel.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/8/1.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewCommon

class MagicShareDirectionViewModel {

    /// 方向枚举，其中.free为无箭头背景
    enum Direction {
        case top
        case bottom
        case left
        case right
        case free
    }

    let tapPresenterIconAction: CocoaAction
    let avatarInfoObservable: Observable<AvatarInfo>
    let directionObservable: Observable<Direction>
    let isRemoteEqualLocalObservable: Observable<Bool>

    init(tapPresenterIconAction: CocoaAction,
         avatarInfoObservable: Observable<AvatarInfo>,
         directionObservable: Observable<Direction>,
         isRemoteEqualLocalObservable: Observable<Bool>) {
        self.tapPresenterIconAction = tapPresenterIconAction
        self.avatarInfoObservable = avatarInfoObservable
        self.directionObservable = directionObservable
        self.isRemoteEqualLocalObservable = isRemoteEqualLocalObservable
    }

}
