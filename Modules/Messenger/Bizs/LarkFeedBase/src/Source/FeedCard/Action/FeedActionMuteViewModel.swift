//
//  FeedActionMuteViewModel.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/9/5.
//

import LarkModel
import LarkOpenFeed
import RustPB
import UniverseDesignToast
import UniverseDesignIcon

public final class FeedActionMuteViewModel: FeedActionViewModelInterface {
    public let title: String
    public let contextMenuImage: UIImage
    public var swipeEditImage: UIImage?
    public var swipeBgColor: UIColor?
    let model: FeedActionModel
    public init(model: FeedActionModel) {
        self.model = model
        self.title = model.feedPreview.basicMeta.isRemind ?
                     BundleI18n.LarkFeedBase.Lark_Core_TouchAndHold_MuteChats_Button :
                     BundleI18n.LarkFeedBase.Lark_Core_TouchAndHold_UnmuteChats_Button
        self.contextMenuImage = model.feedPreview.basicMeta.isRemind ?
                                Resources.LarkFeedBase.pinNotifyClockClose :
                                Resources.LarkFeedBase.pinNotifyClock

        self.swipeEditImage = model.feedPreview.basicMeta.isRemind ?
                            Resources.LarkFeedBase.slideAlertsOffIcon :
                            Resources.LarkFeedBase.slideBellIcon
        self.swipeBgColor = UIColor.ud.colorfulIndigo
    }

    public func handleResultByDefault(error: Error?) {
        guard let window = model.fromVC?.view.window else { return }
        if error == nil {
            let message = model.feedPreview.basicMeta.isRemind ?
                        BundleI18n.LarkFeedBase.Lark_Core_TouchAndHold_MuteChats_MutedToast :
                        BundleI18n.LarkFeedBase.Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast
            UDToast.showTips(with: message, on: window)
        } else {
            // TODO: open feed 不能对 APIError
//            guard let apiError = error?.underlyingError as? APIError else { return }
//            let message = model.feedPreview.basicMeta.isRemind ?
//                        BundleI18n.LarkFeedBase.Lark_Core_UnableToMuteNotificationsTryLater_Toast :
//                        BundleI18n.LarkFeedBase.Lark_Core_UnableToUnmuteNotificationsTryLater_Toast
//            UDToast.showFailure(with: message, on: window, error: apiError)
        }
    }
}
