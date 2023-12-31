//
//  BTFieldEditFooter+AutoNum.swift
//  SKBitable
//
//  Created by zhysan on 2023/4/6.
//

import Foundation
import SKResource
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

protocol BTFieldEditAutoNumFooterDelegate: AnyObject {
    func footerHeightDidChange(_ footer: BTFieldEditAutoNumFooter)
}

class BTFieldEditAutoNumFooter: UIView {
    
    struct Const {
        static let noHeaderTopSuggestMargin: CGFloat = 16.0
    }
    
    // MARK: - public
    
    weak var delegate: BTFieldEditAutoNumFooterDelegate?
    
    var addAction: ((BTAddButton) -> Void)?
    
    func updateAddButton(hidden: Bool? = nil, enable: Bool? = nil, text: String? = nil, topMargin: CGFloat? = nil) {
        var needsUpdateHeight = false
        if let hidden = hidden {
            if hidden {
                addWrapper.removeFromSuperview()
            } else {
                stackView.addArrangedSubview(addWrapper)
            }
            needsUpdateHeight = true
        }
        if let enable = enable {
            addButton.buttonIsEnabled = enable
        }
        if let text = text {
            addButton.setText(text: text)
        }
        if let topMargin = topMargin {
            stackView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(topMargin)
            }
            needsUpdateHeight = true
        }
        updateHeightIfNeeded(needsUpdateHeight)
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let stackView = UIStackView().construct { it in
        it.axis = .vertical
    }
    
    private let addButton = BTAddButton().construct { it in
        it.icon.image = UDIcon.addOutlined.ud.withTintColor(UDColor.primaryContentDefault)
    }
    
    private let addWrapper = UIView().construct { it in
        it.backgroundColor = .clear
    }
    
    @objc
    private func onTapped(_ sender: BTAddButton) {
        addAction?(sender)
    }
    
    private func updateHeightIfNeeded(_ flag: Bool) {
        guard flag else { return }
        setNeedsLayout()
        delegate?.footerHeightDidChange(self)
    }
    
    private func subviewsInit() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.right.bottom.equalToSuperview()
        }
        
        addWrapper.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48).priority(.high)
        }
        
        addButton.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
    }
    
}
