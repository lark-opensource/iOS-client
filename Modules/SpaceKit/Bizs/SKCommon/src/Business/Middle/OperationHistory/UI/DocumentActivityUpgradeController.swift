//
//  DocumentActivityUpgradeController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/10.
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

public final class DocumentActivityUpgradeController: SKPanelController {
    private lazy var emptyView: UDEmpty = {
        let title = UDEmptyConfig.Title(titleText: BundleI18n.SKResource.CreationMobile_Activity_Plan_Desc1)
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.CreationMobile_Activity_Plan_Desc2(suiteTypeName))
        let config = UDEmptyConfig(title: title, description: description, imageSize: 120,
                                   type: .platformUpgrading1, primaryButtonConfig: (BundleI18n.SKResource.CreationMobile_Activity_Plan_ConfirmBtn, { [weak self] _ in
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

    private let currentSuiteType: Int?
    private var suiteTypeName: String {
        guard let suiteType = currentSuiteType else {
            return BundleI18n.SKResource.CreationMobile_version_business
        }
        switch suiteType {
        case 1, 3, 4:
            return BundleI18n.SKResource.CreationMobile_version_standard
        case 2, 6:
            return BundleI18n.SKResource.CreationMobile_version_enterprise
        case 5:
            return BundleI18n.SKResource.CreationMobile_version_business
        default:
            DocsLogger.error("unknown suite type: \(suiteType)")
            return BundleI18n.SKResource.CreationMobile_version_business
        }
    }

    // TODO: 需要一个 suite_type
    public init(suiteType: Int?) {
        self.currentSuiteType = suiteType
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required public init?(coder: NSCoder) {
        currentSuiteType = nil
        super.init(coder: coder)
        setup()
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
            make.top.left.equalToSuperview().inset(16)
        }
        containerView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.left.right.equalTo(containerView.safeAreaLayoutGuide)
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide).offset(-36)
        }
    }
}
