//
//  BTButtonField.swift
//  SKBitable
//
//  Created by zoujie on 2023/1/6.
//  


import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import UniverseDesignButton

final class BTButtonField: BTBaseField {
    
    private var buttonUIConfig = UDButtonUIConifg(normalColor: UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                                                         backgroundColor: UIColor.ud.colorfulBlue,
                                                                                         textColor: UIColor.ud.N00))
    private var colorModel = BTButtonColorModel()
    
    private lazy var button: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let button = UDButton(config)
        button.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return button
    }()
    
    override func setupLayout() {
        super.setupLayout()
        containerView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // nolint: duplicated_code
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        clearContainerViewBorder()
        colorModel = model.buttonColors.first(where: { model.buttonConfig.color == $0.id }) ?? BTButtonColorModel()
        update(config: model.buttonConfig,
               colorModel: colorModel)

        if model.buttonConfig.status == .loading {
            showLoading()
        } else if model.buttonConfig.status == .done {
            showDoneView()
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000, execute: { [weak self] in
                // 执行完成，不可点击，800ms后转换为general状态
                guard let self = self, model.buttonConfig.status == .done else { return }
                self.delegate?.updateButtonFieldStatus(to: .general, inFieldWithID: self.fieldID)
            })
        } else {
            rest(status: .general)
        }
    }
    
    @objc
    private func onClick() {
        guard fieldModel.buttonConfig.status == .general else {
            DocsLogger.btInfo("[ButtonField] click return button status is \(fieldModel.buttonConfig.status.rawValue)")
            return
        }
        
        guard fieldModel.triggerAble else {
            // 数据下钻的场景下，按钮正常显示，但是点击不触发
            DocsLogger.btInfo("[ButtonField] click return editable is false")
            return
        }
        
        //发送异步请求到前端
        delegate?.didClickButtonField(inFieldWithID: fieldID)
    }
    
    private func clearContainerViewBorder() {
        containerView.layer.borderWidth = 0
        containerView.layer.ud.setBorderColor(.clear)
    }
    
    private func update(config: BTButtonModel, colorModel: BTButtonColorModel) {
        buttonUIConfig.normalColor = getButtonThemeColor(buttonStatus: .general)
        buttonUIConfig.pressedColor = getButtonThemeColor(buttonStatus: .active)
        buttonUIConfig.disableColor = getButtonThemeColor(buttonStatus: .disable)
        buttonUIConfig.loadingColor = getButtonThemeColor(buttonStatus: .loading)
        buttonUIConfig.loadingIconColor = UIColor.docs.rgb(colorModel.styles[BTButtonFieldStatus.loading.rawValue]?.textColor ?? "#FFFFFF")
        
        buttonUIConfig.type = .middle
        button.titleLabel?.alpha = 1
        button.setTitle(config.title, for: .normal)
        button.isEnabled = (config.status != .disable)
        button.config = buttonUIConfig
    }
    
    private func showDoneView() {
        button.hideLoading()
        let doneImage = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.primaryOnPrimaryFill)
        button.setImage(doneImage, for: .normal)
        updateButtonNormalColor(buttonStatus: .done)
        button.setTitle("", for: .normal)
        button.titleLabel?.alpha = 0
    }
    
    private func showLoading() {
        button.showLoading()
        button.setImage(nil, for: .normal)
        button.setTitle("", for: .normal)
        button.titleLabel?.alpha = 0
    }
    
    private func rest(status: BTButtonFieldStatus) {
        button.hideLoading()
        button.setImage(nil, for: .normal)
        updateButtonNormalColor(buttonStatus: status)
    }
    
    private func getButtonThemeColor(buttonStatus: BTButtonFieldStatus) -> UDButtonUIConifg.ThemeColor {
        return UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                           backgroundColor: UIColor.docs.rgb(colorModel.styles[buttonStatus.rawValue]?.bgColor ?? "#3370FF"),
                                           textColor: UIColor.docs.rgb(colorModel.styles[buttonStatus.rawValue]?.textColor ?? "#FFFFFF"))
    }
    
    private func updateButtonNormalColor(buttonStatus: BTButtonFieldStatus) {
        buttonUIConfig.normalColor = getButtonThemeColor(buttonStatus: buttonStatus)
        button.config = buttonUIConfig
    }
}
