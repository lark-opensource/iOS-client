//
//  BTContainerSearchPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/13.
//

import Foundation
import SKBrowser

class BTContainerSearchPlugin: BTContainerBasePlugin {
    
    private lazy var baseHeaderMaskView: UIView = {
        let view = UIControl()
        view.addTarget(self, action: #selector(maskViewClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var viewCatalogueMaskView: UIView = {
        let view = UIControl()
        view.addTarget(self, action: #selector(maskViewClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var toolbarMaskView: UIView = {
        let view = UIControl()
        view.addTarget(self, action: #selector(maskViewClicked), for: .touchUpInside)
        return view
    }()
    
    var searchMode: BrowserViewController.SearchMode? {
        didSet {
            if case .search(_) = searchMode {
                showMask()
            } else {
                removeMask()
            }
        }
    }
    
    private func showMask() {
        guard let service = service else {
            return
        }
        
        if let view = service.getPlugin(BTContainerHeaderPlugin.self)?.view {
            baseHeaderMaskView.removeFromSuperview()
            view.addSubview(baseHeaderMaskView)
            baseHeaderMaskView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        if let view = service.getPlugin(BTContainerViewCataloguePlugin.self)?.view {
            viewCatalogueMaskView.removeFromSuperview()
            view.addSubview(viewCatalogueMaskView)
            viewCatalogueMaskView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        if let view = service.getPlugin(BTContainerToolBarPlugin.self)?.view {
            toolbarMaskView.removeFromSuperview()
            view.addSubview(toolbarMaskView)
            toolbarMaskView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func removeMask() {
        if baseHeaderMaskView.superview != nil {
            baseHeaderMaskView.removeFromSuperview()
        }
        if viewCatalogueMaskView.superview != nil {
            viewCatalogueMaskView.removeFromSuperview()
        }
        if toolbarMaskView.superview != nil {
            toolbarMaskView.removeFromSuperview()
        }
    }
    
    @objc func maskViewClicked() {
        if case let .search(finishCallback) = searchMode {
            finishCallback()
        }
    }
    
}
