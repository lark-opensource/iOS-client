//
//  GuideDialogController.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/7.
//

import Foundation
import UIKit

final class GuideDialogController: BaseMaskController {
    private var dialogView: GuideDialogView
    private var dialogConfig: DialogConfig
    init(dialogConfig: DialogConfig) {
        self.dialogConfig = dialogConfig
        self.dialogView = GuideDialogView(dialogConfig: dialogConfig)
        super.init()
        self.dialogView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        // 蒙层背景阴影设置
        let shadowAlpha = dialogConfig.shadowAlpha ?? BaseMaskController.Layout.shadowAlpha
        self.shadowAlpha = shadowAlpha
        self.view.addSubview(self.dialogView)
    }

    func showDialog() {
        self.dialogView.snp.remakeConstraints { (make) in
            make.size.equalTo(self.dialogView.intrinsicContentSize)
            make.centerX.centerY.equalToSuperview()
        }
    }

    func closeDialog() {
        removeFromWindow(window: self.view.window)
    }

    override func showInWindow(to window: UIWindow, makeKey: Bool = true) {
        super.showInWindow(to: window, makeKey: makeKey)
        self.showDialog()
    }
}

extension GuideDialogController: GuideDialogViewDelegate {
    func didClickClose(dialogView: GuideDialogView) {
        closeDialog()
        self.dialogConfig.delegate?.didClickClose(dialogView: dialogView)
    }

    func didClickBottomButton(dialogView: GuideDialogView) {
        self.dialogConfig.delegate?.didClickBottomButton(dialogView: dialogView)
    }
}
