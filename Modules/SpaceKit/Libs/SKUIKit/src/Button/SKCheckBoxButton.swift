//
//  SKCheckBoxButton.swift
//  SKUIKit
//
//  Created by huayufan on 2021/6/24.
//  


import UIKit
import UniverseDesignCheckBox


public final class SKCheckBoxButton: UIButton {
    var checkBox = UDCheckBox()
    public var textLabel = UILabel()
    
    public override var isSelected: Bool {
        didSet {
            checkBox.isSelected = self.isSelected
        }
    }
    
    public override var isEnabled: Bool {
        didSet {
            checkBox.isEnabled = isEnabled
        }
    }
    
    public struct Config {
        var text: String?
        var textColor: UIColor
        var font: UIFont
        var margin: CGFloat = 6
        var edgeLength: CGFloat = 20
        var type: UniverseDesignCheckBox.UDCheckBoxType
        public init(text: String? = nil, textColor: UIColor, font: UIFont, margin: CGFloat = 6, edgeLength: CGFloat = 20, type: UniverseDesignCheckBox.UDCheckBoxType = .single ) {
            self.text = text
            self.textColor = textColor
            self.font = font
            self.margin = margin
            self.edgeLength = edgeLength
            self.type = type
        }
    }
    
    var config: Config
    
    public required init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupInit()
        setupLayout()
        updateConfig(config)
    }
    
    func setupInit() {
        checkBox = UDCheckBox(boxType: config.type, config: UDCheckBoxUIConfig(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        addSubview(checkBox)
        addSubview(textLabel)
    }
    
    public func updateConfig(_ config: Config) {
        textLabel.text = config.text
        textLabel.textColor = config.textColor
        textLabel.font = config.font
    }
    
    func setupLayout() {
        checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(config.edgeLength)
            make.left.equalToSuperview()
        }
        
        textLabel.snp.makeConstraints { (make) in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(checkBox.snp.right).offset(config.margin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
