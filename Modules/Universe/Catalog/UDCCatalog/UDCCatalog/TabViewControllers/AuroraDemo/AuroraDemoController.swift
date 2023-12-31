//
//  AuroraDemoController.swift
//  UDCCatalog
//
//  Created by Hayden on 8/10/2023.
//  Copyright © 2023 姚启灏. All rights reserved.
//

import UIKit
import FigmaKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignInput

// swiftlint:disable all

class AuroraDemoController: UIViewController {

    private lazy var auroraTypeSwitch: UISegmentedControl = {
        let control = UISegmentedControl(items: ["System Blur", "Gradient Color"])
        control.selectedSegmentIndex = 0
        return control
    }()

    private lazy var previewButton: FKGradientButton = {
        let button = FKGradientButton()
        button.setTitle("Preview", for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        button.colorStyle = .solidGradient(
            background: UDColor.AIPrimaryFillDefault,
            highlightedBackground: UDColor.AIPrimaryFillPressed,
            disabledBackground: UDColor.AIPrimaryFillLoading
        )
        return button
    }()

    private lazy var previewAnimateButton: FKGradientButton = {
        let button = FKGradientButton()
        button.setTitle("Animation", for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        button.colorStyle = .solidGradient(
            background: UDColor.AIPrimaryFillDefault,
            highlightedBackground: UDColor.AIPrimaryFillPressed,
            disabledBackground: UDColor.AIPrimaryFillLoading
        )
        return button
    }()

    private lazy var resetButton: FKGradientButton = {
        let button = FKGradientButton()
        button.setTitle("重置", for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        button.colorStyle = .solidGradient(
            background: UDColor.gradientRed
        )
        return button
    }()

    private lazy var textView: UDMultilineTextField = {
        let textField = UDMultilineTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = UIColor.ud.bgFiller
        textField.config.font = UIFont(name: "Menlo", size: 14)
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setComponents()
        setConstraints()
        setAppearance()
    }

    private func setComponents() {
        view.addSubview(auroraTypeSwitch)
        view.addSubview(previewButton)
        view.addSubview(previewAnimateButton)
        view.addSubview(resetButton)
        view.addSubview(textView)
    }

    private func setConstraints() {

        auroraTypeSwitch.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(textView.snp.top).offset(-16)
        }

        previewButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            if #available(iOS 15.0, *) {
                make.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-16)
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-16)
            }
            make.height.equalTo(50)
        }
        previewAnimateButton.snp.makeConstraints { make in
            make.left.equalTo(previewButton.snp.right).offset(8)
            make.height.bottom.equalTo(previewButton)
            make.width.equalTo(previewButton)
        }
        resetButton.snp.makeConstraints { make in
            make.left.equalTo(previewAnimateButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.bottom.height.equalTo(previewButton)
            make.width.equalTo(50)
        }
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(previewButton.snp.top).offset(-16)
            make.height.equalTo(360)
        }
    }

    private func setAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.previewButton.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)
        self.previewAnimateButton.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)
        self.resetButton.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapBackground)))
        resetJsonString()
    }

    @objc
    func click(_ sender: UIButton) {
        if sender === previewButton {
            showAuroraPreviewController()
        } else if sender === previewAnimateButton {
            showAuroraAnimationController()
        } else if sender === resetButton {
            resetJsonString()
        }
    }

    @objc
    func tapBackground() {
        let _ = textView.resignFirstResponder()
    }

    private func showAuroraPreviewController() {
        let jsonString = textView.text!
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        // 解析JSON字符串为AuroraViewConfig实例
        do {
            let value = try decoder.decode(AuroraDemoViewConfig.self, from: jsonData)
//            auroraView.updateAppearance(with: auroraConfig, duration: 0.5)
            textView.setStatus(.normal)

            let newConfig = AuroraViewConfiguration(
                mainBlob: .init(
                    color: value.mainBlob.color,
                    frame: value.mainBlob.frame,
                    opacity: value.mainBlob.opacity,
                    blurRadius: value.blurRadius),
                subBlob: .init(
                    color: value.subBlob.color,
                    frame: value.subBlob.frame,
                    opacity: value.subBlob.opacity,
                    blurRadius: value.blurRadius),
                reflectionBlob: .init(
                    color: value.reflectionBlob.color,
                    frame: value.reflectionBlob.frame,
                    opacity: value.reflectionBlob.opacity,
                    blurRadius: value.blurRadius)
            )
            let auroraVC = AuroraPreviewController(auroraConfig: newConfig,
                                                   useGradient: auroraTypeSwitch.selectedSegmentIndex == 1,
                                                   blobOpacity: value.blobOpacity,
                                                   backgroundColor: value.backgroundColor,
                                                   blurRadius: value.blurRadius
            )
            auroraVC.modalPresentationStyle = .fullScreen
            present(auroraVC, animated: true)
        } catch {
            textView.config.errorMessege = "Invalid JSON"
            textView.setStatus(.error)
        }
    }

    private func showAuroraAnimationController() {
        let animationVC = AuroraAnimationController()
        navigationController?.pushViewController(animationVC, animated: true)
    }

    private func resetJsonString() {
        textView.text = """
        {
            "mainBlob": {
                "color": "B600",
                "frame": [-80, -59, 150, 150],
                "opacity": 0.15
            },
            "subBlob": {
                "color": "B500",
                "frame": [-17, -126, 228, 220],
                "opacity": 0.15
            },
            "reflectionBlob": {
                "color": "T350",
                "frame": [150, -65, 145, 140],
                "opacity": 0.1
            },
            "backgroundColor": "N00",
            "blurRadius": 80,
            "blobOpacity": 1.0
        }
        """
        textView.config.errorMessege = nil
        textView.setStatus(.normal)
    }
}

// swiftlint:enable all
