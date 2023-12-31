//
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import UIKit
import SKFoundation
import SKCommon
import LarkTag
import SKResource
import SKBrowser
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast


class BTBaseField: UICollectionViewCell, BTReadOnlyTextViewDelegate, BTDescriptionViewDelegate, BTFieldCellProtocol, BTStatisticRecordProtocol {

    // MARK: Data Model

    var fieldModel = BTFieldModel(recordID: "")

    weak var delegate: BTFieldDelegate?

    // MARK: Horizontally Laid Out Views

    lazy var horizontalStackView = UIStackView().construct { it in
        it.spacing = BTFieldLayout.Const.fieldIconRightPadding
        it.axis = .horizontal
        it.alignment = .top
    }

    private let iconWrapper = UIView()
    private lazy var iconImageView = BTLightingIconView()

    private lazy var fieldNameView = BTReadOnlyTextView().construct { it in
        it.isSelectable = false
        it.btDelegate = self
        it.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var fieldDescriptionInfoButton = BTFieldTipsButton().construct { it in
        it.addTarget(self, action: #selector(didTapDescriptionButton), for: .touchUpInside)
        it.setImage(iconType: .infoOutlined, withColorsForStates: [
            (UDColor.iconN2, .normal),
            (UDColor.iconN2, .highlighted),
            (UDColor.iconN2, [.highlighted, .selected]),
            (UDColor.primaryContentDefault, .selected)
        ])
    }

    private lazy var fieldErrorInfoButton = BTFieldTipsButton().construct { it in
        it.addTarget(self, action: #selector(didTapFieldErrorButton), for: .touchUpInside)
        it.setImage(iconType: .warningColorful)
    }
    
//    private lazy var unreadablePlaceholder = UIView().construct { it in
//        let label = UILabel()
//        let text = BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToViewFieldContent
//        label.text = text
//        label.font = UIFont.systemFont(ofSize: 14)
//        label.textColor = UIColor.ud.udtokenComponentTextDisabledLoading
//        label.textAlignment = .left
//        it.addSubview(label)
//        label.snp.makeConstraints { make in
//            make.left.equalToSuperview().offset(8)
//            make.right.equalToSuperview().offset(-8)
//            make.top.equalToSuperview().offset(8)
//            make.bottom.equalToSuperview().offset(-8)
//        }
//        it.backgroundColor = UDColor.bgContentBase
//        it.layer.zPosition = .greatestFiniteMagnitude
//        it.isUserInteractionEnabled = false
//    }

    private var fieldErrorMsg: String = ""

    // MARK: Vertically Laid Out Views

    lazy var verticalStackView = UIStackView().construct { it in
        it.spacing = BTFieldLayout.Const.fieldElementVerticalSpacing
        it.axis = .vertical
        it.alignment = .leading
    }

    private lazy var descriptionView = BTDescriptionView(limitButtonFont: BTFieldLayout.Const.fieldDescriptionFont,
                                                         textViewDelegate: self,
                                                         limitButtonDelegate: self)

    lazy var containerView = BTFieldContainer().construct { it in
        it.layer.cornerRadius = 6
        it.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
        it.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        it.backgroundColor = .clear
        it.clipsToBounds = false
    }
    
    lazy var fieldInfoWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.primaryPri600.withAlphaComponent(0.06)
        view.layer.cornerRadius = 4
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    let normalIndicator = UDIcon.expandDownFilled.ud.withTintColor(UDColor.iconN3)

    let pickingIndicator = UDIcon.expandUpFilled.ud.withTintColor(UDColor.primaryContentDefault)

    lazy var panelIndicator = UIImageView(image: normalIndicator)

    private lazy var errorMsgLabel = UILabel().construct { it in
        it.textColor = UDColor.functionDangerContentDefault
        it.font = UIFont.systemFont(ofSize: 14)
        it.textAlignment = .left
    }

    // MARK: View Configurations
    private var containerPreviousColor: UIColor? = .clear

    private var containerHighlight: Bool = false {
        willSet {
            if newValue == true && containerHighlight == false {
                containerPreviousColor = containerView.backgroundColor
            }
        }
        didSet {
            if containerHighlight == true && oldValue == false {
                containerView.backgroundColor = UDColor.primaryFillSolid02
            } else if containerHighlight == false && oldValue == true {
                containerView.backgroundColor = containerPreviousColor
            }
        }
    }

    var showsDescriptionIndicator: Bool = false

    var showsWarningIndicator: Bool = false

    var isDescriptionIndicatorSelected: Bool = false
    
    private lazy var primaryFieldBottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
    }

    private var startTimestamp: Double = 0
    var drawCount: (layout: Int, draw: Int) = (0, 0)
    var drawTime: (layout: Double, draw: Double) = (0, 0)

    override init(frame: CGRect) {
        super.init(frame: .zero)

        startTimestamp = CACurrentMediaTime() * 1000
        setupLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let endTimestamp = CACurrentMediaTime() * 1000
        drawCount.layout += 1
        drawTime.layout = endTimestamp - startTimestamp
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let endTimestamp = CACurrentMediaTime() * 1000
        drawCount.draw += 1
        drawTime.draw = endTimestamp - startTimestamp
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        drawCount = (0, 0)
        drawTime = (0, 0)
        startTimestamp = CACurrentMediaTime() * 1000
    }

    func setupLayout() {
        contentView.addSubview(fieldInfoWrapperView)
        contentView.addSubview(horizontalStackView)
        horizontalStackView.addArrangedSubview(iconWrapper)
        iconWrapper.addSubview(iconImageView)
        horizontalStackView.addArrangedSubview(fieldNameView)
        contentView.addSubview(verticalStackView)
        verticalStackView.addArrangedSubview(descriptionView)
        verticalStackView.addArrangedSubview(containerView)
        verticalStackView.addArrangedSubview(errorMsgLabel)
        contentView.addSubview(primaryFieldBottomLine)
//        containerView.addSubview(unreadablePlaceholder)

        horizontalStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(BTFieldLayout.Const.fieldVerticalInset)
            make.left.right.equalToSuperview().inset(BTFieldLayout.Const.containerLeftRightMargin)
            make.height.equalTo(fieldNameView)
        }

        iconImageView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(2) // label 因为设置了 figmaHeight，所以视觉上文字顶部与 icon 不对齐了
            make.width.height.equalTo(BTFieldLayout.Const.fieldIconWidthHeight)
        }
        
        fieldInfoWrapperView.snp.makeConstraints { make in
            make.top.bottom.equalTo(horizontalStackView).inset(-2)
            make.right.equalTo(fieldNameView).offset(4)
            make.left.equalTo(iconImageView).offset(-4)
        }

        verticalStackView.snp.makeConstraints { it in
            it.top.equalTo(horizontalStackView.snp.bottom).offset(BTFieldLayout.Const.fieldElementVerticalSpacing)
            it.left.right.equalToSuperview().inset(BTFieldLayout.Const.containerLeftRightMargin)
            it.bottom.equalToSuperview().inset(BTFieldLayout.Const.fieldVerticalInset)
        }

        containerView.snp.makeConstraints { make in
            make.width.equalTo(verticalStackView)
        }

        errorMsgLabel.snp.makeConstraints { make in
            make.height.equalTo(BTFieldLayout.Const.errorMsgHeight)
        }
        
        primaryFieldBottomLine.snp.remakeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
//        unreadablePlaceholder.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        unreadablePlaceholder.isHidden = true
    }

    func resetLayout() {
        // 如果子类依赖 fieldType 决定布局（例如 checkbox），则在 fieldModel 注入之后会立马调用该方法
        // 该方法时序早于一切其他配置
    }

    func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let startTimestamp = CACurrentMediaTime() * 1000
        fieldModel = model
        resetLayout()
        iconImageView.update(model.compositeType.icon(), showLighting: model.isSync, tintColor: UDColor.iconN2)
        let isInStage = model.isInStage
        
        fieldInfoWrapperView.isHidden = !model.isPrimaryField
        updateContainerColor()
        updateDescriptionButton(toSelected: model.isDescriptionIndicatorSelected)
        let isForm = model.isInForm
        showsDescriptionIndicator = false
        isDescriptionIndicatorSelected = fieldModel.isDescriptionIndicatorSelected
        var descriptionAttrText: NSAttributedString?
        if let descriptionSegments = fieldModel.description?.content, !descriptionSegments.isEmpty {
            if isForm {
                let result = BTUtil.convert(descriptionSegments,
                                            font: BTFieldLayout.Const.fieldDescriptionFont,
                                            plainTextColor: UDColor.textCaption)
                descriptionAttrText = result
            } else {
                showsDescriptionIndicator = true
            }
        }

        showsWarningIndicator = !fieldModel.fieldWarning.isEmpty && !model.isInForm
        let fieldNameColor = isForm ? UDColor.textTitle : UDColor.textCaption
        let fieldNameAttributedString = NSMutableAttributedString(string: fieldModel.name,
                                                                  attributes: [.foregroundColor: fieldNameColor])
        if fieldModel.required && (isForm || (isInStage && fieldModel.isStageLinkField)) {
            let asteriskAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UDColor.functionDangerContentDefault]
            let asterisk = NSMutableAttributedString(string: "*", attributes: asteriskAttributes)
            fieldNameAttributedString.append(asterisk)
        }

        let fieldNameFont = isForm ? BTFieldLayout.Const.formQuestionFont : BTFieldLayout.Const.fieldNameFont
        var shouldLastWordClear = false
        if showsDescriptionIndicator || showsWarningIndicator {
            shouldLastWordClear = true
            fieldNameAttributedString.append(NSMutableAttributedString(string: "ⓘ", attributes: [.foregroundColor: UIColor.clear]))
        }

        var figmaHeightAttributes = BTUtil.getFigmaHeightAttributes(font: fieldNameFont, alignment: .left)
        if model.isPrimaryField {
            let color = UDColor.primaryPri900.withAlphaComponent(0.7)
            figmaHeightAttributes[.foregroundColor] = color
            let offset = shouldLastWordClear ? 1 : 0
            fieldNameAttributedString.addAttributes(figmaHeightAttributes, range: NSRange(location: 0, length: fieldNameAttributedString.length - offset))
            fieldDescriptionInfoButton.setImage(iconType: .infoOutlined, withColorsForStates: [
            (color, .normal),
            (color, .highlighted),
            (color, [.highlighted, .selected]),
            (UDColor.primaryContentDefault, .selected)
        ])
        } else {
            fieldNameAttributedString.addAttributes(figmaHeightAttributes, range: NSRange(location: 0, length: fieldNameAttributedString.length))
            fieldDescriptionInfoButton.setImage(iconType: .infoOutlined, withColorsForStates: [
            (UDColor.iconN2, .normal),
            (UDColor.iconN2, .highlighted),
            (UDColor.iconN2, [.highlighted, .selected]),
            (UDColor.primaryContentDefault, .selected)
        ])
        }
        fieldNameView.font = fieldNameFont
        fieldNameView.attributedText = fieldNameAttributedString
        primaryFieldBottomLine.isHidden = !model.isPrimaryField
        if isInStage {
            let size = fieldNameView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: fieldNameFont.figmaHeight))
            if model.isPrimaryField {
                fieldNameView.textContainer.maximumNumberOfLines = 2
                fieldNameView.textContainer.lineBreakMode = .byTruncatingTail
                iconImageView.updateTintColor(UDColor.primaryPri900.withAlphaComponent(0.7))
            } else {
                // cell复用需要reset
                fieldNameView.textContainer.maximumNumberOfLines = 0
                fieldNameView.textContainer.lineBreakMode = .byWordWrapping
                iconImageView.updateTintColor(UDColor.iconN2)
            }
            horizontalStackView.snp.remakeConstraints { make in
                let inset = model.isPrimaryField ?
                    BTFieldLayout.Const.primaryFieldContainerLeftRightMarginInStage :
                    BTFieldLayout.Const.normalFieldContainerLeftRightMarginInStage
                make.right.equalToSuperview().offset(-inset)
                make.left.equalToSuperview().offset(inset)
                make.top.equalToSuperview().offset(BTFieldLayout.Const.fieldVerticalInset)
                make.height.equalTo(fieldNameView)
            }
            fieldInfoWrapperView.snp.remakeConstraints { make in
                make.left.equalTo(iconImageView.snp.left).offset(-4)
                make.right.greaterThanOrEqualTo(fieldNameView.snp.left).offset(size.width + 4).priority(.high)
                make.right.lessThanOrEqualTo(horizontalStackView).priority(.required)
                make.top.bottom.equalTo(horizontalStackView).inset(-2)
            }
            verticalStackView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(BTFieldLayout.Const.normalFieldContainerLeftRightMarginInStage)
                make.top.equalTo(horizontalStackView.snp.bottom).offset(BTFieldLayout.Const.fieldElementVerticalSpacing)
                make.bottom.equalToSuperview().inset(BTFieldLayout.Const.fieldVerticalInset)
            }
        }

        if let descAttrText = descriptionAttrText, let targetHeight = layout.descriptionHeights[fieldID] {
            verticalStackView.snp.updateConstraints { it in
                it.top.equalTo(horizontalStackView.snp.bottom).offset(BTFieldLayout.Const.fieldElementVerticalSpacing / 2)
            }
            descriptionView.isHidden = false
            descriptionView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(targetHeight)
            }
            layoutIfNeeded()
            descriptionView.setDescriptionText(descAttrText, showingHeight: targetHeight)
        } else {
            verticalStackView.snp.updateConstraints { it in
                it.top.equalTo(horizontalStackView.snp.bottom).offset(BTFieldLayout.Const.fieldElementVerticalSpacing)
            }
            descriptionView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(0)
            }
            descriptionView.isHidden = true
            layoutIfNeeded()
        }

        iconWrapper.isHidden = isForm
        if model.isPrimaryField {
            updateBorderMode(.none)
        } else if !model.editable {
            updateBorderMode(.none)
            if isInStage {
                errorMsgLabel.isHidden = fieldModel.errorMsg.isEmpty
                containerView.layer.borderWidth = fieldModel.errorMsg.isEmpty ? 0 : BTFieldLayout.Const.containerBorderWidth
                errorMsgLabel.text = fieldModel.errorMsg.isEmpty ? "" : fieldModel.errorMsg
                if !fieldModel.errorMsg.isEmpty {
                    containerView.layer.ud.setBorderColor(UDColor.functionDangerContentDefault)
                }
            }
        } else {
            if model.isEditing {
                updateBorderMode(.editing)
            } else if fieldModel.errorMsg.isEmpty {
                updateBorderMode(.normal)
            } else {
                updateBorderMode(.error)
            }
        }
        reportSetData(startTimestamp: startTimestamp)
    }

    private func reportSetData(startTimestamp: Double) {
        guard let traceId = delegate?.getOpenRecordTraceId() else {
            return
        }
        let endTimestamp = CACurrentMediaTime() * 1000
        let costTime = endTimestamp - startTimestamp
        BTOpenRecordReportHelper.reportCellSetData(
            traceId: traceId,
            costTime: costTime,
            uiType: fieldModel.extendedType.mockFieldID
        )
    }

    func updateBorderMode(_ mode: BorderMode) {
        if fieldModel.isPrimaryField {
            containerView.layer.borderWidth = 0
            errorMsgLabel.isHidden = true
        } else {
            switch mode {
            case .normal:
                containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
                containerView.layer.ud.setBorderColor(UDColor.lineBorderComponent)
                errorMsgLabel.isHidden = true
            case .editing:
                containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
                containerView.layer.ud.setBorderColor(UDColor.primaryContentDefault)
                errorMsgLabel.isHidden = true
            case .error:
                containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
                containerView.layer.ud.setBorderColor(UDColor.functionDangerContentDefault)
                errorMsgLabel.isHidden = false
                errorMsgLabel.text = fieldModel.errorMsg
            case .none:
                containerView.layer.borderWidth = 0
                errorMsgLabel.isHidden = true
            case .noBorder:
                containerView.layer.borderWidth = 0
                errorMsgLabel.isHidden = UserScopeNoChangeFG.YY.bitableRedesignFormViewFixDisable ? false : fieldModel.errorMsg.isEmpty
                errorMsgLabel.text = fieldModel.errorMsg
            }
        }
    }

    func updateContainerColor() {
        if !fieldModel.isPrimaryField {
            containerView.backgroundColor = fieldModel.editable ? UDColor.bgBody : UDColor.bgContentBase
        }
    }

    func updateContainerHighlight(_ highlight: Bool) {
        guard containerHighlight != highlight else { return }
        containerHighlight = highlight
    }

    func updateDescriptionButton(toSelected selected: Bool) {
        fieldDescriptionInfoButton.isSelected = selected
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapDescriptionButton() {
        delegate?.showDescriptionPanel(forFieldModel: fieldModel, fromButton: fieldDescriptionInfoButton)
    }

    @objc
    private func didTapFieldErrorButton() {
        guard let window = self.window, !fieldErrorMsg.isEmpty else { return }
        UDToast.showWarning(with: fieldErrorMsg, on: window)
    }

    func readOnlyTextViewDidFinishLayout(_ textView: BTReadOnlyTextView) {
        guard textView == fieldNameView else { return }

        fieldDescriptionInfoButton.removeFromSuperview()
        fieldErrorInfoButton.removeFromSuperview()
        guard showsDescriptionIndicator || showsWarningIndicator else {
            return
        }

        if let fieldNameAttrText = fieldNameView.attributedText, fieldNameAttrText.length > 0 {
            let lastCharacterGlyphRange = fieldNameView.layoutManager.glyphRange(forCharacterRange: NSRange(location: fieldNameAttrText.length - 1, length: 1),
                                                                                 actualCharacterRange: nil)
            let lastGlyphRect = fieldNameView.layoutManager.boundingRect(forGlyphRange: lastCharacterGlyphRange,
                                                                         in: fieldNameView.textContainer)

            if showsWarningIndicator {
                //显示字段警告按钮
                fieldErrorMsg = fieldModel.fieldWarning
                horizontalStackView.addSubview(fieldErrorInfoButton)
                fieldErrorInfoButton.snp.remakeConstraints { make in
                    make.left.equalTo(fieldNameView).offset(lastGlyphRect.minX == 0 ? -2 : lastGlyphRect.minX)
                    make.bottom.equalTo(fieldNameView)
                    make.width.height.equalTo(20)
                }
            }

            if showsDescriptionIndicator {
                //显示字段描述按钮
                horizontalStackView.addSubview(fieldDescriptionInfoButton)
                fieldDescriptionInfoButton.isSelected = isDescriptionIndicatorSelected
                fieldDescriptionInfoButton.snp.remakeConstraints { make in
                                        make.left.equalTo(fieldNameView).offset(lastGlyphRect.minX == 0 ? -2 : lastGlyphRect.minX)
                    make.bottom.equalTo(fieldNameView)
                    make.width.height.equalTo(20)
                }

                if showsWarningIndicator {
                    fieldErrorInfoButton.snp.remakeConstraints { make in
                        make.left.equalTo(fieldDescriptionInfoButton.snp.right).offset(2)
                        make.bottom.equalTo(fieldNameView)
                        make.width.height.equalTo(20)
                    }
                }
            }
        }
    }

    func readOnlyTextView(_ descriptionTextView: BTReadOnlyTextView, handleTapFromSender sender: UITapGestureRecognizer) {
        guard descriptionTextView != fieldNameView else {
            // 点击字段标题时退出编辑
            self.affiliatedViewController?.view.endEditing(true)
            return
        }
        let attributes = BTUtil.getAttributes(in: descriptionTextView, sender: sender)
        if !attributes.isEmpty {
            delegate?.didTapView(withAttributes: attributes, inFieldModel: nil)
        }
    }

    func toggleLimitMode(to newMode: Bool) {
        delegate?.changeDescriptionLimitMode(forFieldID: fieldID, toLimited: newMode)
    }

    func showUneditableToast() {
        BTFiledUtils.showUneditableToast(fieldModel: fieldModel, view: self)
        delegate?.track(
            event: DocsTracker.EventType.bitableCardEditDenyView.rawValue,
            params: ["reason": fieldModel.uneditableReason.rawValue]
        )
    }
}


// MARK: - Add Button for Attachment | Link typed fields

extension BTBaseField {
    
    enum IconStyle {
        case normal
        case disable
    }

    final class AddButton: UIButton {

        override var isHighlighted: Bool {
            didSet {
                addIcon.tintColor = isHighlighted ? UDColor.iconN2 : UDColor.iconN3
                backgroundColor = isHighlighted ? UDColor.udtokenBtnSeBgNeutralHover : .clear
            }
        }

        lazy var addIcon = UIImageView(image: UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 20, height: 20)))

        private var dashedBorder: CAShapeLayer?

        var shouldAddNewBorder = false
        
        /// 改变 Icon "+" 号的样式（透明度）
        var iconStyle: IconStyle = .normal {
            didSet {
                switch iconStyle {
                case .normal:
                    addIcon.alpha = 1.0
                case .disable:
                    addIcon.alpha = 0.5
                }
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            addSubview(addIcon)
            addIcon.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(18)
            }
            layer.cornerRadius = 6
            iconStyle = .normal
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            dashedBorder?.removeFromSuperlayer()
            if shouldAddNewBorder {
                let newDashedBorder = CAShapeLayer()
                layer.addSublayer(newDashedBorder)
                dashedBorder = newDashedBorder
                newDashedBorder.ud.setStrokeColor(UDColor.lineBorderComponent)
                newDashedBorder.lineDashPattern = [4, 2]
                newDashedBorder.lineJoin = .round
                newDashedBorder.fillColor = nil
                newDashedBorder.frame = bounds
                newDashedBorder.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
            }
        }
        
        func update(iconType: UDIconType) {
            let icon = UDIcon.getIconByKey(iconType, iconColor: UDColor.iconN3, size: CGSize(width: 20, height: 20))
            addIcon.image = icon
        }
    }
}

extension BTBaseField {
    var baseContext: BaseContext? {
        get {
            delegate?.baseContext
        }
    }
}
