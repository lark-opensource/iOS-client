//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkAudioView

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow.init()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)

        let audioView = AudioView(frame: CGRect(x: 100, y: 200, width: 200, height: 60))
        audioView.colorConfig = AudioView.ColorConfig(
            panColorConfig: AudioView.PanColorConfig(
                background: UIColor.ud.N00,
                readyBorder: nil,
                playBorder: nil
            ),
            stateColorConfig: AudioView.StateColorConfig(
                background: UIColor.ud.N00,
                foreground: UIColor.ud.B700
            ),
            background: UIColor.white,
            lineBackground: UIColor.ud.B700.withAlphaComponent(0.3),
            processLineBackground: UIColor.ud.B700,
            timeLabelText: UIColor.ud.B700,
            invalidTimeLabelText: nil
        )

        self.window?.rootViewController?.view.addSubview(audioView)
        self.window?.rootViewController?.view.backgroundColor = UIColor.black
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
