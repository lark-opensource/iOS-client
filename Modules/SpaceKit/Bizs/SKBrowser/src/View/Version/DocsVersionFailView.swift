//
//  VersionFailView.swift
//  SKCommon
//
//  Created by GuoXinyi on 2022/9/11.
//

import UIKit
import SKUIKit
import UniverseDesignColor
import SKCommon
import SKFoundation
import UniverseDesignEmpty
import SKResource

public protocol VersionFailViewProtocol: NSObject {
    func didClickPrimaryButton()
}

class VersionFailView: EmptyListPlaceholderView {
    var didTap: ((VersionErrorCode?) -> Void)?
    private var error: VersionErrorCode?
    public weak var failDelegate: VersionFailViewProtocol?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    func showFail(error: VersionErrorCode) {
        if error.failViewType != .fileDeleted {
            super.config(error: ErrorInfoStruct(type: error.failViewType, title: error.pageErrorDescription, domainAndCode: nil))
        } else {
            super.config(.init(title: .init(titleText: ""),
                        description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Deleted),
                        imageSize: 100,
                        type: .noContent,
                        primaryButtonConfig: (BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_Back2Ori_Button, { [weak self] button in
                                guard let self = self else { return }
                                self.failDelegate?.didClickPrimaryButton()
                            })))
        }
        
        self.error = error
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        isHidden = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didClickFailTips(_:)))
        addGestureRecognizer(gesture)
    }

    @objc
    private func didClickFailTips(_ gesture: UITapGestureRecognizer) {
        didTap?(error)
    }
}
