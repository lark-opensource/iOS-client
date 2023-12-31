//
//  WAEmptyView.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/27.
//

import Foundation
import UniverseDesignLoading
import UniverseDesignEmpty
import UniverseDesignColor
import SKResource

class WALoadingView: UIView {
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UDColor.bgBody

        let animationView = UDLoading.loadingImageView()
        addSubview(animationView)
        animationView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WAEmptyView: UIView {
    
    enum WAEmptyViewType {
        case loading    //加载
        case error(type: WALoadError?, clickHandler: (() -> Void)?)      //失败
    }
    
    private let loadingView = WALoadingView()
    private var clickHandler: (() -> Void)?
    
    private let errorView = {
        let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_LoadFailed),
                                   type: .loadingFailure)
        let view = UDEmptyView(config: config)
        view.isHidden = true
        return view
    }()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(loadingView)
        addSubview(errorView)
        
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        errorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingView.isHidden = true
    }
    
    private func showLoading() {
        bringSubviewToFront(loadingView)
        loadingView.isHidden = false
        errorView.isHidden = true
    }
    
    private func showError(type: WALoadError?) {
        if let type {
            errorView.update(config: type.emptyConfig)
        }
        errorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(errorViewClickHandler)))
        bringSubviewToFront(errorView)
        loadingView.isHidden = true
        errorView.isHidden = false
    }
    
    func show(type: WAEmptyViewType) {
        self.isHidden = false
        switch type {
        case .loading:
            showLoading()
        case let .error(type, handler):
            clickHandler = handler
            showError(type: type)
        }
        WALogger.logger.info("emptyview show:\(type)")
    }
    
    func hide() {
        self.isHidden = true
        loadingView.isHidden = true
        errorView.isHidden = true
        WALogger.logger.info("emptyview hide")
    }
    
    @objc
    private func errorViewClickHandler() {
        clickHandler?()
    }
}
