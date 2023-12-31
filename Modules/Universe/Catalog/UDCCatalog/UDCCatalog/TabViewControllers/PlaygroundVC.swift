//
//  UDTestDemoVC.swift
//  UDCCatalog
//
//  Created by Siegfried on 2021/9/23.
//  Copyright © 2021 姚启灏。All rights reserved.
//

import UIKit
import FigmaKit
import UniverseDesignButton
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignInput

// swiftlint:disable all

// MARK: - 在这里测试 UD 小组件，代码不要提交

class PlaygroundVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        testCode()
        setComponents()
        setConstraints()
        setAppearance()
    }

    private func setComponents() {

    }

    private func setConstraints() {

    }

    private func setAppearance() {
        view.backgroundColor = UIColor.ud.bgBase
    }

    private func testCode() {
        let testLabel = UILabel()
        testLabel.font = UIFont.systemFont(ofSize: 120)
        testLabel.text = "Try It"
        testLabel.textColor = UIColor.ud.textPlaceholder.withAlphaComponent(0.2)
        testLabel.textAlignment = .center
        view.addSubview(testLabel)
        testLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

// swiftlint:enable all
