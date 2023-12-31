//
//  AIImagePreviewToolBarView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/6/19.
//  


import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon

protocol AIImagePreviewTopToolBarViewDelegate: AnyObject {
    func topToolBarViewDidClickCancel()
    func topToolBarViewDidClickCheckBox(isSelect: Bool)
}

class AIImagePreviewTopToolBarView: UIView, LKNumberBoxDelegate {

    weak var delegate: AIImagePreviewTopToolBarViewDelegate?
    
    lazy var cancelBtn: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UDColor.textTitle.alwaysDark, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitle(BundleI18n.LarkAIInfra.Lark_Legacy_Cancel, for: .normal)
        return btn
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle.alwaysDark
        label.textAlignment = .center
        label.text = "1/4"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    lazy var numberBox: LKNumberBox = {
        let box = LKNumberBox(number: nil)
        box.delegate = self
        box.hitTestEdgeInsets = UIEdgeInsets(top: -9, left: -9, bottom: -9, right: -9)
        return box
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.N900.alwaysLight
        setupInit()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupInit() {
        addSubview(cancelBtn)
        cancelBtn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        addSubview(textLabel)
        addSubview(numberBox)
    }
    
    @objc func cancelAction() {
        self.delegate?.topToolBarViewDidClickCancel()
    }
    
    func didTapNumberbox(_ numberBox: LKNumberBox) {
        self.delegate?.topToolBarViewDidClickCheckBox(isSelect: numberBox.number == nil)
    }


    func setupLayout() {
        cancelBtn.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(16)
        }
        
        textLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(cancelBtn)
        }
        
        numberBox.snp.makeConstraints { (make) in
            make.centerY.equalTo(cancelBtn)
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 36, height: 36))
        }
    }
    
}



protocol AIImagePreviewBottomToolBarViewDelegate: AnyObject {
    func bottomToolBarViewDidClickInsert()
    func bottomToolBarViewDidClickSave()
}

class AIImagePreviewBottomToolBarView: UIView {
    
    weak var delegate: AIImagePreviewBottomToolBarViewDelegate?
    
    private lazy var insertButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UDColor.textTitle.alwaysDark, for: .normal)
        let size = CGSize(width: 100, height: 36)
        if let defaultColor = UDColor.AIPrimaryFillDefault(ofSize: size),
           let pressColor = UDColor.AIPrimaryFillPressed(ofSize: size) {
            btn.setBackgroundImage(UIColor.ud.image(with: defaultColor, size: size, scale: UIScreen.main.scale), for: .normal)
            btn.setBackgroundImage(UIColor.ud.image(with: pressColor, size: size, scale: UIScreen.main.scale), for: .highlighted)
        }
        btn.setBackgroundImage(UIColor.ud.image(with: UDColor.fillDisabled, size: size, scale: UIScreen.main.scale), for: .disabled)
        btn.layer.cornerRadius = 6
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        return btn
    }()
    
    lazy var saveButton: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UDColor.staticWhite, for: .normal)
        btn.setTitleColor(UDColor.staticWhitePressed, for: .highlighted)
        let size = CGSize(width: 100, height: 36)
        let icon = UDIcon.getIconByKey(.downloadOutlined, iconColor: UDColor.staticWhite, size: CGSize(width: 16, height: 16))
        let pressIcon = UDIcon.getIconByKey(.downloadOutlined, iconColor: UDColor.staticWhitePressed, size: CGSize(width: 16, height: 16))
        btn.setImage(icon, for: .normal)
        btn.setImage(pressIcon, for: .highlighted)
        btn.contentEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -4)
        btn.imageEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 4)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitle(BundleI18n.LarkAIInfra.Doc_Facade_Save, for: .normal)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.N900.alwaysLight
        setupInit()
        setupLayout()
        updateSelectNumber(0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupInit() {
        addSubview(saveButton)
        addSubview(insertButton)
        insertButton.addTarget(self, action: #selector(insertAction), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
    }
    
    @objc func insertAction() {
        self.delegate?.bottomToolBarViewDidClickInsert()
    }
    
    @objc func saveAction() {
        self.delegate?.bottomToolBarViewDidClickSave()
    }
    
    func setupLayout() {
        insertButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(36)
            make.width.equalTo(100)
        }
        
        saveButton.snp.makeConstraints { make in
            make.centerY.equalTo(insertButton)
            make.left.equalToSuperview().offset(18)
            make.height.equalTo(36)
        }
    }
    
    func updateSelectNumber(_ number: Int) {
        var text = BundleI18n.LarkAIInfra.LarkCCM_Docs_Cover_AIGC_InsertToDocs_Button(number: number)
        if number <= 0 {
            text = BundleI18n.LarkAIInfra.LarkCCM_Docs_Cover_AIGC_InsertToDocs_0_Button
        }
        let width = text.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 36), options: [], attributes: [NSAttributedString.Key.font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)], context: nil).size.width + 32
        self.insertButton.setTitle(text, for: .normal)
        insertButton.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
        updateSelectButton(number > 0)
    }
    
    func updateSelectButton(_ enable: Bool) {
        insertButton.isEnabled = enable
    }
}
