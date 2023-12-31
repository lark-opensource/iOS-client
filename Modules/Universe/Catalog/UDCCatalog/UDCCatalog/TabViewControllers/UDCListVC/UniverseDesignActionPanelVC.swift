//
//  UniverseDesignActionPanelVC.swift
//  UDCCatalog
//
//  Created by Siegfried on 2021/9/23.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignButton
import UniverseDesignFont
import UniverseDesignActionPanel
import UniverseDesignToast

class UniverseDesignActionPanelVC: UIViewController {
    private lazy var titleLabel: UILabel = createTitleLabel("UDActionPanel", UIFont.ud.title1)
    
    private lazy var panelTypeControl = UISegmentedControl()
    private lazy var actionSheetPadControl = UISegmentedControl()
    private lazy var popoverDirectionControl = UISegmentedControl()
    private lazy var actionSheetTitleControl = UISegmentedControl()
    private lazy var actionPanelIconControl = UISegmentedControl()
    
    private lazy var titleEnabledLabel: UILabel = createTitleLabel("启用标题：")
    private lazy var titleEnabledSwitch: UISwitch = UISwitch()
    
    private lazy var iconEnabledLabel: UILabel = createTitleLabel("启用图标：")
    private lazy var iconEnabledSwitch: UISwitch = UISwitch()
    private lazy var dragEnabelLabel: UILabel = createTitleLabel("启用拖动：")
    private lazy var dragEnabelSwitch: UISwitch = UISwitch()
    private lazy var middleEnabelLabel: UILabel = createTitleLabel("启用中间态：")
    private lazy var middleEnabelSwitch: UISwitch = UISwitch()
    
    private lazy var actionSheetStyle: UDActionSheetUIConfig.Style =
        .autoPopover(popSource: UDActionSheetSource(sourceView: button,
                                                    sourceRect: button.bounds,
                                                    arrowDirection: .up))
    
    private lazy var actionSheetDirection: UIPopoverArrowDirection = .up {
        didSet {
            self.actionSheetStyle = .autoPopover(popSource: UDActionSheetSource(sourceView: self.button,
                                                                                sourceRect: self.button.bounds,
                                                                                arrowDirection: self.actionSheetDirection))
        }
    }
    private lazy var isShowTitle: Bool = false
    private lazy var isShowIcon: Bool = false
    
    lazy var button = UDButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "sdadaa"
        setComponents()
        setConstraints()
        setAppearance()
    }
    
    private func setComponents() {
        self.view.addSubview(titleLabel)
        self.view.addSubview(panelTypeControl)
        self.view.addSubview(actionSheetPadControl)
        self.view.addSubview(popoverDirectionControl)
        self.view.addSubview(titleEnabledLabel)
        self.view.addSubview(titleEnabledSwitch)
        self.view.addSubview(iconEnabledLabel)
        self.view.addSubview(iconEnabledSwitch)
        self.view.addSubview(button)
    }

    private func setConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(PanelCons.defaultPadding)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(PanelCons.defaultPadding)
        }
        panelTypeControl.snp.makeConstraints { make in
            make.height.equalTo(PanelCons.SegmHeight)
            make.top.equalTo(titleLabel.snp.bottom).offset(PanelCons.largePadding)
            make.left.equalToSuperview().offset(PanelCons.defaultPadding)
        }

        actionSheetPadControl.snp.makeConstraints { make in
            make.height.equalTo(PanelCons.SegmHeight)
            make.top.equalTo(panelTypeControl.snp.bottom).offset(PanelCons.largePadding)
            make.left.equalToSuperview().offset(PanelCons.defaultPadding)
        }
        
        popoverDirectionControl.snp.makeConstraints { make in
            make.height.equalTo(PanelCons.SegmHeight)
            make.top.equalTo(actionSheetPadControl.snp.bottom).offset(PanelCons.largePadding)
            make.left.equalToSuperview().offset(PanelCons.defaultPadding)
            make.right.equalToSuperview().inset(PanelCons.defaultPadding)
        }
        
        titleEnabledLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(PanelCons.defaultPadding)
            make.top.equalTo(popoverDirectionControl.snp.bottom).offset(PanelCons.largePadding)
        }

        titleEnabledSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(titleEnabledLabel.snp.centerY)
            make.left.equalTo(titleEnabledLabel.snp.right).offset(PanelCons.spacing)
        }
        
        iconEnabledLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(PanelCons.defaultPadding)
            make.top.equalTo(popoverDirectionControl.snp.bottom).offset(PanelCons.largePadding)
        }

        iconEnabledSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(iconEnabledLabel.snp.centerY)
            make.left.equalTo(iconEnabledLabel.snp.right).offset(PanelCons.spacing)
        }

        button.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(44)
            make.center.equalToSuperview()
        }
    }

    private func setAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBody
        button.setTitle("Click To Present", for: .normal)
        iconEnabledLabel.isHidden = true
        iconEnabledSwitch.isHidden = true
        setTypeControlAppearance(self.panelTypeControl)
        setSheetPadControlAppearance(self.actionSheetPadControl)
        setPopoverDirectionControlAppearance(self.popoverDirectionControl)
        self.button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        self.panelTypeControl.addTarget(self, action: #selector(clickTypeControl(_:)), for: .valueChanged)
        self.actionSheetPadControl.addTarget(self, action: #selector(clickPadControl(_:)), for: .valueChanged)
        self.popoverDirectionControl.addTarget(self, action: #selector(clickDirControl(_:)), for: .valueChanged)
        self.titleEnabledSwitch.addTarget(self, action: #selector(clickTitleEnable(_:)), for: .valueChanged)
        self.iconEnabledSwitch.addTarget(self, action: #selector(clickIconEnable(_:)), for: .valueChanged)
    }
    
    @objc
    private func clickButton() {
        if panelTypeControl.selectedSegmentIndex == 0 {
            let actionSheet: UDActionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: self.actionSheetStyle,
                                                                                         isShowTitle: self.isShowTitle))
            setActionSheet(actionSheet)
            self.present(actionSheet, animated: true)
        } else {
            let actionPanel: UDActionPanel = UDActionPanel(customViewController: UIViewController(),
                                                           config: UDActionPanelUIConfig(showMiddleState: false,
                                                                                         canBeDragged: false,
                                                                                         showIcon: self.isShowIcon))
            self.present(actionPanel, animated: true)
        }
    }
}

extension UniverseDesignActionPanelVC {
    func createTitleLabel(_ text: String, _ font: UIFont = UDFont.body0) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textAlignment = .left
        return label
    }

    func setTypeControlAppearance(_ sizeSegm: UISegmentedControl) {
        sizeSegm.setTitleTextAttributes([.font: UIFont.ud.body2], for: .normal)
        sizeSegm.insertSegment(withTitle: "ActionSheet", at: 0, animated: true)
        sizeSegm.insertSegment(withTitle: "ActionPanel", at: 1, animated: true)
        sizeSegm.selectedSegmentIndex = 0
        sizeSegm.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setSheetPadControlAppearance(_ sizeSegm: UISegmentedControl) {
        sizeSegm.setTitleTextAttributes([.font: UIFont.ud.body2], for: .normal)
        sizeSegm.insertSegment(withTitle: "Normal", at: 0, animated: true)
        sizeSegm.insertSegment(withTitle: "Popover", at: 1, animated: true)
        sizeSegm.insertSegment(withTitle: "Alert", at: 2, animated: true)
        sizeSegm.selectedSegmentIndex = 1
        sizeSegm.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setPopoverDirectionControlAppearance(_ sizeSegm: UISegmentedControl) {
        sizeSegm.setTitleTextAttributes([.font: UIFont.ud.body2], for: .normal)
        sizeSegm.insertSegment(withTitle: "Up", at: 0, animated: true)
        sizeSegm.insertSegment(withTitle: "Down", at: 1, animated: true)
        sizeSegm.insertSegment(withTitle: "Left", at: 2, animated: true)
        sizeSegm.insertSegment(withTitle: "Right", at: 3, animated: true)
        sizeSegm.insertSegment(withTitle: "Unkwn", at: 4, animated: true)
        sizeSegm.selectedSegmentIndex = 0
        sizeSegm.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc
    func clickTypeControl(_ segmented: UISegmentedControl) {
        if segmented.selectedSegmentIndex == 0 {
            self.popoverDirectionControl.isEnabled = true
            self.actionSheetPadControl.isEnabled = true
            self.titleEnabledLabel.isHidden = false
            self.titleEnabledSwitch.isHidden = false
            self.iconEnabledLabel.isHidden = true
            self.iconEnabledSwitch.isHidden = true
        } else {
            self.popoverDirectionControl.isEnabled = false
            self.actionSheetPadControl.isEnabled = false
            self.titleEnabledLabel.isHidden = true
            self.titleEnabledSwitch.isHidden = true
            self.iconEnabledLabel.isHidden = false
            self.iconEnabledSwitch.isHidden = false
        }
    }
    
    @objc
    func clickPadControl(_ segmented: UISegmentedControl) {
        switch segmented.selectedSegmentIndex {
        case 0:
            self.actionSheetStyle = .normal
            self.popoverDirectionControl.isEnabled = false
        case 1:
            self.actionSheetStyle = .autoPopover(popSource: UDActionSheetSource(sourceView: self.button,
                                                                                sourceRect: self.button.bounds,
                                                                                arrowDirection: self.actionSheetDirection))
            self.popoverDirectionControl.isEnabled = true
        case 2:
            self.actionSheetStyle = .autoAlert
            self.popoverDirectionControl.isEnabled = false
        default:
            self.actionSheetStyle = .normal
            self.popoverDirectionControl.isEnabled = false
        }
    }
    
    @objc
    func clickDirControl(_ segmented: UISegmentedControl) {
        switch segmented.selectedSegmentIndex {
        case 0:
            self.actionSheetDirection = .up
        case 1:
            self.actionSheetDirection = .down
        case 2:
            self.actionSheetDirection = .left
        case 3:
            self.actionSheetDirection = .right
        case 4:
            self.actionSheetDirection = .unknown
        default:
            self.actionSheetDirection = .up
        }
    }
    
    @objc
    func clickTitleEnable(_ s: UISwitch) {
        if s.isOn {
            self.isShowTitle = true
        } else {
            self.isShowTitle = false
        }
    }
    
    @objc
    func clickIconEnable(_ s: UISwitch) {
        if s.isOn {
            self.isShowIcon = true
        } else {
            self.isShowIcon = false
        }
    }
    
    func setActionSheet(_ actionSheet: UDActionSheet) {
        actionSheet.setTitle("选项描述文本")
        actionSheet.dismissWhenViewTransition(false)
        actionSheet.addDefaultItem(text: "常规选项1") {
            UDToast().showTips(with: "点击了 常规选项1", on: self.view, delay: 3)
        }
        actionSheet.addDefaultItem(text: "常规选项2") {
            UDToast().showTips(with: "点击了 常规选项2", on: self.view, delay: 3)
        }
        actionSheet.addDefaultItem(text: "常规选项3") {
            UDToast().showTips(with: "点击了 常规选项3", on: self.view, delay: 3)
        }
        actionSheet.addDestructiveItem(text: "警惕性操作") {
            UDToast().showTips(with: "点击了 警惕性操作", on: self.view, delay: 3)
        }
        actionSheet.setCancelItem(text: "取消") {
            UDToast().showTips(with: "点击了 取消", on: self.view, delay: 3)
        }
    }
}

struct PanelCons {
    static var defaultPadding: CGFloat { 22 }
    static var largePadding: CGFloat { 28 }
    static var SegmHeight: CGFloat { 32 }
    static var SegmWidth: CGFloat { 250 }
    static var spacing: CGFloat { 8 }
    static var minSpacing: CGFloat { 2 }
    static var lineHeight: CGFloat { 40 }
}
