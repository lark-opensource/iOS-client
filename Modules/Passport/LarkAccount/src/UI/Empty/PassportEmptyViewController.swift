//
//  PassportNoticeViewController.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignButton
import SnapKit
import LarkUIKit
import UniverseDesignTheme
import UniverseDesignEmpty

class PassportEmptyViewController: PassportBaseViewController {

    let viewModel: PassportEmptyViewModel

    init(viewModel: PassportEmptyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeSubViews()
    }

    private func makeSubViews() {

        let primaryButtonConfig: (String?, (UIButton) -> Void)? = (viewModel.primaryButtonTitle, {[weak self] _ in
            self?.onPrimaryClick()
        })

        let secondaryButtonConfig: (String?, (UIButton) -> Void)?
        if let title = viewModel.secondaryButtonTitle {
            secondaryButtonConfig = (title, { [weak self] _ in
                self?.onSecondaryClick()
            })
        } else {
            secondaryButtonConfig = nil
        }

        let config = UDEmptyConfig(titleText: viewModel.title,
                                   description: UDEmptyConfig.Description(descriptionText: viewModel.subTitle),
                                   imageSize: Layout.noticeImageSize,
                                   type: viewModel.type,
                                   primaryButtonConfig: primaryButtonConfig,
                                   secondaryButtonConfig: secondaryButtonConfig)

        let emptyView = UDEmptyView(config: config)
        self.view.addSubview(emptyView)

        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func onPrimaryClick() {
        viewModel.handlePrimaryButtonAction()
    }

    @objc
    func onSecondaryClick() {
        viewModel.handleSecondaryButtonAction()
    }
}

fileprivate struct Layout {
    static let titleFontSize = 17
    static let subTitleFontSize = 14
    static let noticeImageSize = 100
    static let buttonWidth = 96
    static let buttonHeight = 36
    static let itemSpace = 12
    static let itemPadding = 16
    static let subTitleLabelWidthForIpad = 320
}
