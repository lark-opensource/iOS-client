//
//  DocumentActivityNoPermissionController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/11.
//

import Foundation
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import SnapKit

public final class DocumentActivityNoPermissionController: SKPanelController {
    private lazy var emptyView: UDEmpty = {
        let title = UDEmptyConfig.Title(titleText: BundleI18n.SKResource.CreationMobile_Activity_NoPermissionToUse_title)
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.CreationMobile_Activity_NoPermissionToUse_content)
        let config = UDEmptyConfig(title: title, description: description, imageSize: 120,
                                   type: .noAccess, primaryButtonConfig: (BundleI18n.SKResource.CreationMobile_Activity_Plan_ConfirmBtn, { [weak self] _ in
            // TODO: 埋点
            self?.didClickMask()
        }))
        return UDEmpty(config: config)
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        button.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        return button
    }()
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait

    public init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    private func setup() {
        transitioningDelegate = panelFormSheetTransitioningDelegate
        modalPresentationStyle = .formSheet
        presentationController?.delegate = adaptivePresentationDelegate
        dismissalStrategy = []
    }

    public override func setupUI() {
        super.setupUI()

        containerView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.left.equalTo(containerView.safeAreaLayoutGuide).inset(16)
        }
        containerView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.left.right.equalTo(containerView.safeAreaLayoutGuide)
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide).offset(-36)
        }
    }
}
