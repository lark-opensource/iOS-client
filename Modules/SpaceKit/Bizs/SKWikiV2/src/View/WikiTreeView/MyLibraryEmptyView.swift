//
//  MyLibraryEmptyView.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/2/7.
//

import Foundation
import UniverseDesignEmpty
import UniverseDesignColor
import SKResource
import SKCommon

class MyLibraryEmptyView: UIView {
    enum LibraryEmptyType {
        case empty
        case error
    }
    
    private let emptyView: UDEmptyView = {
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_CM_MyLib_CreateOne_Empty_Mob),
                                   type: .noCloudFile)
        let view = UDEmptyView(config: config)
        return view
    }()
    
    private let errorView: UDEmptyView = {
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_CM_MyLib_LoadFail_Empty),
                                   type: .vcSharedMiss)
        let view = UDEmptyView(config: config)
        return view
    }()
    
    private let loadingView = DocsUDLoadingImageView()
    
    init() {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configButton(type: LibraryEmptyType, clickHandler: @escaping ((UIButton) -> Void)) {
        switch type {
        case .empty:
            var config = emptyView.config
            config.primaryButtonConfig = .init((BundleI18n.SKResource.LarkCCM_CM_MyLib_CreateOne_Button_Mob, { button in
                clickHandler(button)
            }))
            emptyView.update(config: config)
        case .error:
            var config = errorView.config
            config.primaryButtonConfig = .init((BundleI18n.SKResource.LarkCCM_CM_MyLib_LoadFail_Retry_Button, { button in
                clickHandler(button)
            }))
            errorView.update(config: config)
        }
        
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(loadingView)
        addSubview(emptyView)
        addSubview(errorView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        errorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func showLoading() {
        bringSubviewToFront(loadingView)
        loadingView.isHidden = false
        emptyView.isHidden = true
        errorView.isHidden = true
    }
    
    func showEmpty() {
        bringSubviewToFront(emptyView)
        emptyView.isHidden = false
        loadingView.isHidden = true
        errorView.isHidden = true
    }
    
    func showError() {
        bringSubviewToFront(errorView)
        errorView.isHidden = false
        emptyView.isHidden = true
        loadingView.isHidden = true
    }
}
