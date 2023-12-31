//
//  UniverseDesignButtonVC.swift
//  UDCCatalog
//
//  Created by Siegfried on 2021/9/23.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignSwitch
import UniverseDesignFont
import UniverseDesignButton
import UniverseDesignIcon

class UniverseDesignButtonVC: UIViewController {

    var config: UDButtonUIConifg = UDButtonUIConifg.primaryBlue
    var button = UDButton(UDButtonUIConifg.primaryBlue)
    var iconButton = UDButton(UDButtonUIConifg.primaryBlue)
    var type: UDButtonUIConifg.ButtonType = .small
    var isButtonEnabled: Bool = true
    var isButtonLoading: Bool = false
    var isButtonRadius: Bool = false
    var buttonType: ButtonType = .basic
    var iconColorType: iconColorType = .primaryOnPrimaryFill
    var iconImage: UIImage = UDIcon.imageOutlined

    /// 基础按钮
    private lazy var sizeControl:UISegmentedControl = UISegmentedControl()
    private lazy var loadingLabel: UILabel = createTitleLabel("加载:   ")
    private lazy var loadingSwitch: UISwitch = UISwitch()
    private lazy var colorControl: UISegmentedControl = UISegmentedControl()
    private lazy var disabledLabel: UILabel = createTitleLabel("禁用:   ")
    private lazy var disabledSwitch: UISwitch = UISwitch()
    private lazy var typeControl: UISegmentedControl = UISegmentedControl()
    private lazy var roundLabel: UILabel = createTitleLabel("圆角:   ")
    private lazy var roundSwitch: UISwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        setComponents()
        setConstraints()
        setAppearance()
    }

    private func setComponents() {
        self.view.addSubview(sizeControl)
        self.view.addSubview(colorControl)
        self.view.addSubview(typeControl)
        self.view.addSubview(loadingLabel)
        self.view.addSubview(disabledLabel)
        self.view.addSubview(roundLabel)
        self.view.addSubview(loadingSwitch)
        self.view.addSubview(disabledSwitch)
        self.view.addSubview(roundSwitch)
        self.view.addSubview(self.button)
        self.view.addSubview(self.iconButton)
    }

    private func setConstraints() {

        sizeControl.snp.makeConstraints { make in
            make.height.equalTo(BtnCons.SegmHeight)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(BtnCons.defaultPadding)
            make.left.equalToSuperview().offset(BtnCons.defaultPadding)
        }

        typeControl.snp.makeConstraints { make in
            make.height.equalTo(BtnCons.SegmHeight)
            make.top.equalTo(sizeControl.snp.bottom).offset(BtnCons.largePadding)
            make.left.equalToSuperview().offset(BtnCons.defaultPadding)
        }

        colorControl.snp.makeConstraints { make in
            make.height.equalTo(BtnCons.SegmHeight)
            make.top.equalTo(typeControl.snp.bottom).offset(BtnCons.largePadding)
            make.left.equalToSuperview().offset(BtnCons.defaultPadding)
            make.right.equalToSuperview().inset(BtnCons.defaultPadding)
        }

        loadingLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(BtnCons.defaultPadding)
            make.top.equalTo(colorControl.snp.bottom).offset(BtnCons.largePadding)
        }

        loadingSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(loadingLabel.snp.centerY)
            make.left.equalTo(loadingLabel.snp.right).offset(BtnCons.spacing)
        }

        disabledLabel.snp.makeConstraints { make in
            make.centerY.equalTo(loadingLabel.snp.centerY)
            make.left.equalTo(loadingSwitch.snp.right).offset(BtnCons.defaultPadding)
        }

        disabledSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(loadingLabel.snp.centerY)
            make.left.equalTo(disabledLabel.snp.right).offset(BtnCons.spacing)
        }

        roundLabel.snp.makeConstraints { make in
            make.centerY.equalTo(loadingLabel.snp.centerY)
            make.left.equalTo(disabledSwitch.snp.right).offset(BtnCons.defaultPadding)
        }

        roundSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(loadingLabel.snp.centerY)
            make.left.equalTo(roundLabel.snp.right).offset(BtnCons.spacing)
        }

        self.button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(roundSwitch.snp.bottom).offset(40)
        }

        self.iconButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(button.snp.bottom).offset(40)
        }
    }

    private func setAppearance() {
        self.view.backgroundColor = UIColor.ud.bgFloat
        self.title = "UniverseDesignButton"
        self.button.setTitle("按钮标题", for: .normal)
        self.iconButton.setTitle("按钮标题", for: .normal)
        self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 12, height: 12)), for: .normal)
        self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 12, height: 12)), for: .highlighted)
        self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: UIColor.ud.udtokenBtnPriTextDisabled, size: CGSize(width: 12, height: 12)), for: .disabled)
        setSizeControlAppearance(self.sizeControl)
        setColorControlAppearance(self.colorControl)
        setTypeControlAppearance(self.typeControl)
        self.sizeControl.addTarget(self, action: #selector(clickSizeControl(_:)), for: .valueChanged)
        self.colorControl.addTarget(self, action: #selector(clickColorControl(_:)), for: .valueChanged)
        self.typeControl.addTarget(self, action: #selector(clickTypeControl(_:)), for: .valueChanged)
        self.loadingSwitch.addTarget(self, action: #selector(clickLoading(_:)), for: .valueChanged)
        self.disabledSwitch.addTarget(self, action: #selector(clickDisabled(_:)), for: .valueChanged)
        self.roundSwitch.addTarget(self, action: #selector(clickRounded(_:)), for: .valueChanged)
    }
}

extension UniverseDesignButtonVC {
    func createTitleLabel(_ text: String, _ font: UIFont = UDFont.body0) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textAlignment = .left
        return label
    }

    func setSizeControlAppearance(_ sizeSegm: UISegmentedControl) {
        sizeSegm.setTitleTextAttributes([
            .font: UIFont.ud.body2
        ], for: .normal)
        sizeSegm.insertSegment(withTitle: "Small", at: 0, animated: true)
        sizeSegm.insertSegment(withTitle: "Middle", at: 1, animated: true)
        sizeSegm.insertSegment(withTitle: "Large", at: 2, animated: true)
        sizeSegm.selectedSegmentIndex = 0
        sizeSegm.translatesAutoresizingMaskIntoConstraints = false
    }

    func setColorControlAppearance(_ sizeSegm: UISegmentedControl) {
        sizeSegm.setTitleTextAttributes([
            .font: UIFont.ud.body2
        ], for: .normal)
        sizeSegm.insertSegment(withTitle: "Pri", at: 0, animated: true)
        sizeSegm.insertSegment(withTitle: "Sec", at: 1, animated: true)
        sizeSegm.insertSegment(withTitle: "Sec-Blue", at: 2, animated: true)
        sizeSegm.insertSegment(withTitle: "Error", at: 3, animated: true)
        sizeSegm.insertSegment(withTitle: "Sec-Err", at: 4, animated: true)
        sizeSegm.selectedSegmentIndex = 0
        sizeSegm.translatesAutoresizingMaskIntoConstraints = false
    }

    func setTypeControlAppearance(_ sizeSegm: UISegmentedControl) {
        sizeSegm.setTitleTextAttributes([
            .font: UIFont.ud.body2
        ], for: .normal)
        sizeSegm.insertSegment(withTitle: "基础", at: 0, animated: true)
        sizeSegm.insertSegment(withTitle: "文本", at: 1, animated: true)
//        sizeSegm.insertSegment(withTitle: "幽灵", at: 2, animated: true)
        sizeSegm.selectedSegmentIndex = 0
        sizeSegm.translatesAutoresizingMaskIntoConstraints = false
    }

    func updateButton() {
        self.button.config = self.config
        self.button.config.type = self.type
        self.button.config.radiusStyle = self.isButtonRadius ? .circle : .square
        self.button.isEnabled = self.isButtonEnabled
        self.iconButton.config = self.config
        self.iconButton.config.type = self.type
        self.iconButton.config.radiusStyle = self.isButtonRadius ? .circle : .square
        self.iconButton.isEnabled = self.isButtonEnabled
        switch self.type {
        case .small:
            self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: self.iconColorType.getColor(), size: CGSize(width: 12, height: 12)), for: .normal)
            self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: self.iconColorType.getColor(), size: CGSize(width: 12, height: 12)), for: .highlighted)
            self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: self.iconColorType.getDisableColor(), size: CGSize(width: 12, height: 12)), for: .disabled)
        default:
            self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: self.iconColorType.getColor(), size: CGSize(width: 16, height: 16)), for: .normal)
            self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: self.iconColorType.getColor(), size: CGSize(width: 16, height: 16)), for: .highlighted)
            self.iconButton.setImage(UDIcon.getIconByKey(.imageOutlined, iconColor: self.iconColorType.getDisableColor(), size: CGSize(width: 16, height: 16)), for: .disabled)
        }

        if self.isButtonLoading {
            self.button.showLoading()
            self.iconButton.showLoading()
        } else {
            self.button.hideLoading()
            self.iconButton.hideLoading()
        }
    }

    @objc
    func clickSizeControl(_ segmented: UISegmentedControl) {
        if segmented.selectedSegmentIndex == 0 {
            self.type = .small
        } else if segmented.selectedSegmentIndex == 1 {
            self.type = .middle
        } else if segmented.selectedSegmentIndex == 2 {
            self.type = .big
        }
        self.updateButton()
    }

    @objc
    func clickColorControl(_ segmented: UISegmentedControl) {
        switch self.buttonType {
        case .basic:
            if segmented.selectedSegmentIndex == 0 {
                self.config = .primaryBlue
                self.iconColorType = .primaryOnPrimaryFill
            } else if segmented.selectedSegmentIndex == 1 {
                self.config = .secondaryGray
                self.iconColorType = .iconN1
            } else if segmented.selectedSegmentIndex == 2 {
                self.config = .secondaryBlue
                self.iconColorType = .Pri500
            } else if segmented.selectedSegmentIndex == 3 {
                self.config = .primaryRed
                self.iconColorType = .primaryOnPrimaryFill
            } else if segmented.selectedSegmentIndex == 4 {
                self.config = .secondaryRed
                self.iconColorType = .dangercolorfulRed
            }
        case .text:
            if segmented.selectedSegmentIndex == 0 {
                self.config = .textBlue
                self.iconColorType = .Pri500
            } else if segmented.selectedSegmentIndex == 1 {
                self.config = .textGray
                self.iconColorType = .iconN1
            } else if segmented.selectedSegmentIndex == 3 {
                self.config = .textRed
                self.iconColorType = .dangercolorfulRed
            } else {
                self.config = .textBlue
                segmented.selectedSegmentIndex = 0
            }
        }
        self.updateButton()
    }

    @objc
    func clickTypeControl(_ segmented: UISegmentedControl) {
        if segmented.selectedSegmentIndex == 0 {
            self.buttonType = .basic
            self.colorControl.setEnabled(true, forSegmentAt: 2)
            self.colorControl.setEnabled(true, forSegmentAt: 4)
            self.roundSwitch.isEnabled = true
            self.roundLabel.isEnabled = true
        } else if segmented.selectedSegmentIndex == 1 {
            self.buttonType = .text
            self.config = .primaryBlue
            self.colorControl.selectedSegmentIndex = 0
            self.colorControl.setEnabled(false, forSegmentAt: 2)
            self.colorControl.setEnabled(false, forSegmentAt: 4)
            self.roundSwitch.isEnabled = false
            self.roundLabel.isEnabled = false
        }
        self.clickColorControl(self.colorControl)
    }

    @objc
    func clickLoading(_ s: UISwitch) {
        if s.isOn {
            self.disabledSwitch.setOn(false, animated: true)
            self.clickDisabled(self.disabledSwitch)
            self.isButtonLoading = true
        } else {
            self.isButtonLoading = false
        }
        self.updateButton()
    }

    @objc
    func clickDisabled(_ s: UISwitch) {
        if s.isOn {
            self.loadingSwitch.setOn(false, animated: true)
            self.clickLoading(self.loadingSwitch)
            self.isButtonEnabled = false
        } else {
            self.isButtonEnabled = true
        }
        self.updateButton()
    }

    @objc
    func clickRounded(_ s: UISwitch) {
        if s.isOn {
            self.isButtonRadius = true
        } else {
            self.isButtonRadius = false
        }
        self.updateButton()
    }
}

struct BtnCons {
    static var defaultPadding: CGFloat { 22 }
    static var largePadding: CGFloat { 28 }
    static var SegmHeight: CGFloat { 32 }
    static var SegmWidth: CGFloat { 250 }
    static var spacing: CGFloat { 8 }
    static var minSpacing: CGFloat { 2 }
    static var lineHeight: CGFloat { 40 }
}


enum ButtonType {
    case basic
    case text
}

enum iconColorType {
    case primaryOnPrimaryFill
    case iconN1
    case dangercolorfulRed
    case Pri500

    func getColor() -> UIColor {
        switch self {
        case .primaryOnPrimaryFill:
            return UIColor.ud.primaryOnPrimaryFill
        case .iconN1:
            return UIColor.ud.iconN1
        case .dangercolorfulRed:
            return UIColor.ud.functionDangerContentDefault
        case .Pri500:
            return UIColor.ud.primaryContentDefault
        }
    }

    func getDisableColor() -> UIColor {
        switch self {
        case .primaryOnPrimaryFill:
            return UIColor.ud.udtokenBtnPriTextDisabled
        case .iconN1:
            return UIColor.ud.lineBorderComponent
        case .dangercolorfulRed:
            return UIColor.ud.lineBorderComponent
        case .Pri500:
            return UIColor.ud.lineBorderComponent
        }
    }
}
