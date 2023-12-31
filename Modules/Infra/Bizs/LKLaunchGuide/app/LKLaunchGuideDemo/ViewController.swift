//
//  ViewController.swift
//  LKLaunchGuideDemo
//
//  Created by Yuri on 2023/8/21.
//

import UIKit
@testable import LKLaunchGuide
import SnapKit
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let isDark = self.traitCollection.userInterfaceStyle == .dark
        let guideView = LaunchNewGuideView(frame: .zero, isLark: true, isDark: isDark)
        view.addSubview(guideView)
        guideView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        // Do any additional setup after loading the view.
    }

}

