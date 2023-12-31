//
//  BTFieldEditOptionFooter.swift
//  SKBitable
//
//  Created by zhysan on 2023/4/3.
//

import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

protocol BTFieldEditOptionFooterDelegate: AnyObject {
    func footerHeightDidChange(_ footer: BTFieldEditOptionFooter)
}

class BTFieldEditOptionFooter: UIView {
    // MARK: - public
    
    weak var delegate: BTFieldEditOptionFooterDelegate?
    
    var addAction: ((BTAddButton) -> Void)?
    
    func updateAddButton(hidden: Bool? = nil, enable: Bool? = nil, text: String? = nil, topMargin: CGFloat? = nil) {
        var needsUpdateHeight = false
        if let hidden = hidden {
            if hidden {
                addWrapper.removeFromSuperview()
            } else {
                updateTipLabel(hidden: true)
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
    
    func updateTipLabel(hidden: Bool, text: String? = nil, topMargin: CGFloat? = nil) {
        if hidden {
            tipWrapper.removeFromSuperview()
        } else {
            updateAddButton(hidden: true)
            stackView.addArrangedSubview(tipWrapper)
        }
        if let val = text {
            tipLabel.text = val
        }
        if let topMargin = topMargin {
            stackView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(topMargin)
            }
        }
        updateHeightIfNeeded(true)
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tipLabel.preferredMaxLayoutWidth = frame.width - 16 * 2
    }
    
    // MARK: - private
    
    private let stackView = UIStackView().construct { it in
        it.axis = .vertical
    }
    
    private let tipLabel = UILabel().construct { it in
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.font = UDFont.body1
        it.textColor = UDColor.textPlaceholder
        it.backgroundColor = .clear
    }

    private let tipWrapper = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.layer.cornerRadius = 10
        it.clipsToBounds = true
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
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        
        tipWrapper.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        
        addWrapper.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(48).priority(.high)
        }
        
        addButton.addTarget(self, action: #selector(onTapped(_:)), for: .touchUpInside)
    }
}
