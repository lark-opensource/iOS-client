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
import UniverseDesignFont

struct BTFieldUIDataButton: BTFieldUIData {
    struct Const {
        static let buttonWidthMin: CGFloat = 68.0
        static let buttonHeight: CGFloat = 32.0
        static let buttonIconSize: CGFloat = 18.0
        
        static let textFont: UIFont = UDFont.body2
    }
    
    static let buttonConfig: UDButtonUIConifg = {
        let size = CGSize(width: Const.buttonWidthMin, height: Const.buttonHeight)
        let inset: CGFloat = 10
        let font = Const.textFont
        let iconSize = CGSize(width: Const.buttonIconSize, height: Const.buttonIconSize)
        return UDButtonUIConifg(
            normalColor: .init(borderColor: .clear, backgroundColor: UDColor.colorfulBlue, textColor: UDColor.N00),
            type: .custom(type: (size, inset, font, iconSize))
        )
    }()
    
    static func calculateButtonFieldFitSize(_ field: BTFieldModel) -> CGSize {
        let button = UDButton(buttonConfig)
        button.setTitle(field.buttonConfig.title, for: .normal)
        button.sizeToFit()
        let w = max(Const.buttonWidthMin, button.bounds.width)
        let h = Const.buttonHeight
        return CGSize(width: w, height: h)
    }
}

final class BTFieldV2Button: BTFieldV2Base {
    
    private var colorModel = BTButtonColorModel()
    
    /// 需要支持 disbale 态页点击弹 toast，因此不能自带的 isEnable 属性（isEnable设置后会无法响应点击事件）
    private var isDisable = false
    
    private lazy var button: UDButton = {
        var config = BTFieldUIDataButton.buttonConfig
        let button = UDButton(config)
        button.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return button
    }()
    
    override func subviewsInit() {
        super.subviewsInit()
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
        if fieldModel.buttonConfig.status == .disable {
            if fieldModel.uneditableReason == .editAfterSubmit {
                // disable 点击按钮也需要显示提示
                showUneditableToast()
            }
        }
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
        isDisable = (config.status == .disable)
        
        var buttonUIConfig = button.config
        buttonUIConfig.normalColor = getButtonThemeColor(buttonStatus: isDisable ? .disable : .general)
        buttonUIConfig.pressedColor = getButtonThemeColor(buttonStatus: .active)
        buttonUIConfig.disableColor = getButtonThemeColor(buttonStatus: .disable)
        buttonUIConfig.loadingColor = getButtonThemeColor(buttonStatus: .loading)
        buttonUIConfig.loadingIconColor = UIColor.docs.rgb(colorModel.styles[BTButtonFieldStatus.loading.rawValue]?.textColor ?? "#FFFFFF")
        
        button.titleLabel?.alpha = 1
        button.setTitle(config.title, for: .normal)
        
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
        updateButtonNormalColor(buttonStatus: .general)
    }
    
    private func getButtonThemeColor(buttonStatus: BTButtonFieldStatus) -> UDButtonUIConifg.ThemeColor {
        return UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                           backgroundColor: UIColor.docs.rgb(colorModel.styles[buttonStatus.rawValue]?.bgColor ?? "#3370FF"),
                                           textColor: UIColor.docs.rgb(colorModel.styles[buttonStatus.rawValue]?.textColor ?? "#FFFFFF"))
    }
    
    private func updateButtonNormalColor(buttonStatus: BTButtonFieldStatus) {
        var buttonUIConfig = button.config
        if isDisable {
            buttonUIConfig.normalColor = getButtonThemeColor(buttonStatus: .disable)
        } else {
            buttonUIConfig.normalColor = getButtonThemeColor(buttonStatus: buttonStatus)
        }
        button.config = buttonUIConfig
    }
}
