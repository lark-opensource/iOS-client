//
//  SetupKeyboardTask.swift
//  LarkMessenger
//
//  Created by KT on 2020/7/2.
//

import UIKit
import Foundation
import BootManager
import LarkContainer
import LarkKeyboardKit
import LarkKeyCommandKit
import LKCommonsTracker
import Homeric
import RxSwift

private var needUploadIPadDeviceInfo: Bool = true

private var iPadDeviceInfoDisposeBag = DisposeBag()

private var iPadDeviceInfoObserve: NSObjectProtocol?

final class NewSetupKeyboardTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupKeyboardTask"
    //懒加载task
    override var isLazyTask: Bool { return true }
    override func execute(_ context: BootContext) {
        // start keyboard kit observe
        KeyboardKit.shared.start()

        // add global keyCommand
        KeyCommandKit.addCloseKeyCommands()

        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        /// 上传 iPad 屏幕使用状况
        iPadDeviceInfoObserve = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil) { (_) in
                needUploadIPadDeviceInfo = true

                let isSceneSplit: Bool
                let isSceneSlideOver: Bool
                if #available(iOS 13.0, *), let scene = UIApplication.shared.connectedScenes.first(where: {
                    $0 is UIWindowScene
                }) as? UIWindowScene {
                    isSceneSplit = scene.coordinateSpace.bounds.size != scene.screen.bounds.size
                    isSceneSlideOver = scene.coordinateSpace.bounds.height < scene.screen.bounds.height
                } else if let ow = UIApplication.shared.delegate?.window, let window = ow {
                    isSceneSplit = window.bounds.size != window.screen.bounds.size
                    isSceneSlideOver = window.bounds.height < window.screen.bounds.height
                } else {
                    return
                }
                let screenSize = UIScreen.main.bounds.size
                let scale = UIScreen.main.scale
                let resolution = "\(Int(max(screenSize.width, screenSize.height) * scale))*\(Int(min(screenSize.width, screenSize.height) * scale))"
                let direction = screenSize.width > screenSize.height ? "landscape" : "portrait"
                let isSplit = isSceneSplit ? "y" : "n"
                let isSlidOver = isSceneSlideOver ? "y" : "n"
                Tracker.post(TeaEvent(Homeric.IPAD_DEVICE, params: [
                    "resolution": resolution,
                    "screen_direction": direction,
                    "is_split_view": isSplit,
                    "is_slide_over": isSlidOver
                ]))
        }

        /// 上传 iPad 是否接入了外接键盘
        KeyboardKit.shared.keyboardChange.drive(onNext: { (keyboard) in
            guard let keyboard = keyboard else { return }
            guard needUploadIPadDeviceInfo else { return }
            needUploadIPadDeviceInfo = false

            if keyboard.type == .hardware {
                Tracker.post(TeaEvent(Homeric.IPAD_DEVICE, params: ["device": "keyboard"]))
            }
        }).disposed(by: iPadDeviceInfoDisposeBag)
    }
}
