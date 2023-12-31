//
//  MeetingWindow.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all
class MeetingWindow: UIWindow {
    
    init(frame: CGRect, dismissWindowBlock: (()-> Void)?) {
        super.init(frame: frame)
        setup(dismissWindowBlock: dismissWindowBlock)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup(dismissWindowBlock: (()-> Void)? = nil) {
        windowLevel = UIWindow.Level.statusBar - 1
        let vc = MeetingVC()
        vc.dismissWindowBlock = dismissWindowBlock
        rootViewController = vc
        UIDevice.current.updateDeviceOrientation(.portrait, animated: false)
    }
}
