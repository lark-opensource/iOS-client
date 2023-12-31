//
//  DriveCACBlockView.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/2/21.
//  


import Foundation
import UIKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignFont

public class DriveCACBlockView: UIView {

    private var displayMode: DrivePreviewMode = .card

    private lazy var containView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDEmptyType.noPreview.defaultImage()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = titleFont
        label.textColor = UDEmptyColorTheme.emptyTitleColor
        label.lineBreakMode = .byCharWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = descFont
        label.textColor = UDEmptyColorTheme.emptyDescriptionColor
        label.lineBreakMode = .byCharWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = BundleI18n.SKResource.CreationMobile_Docs_UnableToAccess_SecurityReason
        return label
    }()
    

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("DriveUnSupportFileView-----deinit")
    }
    
    private var titleFont: UIFont {
        return displayMode == .card ? UIFont.systemFont(ofSize: 14).medium : UDFont.title3(.fixed)
    }
    
    private var descFont: UIFont {
        return displayMode == .card ? UIFont.systemFont(ofSize: 12) : UDFont.body2(.fixed)
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(containView)

        containView.addSubview(iconView)
        containView.addSubview(descLabel)
        
        containView.setContentHuggingPriority(.required, for: .vertical)
        containView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        iconView.setContentHuggingPriority(.required, for: .vertical)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.height.equalTo(70)
            make.centerX.equalToSuperview()
        }
        descLabel.setContentHuggingPriority(.required, for: .vertical)
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.height.equalTo(18)
            make.bottom.equalToSuperview()
        }

    }
    
}
