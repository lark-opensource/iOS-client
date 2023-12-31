//
//  PushMultiNetChangedHandler.swift
//  LarkMine
//
//  Created by huanglx on 2022/1/5.
//

import UIKit
import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import UniverseDesignToast
import Swinject
#if ByteViewMod
import ByteViewInterface
#endif

///检测wifi切4g push
final class PushMultiNetChangedHandler: UserPushHandler {

    var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
    //是否视频会议
    var isMetting: Bool {
        #if ByteViewMod
        let service = try? self.userResolver.resolve(assert: MeetingService.self)
        return service?.currentMeeting?.isActive == true
        #else
        return false
        #endif
    }
    func process(push message: RustPB.Tool_V1_PushMultiNetChanged) throws {
        if message.state == .wifiWithCellularTransData {
            //在非视频会议时切换弹toast
            if let keyWindow = self.keyWindow, !isMetting {
                DispatchQueue.main.async {
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Core_WifiWeakSwitchedToCellular_Toast, on: keyWindow)
                }
            }
        }
    }
}
