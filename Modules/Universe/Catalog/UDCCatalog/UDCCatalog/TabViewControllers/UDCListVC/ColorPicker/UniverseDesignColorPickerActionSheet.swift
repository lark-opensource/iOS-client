//
//  UDColorPickerActionSheet.swift
//  UDKit
//
//  Created by zfpan on 2020/11/13.
//  Copyright © 2020年 panzaofeng. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColorPicker

public class UDColorPickerActionSheet: UIViewController {

    public let config: UDColorPickerConfig

    private var transitioning: UDColorPickerTransitioningDelegate = UDColorPickerTransitioningDelegate()

    private var colorPickerPanel: UDColorPickerPanel?

    private var panelHeight: CGFloat = 0

    private lazy var tap: UITapGestureRecognizer = {
        let ges = UITapGestureRecognizer(target: self, action: #selector(tapAction(sender:)))
        ges.delegate = self
        return ges
    }()

    public init(config: UDColorPickerConfig, height: CGFloat = 300) {
        self.config = config
        self.panelHeight = height

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = transitioning
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addGestureRecognizer(tap)

        colorPickerPanel = UDColorPickerPanel(config: config)
        colorPickerPanel?.delegate = self
        if let colorPickerPanel = colorPickerPanel {
            self.view.addSubview(colorPickerPanel)
        }

        layoutSubviews()
    }

    private func layoutSubviews() {
        colorPickerPanel?.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(panelHeight)
        }
    }
}

extension UDColorPickerActionSheet: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        if let colorPickerPanel = colorPickerPanel, colorPickerPanel.frame.contains(location) {
            return false
        } else {
            return true
        }
    }

    @objc
    private func tapAction(sender: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }
}

extension UDColorPickerActionSheet: UDColorPickerPanelDelegate {
    public func didSelected(color: UIColor?, category: UDPaletteItemsCategory, in panel: UDColorPickerPanel) {

    }
}
