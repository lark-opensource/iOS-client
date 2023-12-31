//
//  WikiFaildView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/9/27.
//

import UIKit
import SKCommon
import SKUIKit
import UniverseDesignColor
import SKResource

public class WikiFaildView: EmptyListPlaceholderView {
    public var didTap: ((WikiErrorCode?) -> Void)?
    public var didClickPrimaryButton: ((UIButton?) -> Void)?
    private var error: WikiErrorCode?
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public func showFail(error: WikiErrorCode) {
        if error != .versionNotFound {
            super.config(error: ErrorInfoStruct(type: error.failViewType, title: error.pageErrorDescription, domainAndCode: nil))
        } else {
            super.config(.init(title: .init(titleText: ""),
                        description: .init(descriptionText: error.pageErrorDescription),
                        imageSize: 100,
                        type: .noContent,
                        primaryButtonConfig: (BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_Back2Ori_Button, { [weak self] button in
                                guard let self = self else { return }
                                self.didClickPrimaryButton?(button)
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
