//
//  BTFieldEditFooter.swift
//  SKBitable
//
//  Created by zhysan on 2023/4/3.
//

import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

protocol BTFieldEditFooterDelegate: AnyObject {
    func footerHeightDidChange(_ footer: BTFieldEditFooter)
    
    func onExtFooterConfigSwitchTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, valueChanged: Bool)
    
    func onExtFooterConfigItemCheckboxTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, item: FieldExtendConfigItem, valueChanged: Bool)
    
    func extFooterOriginRefreshButtonDidTap(_ footer: BTFieldEditExtendFooter, extendInfo: FieldExtendInfo?)
}

class BTFieldEditFooter: UIView {
    
    // MARK: - public
    
    let optionFooter = BTFieldEditOptionFooter()
    
    let autoNumFooter = BTFieldEditAutoNumFooter()
    
    private(set) var speFooter: UIView?
    
    let extFooter = BTFieldEditExtendFooter()
    
    weak var delegate: BTFieldEditFooterDelegate? = nil
    
    func activeOptionFooter(_ config: ((BTFieldEditOptionFooter) -> Void)?) {
        if speFooter != optionFooter {
            speFooter?.removeFromSuperview()
            stackView.insertArrangedSubview(optionFooter, at: 0)
            speFooter = optionFooter
        }
        config?(optionFooter)
    }
    
    func activeAutoNumFooter(_ config: ((BTFieldEditAutoNumFooter) -> Void)?) {
        if speFooter != autoNumFooter {
            speFooter?.removeFromSuperview()
            stackView.insertArrangedSubview(autoNumFooter, at: 0)
            speFooter = autoNumFooter
        }
        config?(autoNumFooter)
    }
    
    func activeLinkFooter(_ linkFooter: UIView) {
        guard linkFooter != speFooter else {
            return
        }
        speFooter?.removeFromSuperview()
        stackView.insertArrangedSubview(linkFooter, at: 0)
        speFooter = linkFooter
    }
    
    func activeExtendFooter(_ config: ((BTFieldEditExtendFooter) -> Void)?) {
        if !stackView.arrangedSubviews.contains(extFooter) {
            stackView.insertArrangedSubview(extFooter, at: stackView.arrangedSubviews.count)
        }
        config?(extFooter)
    }
    
    func deactiveSpeFooter() {
        speFooter?.removeFromSuperview()
        speFooter = nil
    }
    
    func deactiveExtFooter() {
        extFooter.removeFromSuperview()
    }
    
    func deactiveAll() {
        stackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
    }
    
    func hideEditableContent(_ hide: Bool) {
       
    }
    
    // MARK: - life cycle
    init(frame: CGRect = .zero, delegate: BTFieldEditFooterDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let stackView = UIStackView().construct { it in
        it.axis = .vertical
        it.spacing = 16
    }
    
    private func subviewsInit() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        extFooter.delegate = self
        optionFooter.delegate = self
        autoNumFooter.delegate = self
    }
}

extension BTFieldEditFooter: BTFieldEditExtendFooterDelegate {
    func onExtendConfigSwitchTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, valueChanged: Bool) {
        delegate?.onExtFooterConfigSwitchTap(footer, config: config, valueChanged: valueChanged)
    }
    
    func onExtendConfigItemCheckboxTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, item: FieldExtendConfigItem, valueChanged: Bool) {
        delegate?.onExtFooterConfigItemCheckboxTap(footer, config: config, item: item, valueChanged: valueChanged)
    }
    
    func footerExtendOriginRefreshButtonDidTap(_ footer: BTFieldEditExtendFooter, extendInfo: FieldExtendInfo?) {
        delegate?.extFooterOriginRefreshButtonDidTap(footer, extendInfo: extendInfo)
    }
    
    func footerHeightDidChange(_ footer: BTFieldEditExtendFooter) {
        delegate?.footerHeightDidChange(self)
    }
}

extension BTFieldEditFooter: BTFieldEditOptionFooterDelegate {
    func footerHeightDidChange(_ footer: BTFieldEditOptionFooter) {
        delegate?.footerHeightDidChange(self)
    }
}

extension BTFieldEditFooter: BTFieldEditAutoNumFooterDelegate {
    func footerHeightDidChange(_ footer: BTFieldEditAutoNumFooter) {
        delegate?.footerHeightDidChange(self)
    }
}

