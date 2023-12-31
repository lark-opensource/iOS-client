//
//  HomePersonalFailedView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/28.
//

import Foundation
import UniverseDesignEmpty
import UniverseDesignColor
import SKResource
import RxSwift

class HomePersonalFailedView: UICollectionViewCell {
    
    private lazy var emptyView: UDEmpty = {
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_NewCM_TryAgain_Tooltip),
                                   type: .restoring)
        let view = UDEmpty(config: config)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

class HomePersonalEmptyView: UICollectionViewCell {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Space.Home.new_home_personal_empty
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_NewCM_Onboarding_PersonalContent_Title
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_NewCM_Mobile_Onboarding_UseContentToOrganizeDocuments_Desc
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        label.numberOfLines = 0
        return label
    }()
    
    private(set) lazy var createButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.backgroundColor = UDColor.bgFloat
        button.setTitle(BundleI18n.SKResource.LarkCCM_NewCM_Sidebar_Web_CreateNew_Button, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        return button
    }()
    
    var reuseBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    // nolint: duplicated_code
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(createButton)
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.height.equalTo(162)
            make.width.equalTo(207)
            make.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.left.greaterThanOrEqualToSuperview().inset(24)
            make.right.lessThanOrEqualToSuperview().inset(24)
            make.centerX.equalToSuperview()
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.greaterThanOrEqualToSuperview().inset(24)
            make.right.lessThanOrEqualToSuperview().inset(24)
            make.centerX.equalToSuperview()
        }
        
        createButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        createButton.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(16)
            make.height.equalTo(36)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
        }
    }
    // enable-lint: duplicated_code
}
