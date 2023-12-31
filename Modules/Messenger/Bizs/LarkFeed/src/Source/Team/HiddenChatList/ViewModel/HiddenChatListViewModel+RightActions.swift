//
//  HiddenChatListViewModel+RightActions.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/19.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import RustPB
import LarkModel
import UniverseDesignToast

extension HiddenChatListViewModel {

    /// 隐藏群组
    func hideChat(_ cellViewModel: FeedTeamChatItemViewModel, on window: UIWindow?) {
        let feedPreview = cellViewModel.chatEntity
        let showState = !cellViewModel.chatItem.isHidden
        dependency.hideTeamChat(chatId: Int(cellViewModel.chatItem.id), isHidden: showState)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak window] _ in
                guard let window = window else { return }
                let message = showState ? BundleI18n.LarkFeed.Project_MV_GroupIsHidden
                : BundleI18n.LarkFeed.Project_MV_GroupIsShown
                UDToast.showSuccess(with: message, on: window)
            }, onError: { error in
                guard let window = window else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Legacy_ErrorMessageTip, on: window, error: error)
            }).disposed(by: disposeBag)
    }
}
