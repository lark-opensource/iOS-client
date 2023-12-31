//
//  AuroraAnimationController.swift
//  UDCCatalog
//
//  Created by Hayden on 30/10/2023.
//  Copyright © 2023 姚启灏. All rights reserved.
//

import UIKit
import FigmaKit
import UniverseDesignButton
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignInput

// swiftlint:disable all

class AuroraAnimationController: UIViewController {

    private var auroraView = AuroraView()

    private lazy var animatedButton: UIButton = {
        let button = UDButton(.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("Animate!", for: .normal)
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(animated), for: .touchUpInside)
        return button
    }()

    //    override func loadView() {
    //        view = auroraView
    //    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setComponents()
        setConstraints()
        setAppearance()
    }

    private func setComponents() {
        view.addSubview(auroraView)
        view.addSubview(animatedButton)
    }

    private func setConstraints() {
        auroraView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalTo(animatedButton)
            make.bottom.equalTo(animatedButton.snp.top).offset(-16)
        }
        animatedButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
            make.height.equalTo(50)
        }
    }

    private func setAppearance() {
        view.backgroundColor = UIColor.ud.bgBase
        auroraView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        auroraView.layer.borderWidth = 2
        auroraView.layer.cornerRadius = 6
        auroraView.blobsOpacity = 1.0
        auroraView.headColor = UIColor.ud.bgBody
        auroraView.headOpacity = 0.6
        auroraView.backgroundColor = UIColor.ud.bgBody
        auroraView.updateAppearance(with: getCurrentAuroraConfig(), animated: false)
    }

    @objc
    private func animated() {
        auroraView.updateAppearance(with: getCurrentAuroraConfig(), animated: true, duration: 1)
    }

    func getCurrentAuroraConfig() -> AuroraViewConfiguration {
        let config = auroraConfigs[currentConfigIndex % auroraConfigs.count]
        currentConfigIndex += 1
        return config
    }

    let auroraConfigs: [AuroraViewConfiguration] = [
        AuroraViewConfiguration(
            mainBlob: .init(
                color: .systemRed,
                position: .init(absoluteLeft: -30, top: -44, width: 116, height: 117),
                opacity: 0.3,
                blurRadius: 80),
            subBlob: .init(
                color: .systemOrange,
                position: .init(absoluteLeft: -16, top: -112, width: 198, height: 198),
                opacity: 0.3,
                blurRadius: 80),
            reflectionBlob: .init(
                color: .systemYellow,
                position: .init(absoluteLeft: 83, top: -83, width: 168, height: 137),
                opacity: 0.3,
                blurRadius: 80)
        ), AuroraViewConfiguration(
            mainBlob: .init(
                color: .systemPurple,
                position: .init(absoluteLeft: -74, top: -51, width: 192, height: 176),
                opacity: 0.3,
                blurRadius: 80),
            subBlob: .init(
                color: .systemBlue,
                position: .init(absoluteLeft: -60, top: -181, width: 325, height: 306),
                opacity: 0.3,
                blurRadius: 80),
            reflectionBlob: .init(
                color: .systemGreen,
                position: .init(absoluteLeft: 116, top: -102, width: 283, height: 228),
                opacity: 0.3,
                blurRadius: 80)
        )
    ]

    var currentConfigIndex: Int = 0
}

// swiftlint:enable all
