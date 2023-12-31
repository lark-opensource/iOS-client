//
//  BTFieldV2Base.swift
//  SKBitable
//
//  Created by zhysan on 2023/7/26.
//

import SKFoundation
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignToast
import UniverseDesignIcon
import SKResource

struct BTFieldUIDataName: BTFieldUIData {
    struct Const {
        /// 字段名 icon 大小
        static let nameIconSize: CGFloat = 16.0
        
        static let nameDescWrapperSize: CGFloat = 20.0
        
        static let nameDescImageSize: CGFloat = 14.0
        
        static let nameWarnWrapperSize: CGFloat = 20.0
        
        static let nameWarnImageSize: CGFloat = 14.0
        
        /// 字段名 icon 右侧与文字的距离
        static let nameIconRightMargin: CGFloat = 6.0
    }
    
    private(set) var descIconAttachment: NSTextAttachment?
    private(set) var warnIconAttachment: NSTextAttachment?
    private(set) var fieldNameAttributeString: NSAttributedString = NSAttributedString()
    
    init(name: String = "",
         shouldShowDescIcon: Bool = false,
         shouldShowWarnIcon: Bool = false,
         shouldShowRequire: Bool = false) {
        let nameFont = BTFV2Const.Font.fieldName
        let nameAttrs = BTFV2Const.TextAttributes.fieldName
        let nameAttrText = NSMutableAttributedString(string: name, attributes: nameAttrs)
        let baseLineOffset = (nameFont.figmaHeight - nameFont.lineHeight) / 2
        
        if shouldShowDescIcon {
            let attachment = NSTextAttachment(
                UDIcon.infoOutlined.ud.withTintColor(UDColor.iconN2),
                imageSize: CGSize(width: Const.nameDescImageSize, height: Const.nameDescImageSize),
                font: nameFont,
                fontBaseLineOffset: baseLineOffset,
                padding: (Const.nameDescWrapperSize - Const.nameDescImageSize) * 0.5
            )
            let attrString = NSMutableAttributedString(attachment: attachment)
            nameAttrText.append(attrString)
            descIconAttachment = attachment
        } else {
            descIconAttachment = nil
        }
        
        if shouldShowWarnIcon {
            let attachment = NSTextAttachment(
                UDIcon.warningColorful,
                imageSize: CGSize(width: Const.nameWarnImageSize, height: Const.nameWarnImageSize),
                font: nameFont,
                fontBaseLineOffset: baseLineOffset,
                padding: (Const.nameWarnWrapperSize - Const.nameWarnImageSize) * 0.5
            )
            let attrString = NSMutableAttributedString(attachment: attachment)
            nameAttrText.append(attrString)
            warnIconAttachment = attachment
        } else {
            warnIconAttachment = nil
        }
        
        if shouldShowRequire {
            let asteriskAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UDColor.functionDangerContentDefault]
            let asterisk = NSMutableAttributedString(string: "*", attributes: asteriskAttributes)
            nameAttrText.append(asterisk)
        }
        
        fieldNameAttributeString = nameAttrText
    }
}

class BTFieldV2Base: UICollectionViewCell, BTFieldCellProtocol, BTStatisticRecordProtocol {
    
    // MARK: - public

    private var startTimestamp: Double = 0
    var drawCount: (layout: Int, draw: Int) = (0, 0)
    var drawTime: (layout: Double, draw: Double) = (0, 0)
    
    let containerView = UIView().construct { it in
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    let editBtn = BTFieldEditButton()
    
    var fieldModel: BTFieldModel = BTFieldModel(recordID: "")
    
    weak var delegate: BTFieldDelegate?
    
    func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        loadField(model, layout: layout)
    }
    
    func subviewsInit() {
        innerSubviewsInit()
    }
    
    /// 仅更新内容，无法更新布局，如果编辑按钮变化，请触发 reload
    func updateEditButtonContent() {
        updateEditButton()
    }
    
    func updateModelInEditing(_ field: BTFieldModel, layout: BTFieldLayout) {
        updateLayoutInfoIfNeeded(layout.getTheCalculatedLayoutAttrbutesForField(field)?.layoutInfo)
    }
    
    @objc
    func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        if !fieldModel.editable {
            showUneditableToast()
        }
    }
    
    @objc
    func onFieldEditBtnClick(_ sender: UIButton) {
        if !fieldModel.editable {
            showUneditableToast()
        }
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)

        startTimestamp = CACurrentMediaTime() * 1000
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isTemporarilyHighlighted = false

        drawTime = (0, 0)
        drawCount = (0, 0)
        startTimestamp = CACurrentMediaTime() * 1000
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
    
    // MARK: - private
    
    private(set) var layoutInfo = BTFieldLayoutInfo()
    
    private let contentWrapper = EnlargeTapAreaView().construct { it in
        it.setContentHuggingPriority(.required, for: .vertical)
    }
    
    private let errorMsgWrapper = UIView().construct { it in
        it.setContentHuggingPriority(.required, for: .vertical)
    }
    
    private let bottomLine = UIView().construct { it in
        it.isUserInteractionEnabled = false
        it.backgroundColor = UDColor.lineBorderCard
    }
    
    private let nameWrapper = UIView()
    
    private let valueWrapper = EnlargeTapAreaView()
    
    private let nameIconView = BTLightingIconView()
    
    private let nameTextView = BTReadOnlyTextView().construct { it in
        it.isSelectable = false
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private let errorTextView = BTReadOnlyTextView().construct { it in
        it.isSelectable = false
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private let descIconBtn = UIButton(type: .custom)
    private let warnIconBtn = UIButton(type: .custom)
    
    private var isTemporarilyHighlighted = false
    
    private func loadField(_ field: BTFieldModel, layout: BTFieldLayout) {
        let startTimestamp = CACurrentMediaTime() * 1000

        fieldModel = field
        
        updateFieldName()
        updateFieldValue()
        updateFieldError()
        updateEditButton()
        updateFieldColor()
        
        updateLayoutInfoIfNeeded(layout.getTheCalculatedLayoutAttrbutesForField(field)?.layoutInfo)

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
    
    private func updateFieldName() {
        nameIconView.update(
            fieldModel.compositeType.icon(),
            showLighting: fieldModel.isSync,
            tintColor: BTFV2Const.Color.fieldNameIcon
        )
           
        nameTextView.font = BTFV2Const.Font.fieldName
        nameTextView.attributedText = fieldModel.nameUIData.fieldNameAttributeString
    }
    
    private func updateFieldValue() {
        // PM 修改：高级权限下暂不区分
        // containerView.alpha = fieldModel.isPro && !fieldModel.editable ? 0.7 : 1.0
    }
    
    private func updateFieldError() {
        errorTextView.attributedText = NSAttributedString(string: fieldModel.errorMsg, attributes: BTFV2Const.TextAttributes.fieldError)
    }
    
    private func updateEditButton() {
        editBtn.editType = fieldModel.editType
        editBtn.isLoading = fieldModel.isInEditLoadingStatus
    }
    
    private func updateFieldColor() {
        if isTemporarilyHighlighted {
            innerSetBorderMode(.normal)
            innerSetBackgroundHighlight(true)
        } else if fieldModel.isEditing {
            innerSetBorderMode(.editing)
            innerSetBackgroundHighlight(true)
        } else if fieldModel.shouldShowErrorMsg {
            innerSetBorderMode(.error)
            innerSetBackgroundHighlight(false)
        } else {
            innerSetBorderMode(.normal)
            innerSetBackgroundHighlight(false)
        }
    }
    
    private func setupDebugBgColor() {
        if !BTFV2Const.debugEnable {
            return
        }
        contentView.backgroundColor = .brown
        contentView.layer.borderColor = UIColor.black.cgColor
        contentView.layer.borderWidth = 1.0 / UIScreen.main.scale
        
        contentWrapper.backgroundColor = .lightGray
        
        nameWrapper.backgroundColor = .yellow
        
        valueWrapper.backgroundColor = .green
        containerView.backgroundColor = .orange
    }
    
    @objc
    private func onFieldNameAttachmentsBtnClick(_ sender: UIButton) {
        if sender == descIconBtn {
            delegate?.showDescriptionPanel(forFieldModel: fieldModel, fromButton: descIconBtn)
        } else if sender == warnIconBtn {
            guard let window = self.window, !fieldModel.fieldWarning.isEmpty else { return }
            UDToast.showWarning(with: fieldModel.fieldWarning, on: window)
        }
    }
    
    private func updateLayoutInfoIfNeeded(_ info: BTFieldLayoutInfo?) {
        guard let info = info, info != layoutInfo else {
            return
        }
        layoutInfo = info
        
        contentWrapper.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(info.contentInset.top)
            make.left.equalToSuperview().inset(info.contentInset.left)
            make.right.equalToSuperview().inset(info.contentInset.right)
            make.bottom.equalTo(errorMsgWrapper.snp.top).offset(-info.contentInset.bottom)
        }
        
        let showEditBtn = info.editSize.width > 0
        let showValue = info.valueSize.width > 0
        let valueEditSpace = (showValue && showEditBtn) ? BTFV2Const.Dimension.valueAssistHSpace : 0
        
        switch info.style {
        case .tb:
            // 上下结构布局
            nameWrapper.snp.remakeConstraints { make in
                make.left.right.top.equalToSuperview()
            }
            valueWrapper.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(nameWrapper.snp.bottom).offset(BTFV2Const.Dimension.nameValueTBSpace)
            }
            containerView.snp.remakeConstraints { make in
                make.top.greaterThanOrEqualToSuperview()
                make.left.centerY.equalToSuperview()
                make.size.equalTo(info.valueSize)
            }
            editBtn.snp.remakeConstraints { make in
                make.top.right.equalToSuperview()
                make.size.equalTo(info.editSize)
                make.left.equalTo(containerView.snp.right).offset(valueEditSpace).priority(.high)
            }
            contentWrapper.enlargeInset = .zero
            valueWrapper.enlargeInset = .zero
        case .lr:
            // 左右结构布局
            nameWrapper.snp.remakeConstraints { make in
                make.left.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
            }
            valueWrapper.snp.remakeConstraints { make in
                make.left.equalTo(nameWrapper.snp.right).offset(BTFV2Const.Dimension.nameValueLRSpace)
                make.right.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
            }
            editBtn.snp.remakeConstraints { make in
                make.right.centerY.equalToSuperview()
                make.size.equalTo(info.editSize)
                make.top.greaterThanOrEqualToSuperview()
            }
            containerView.snp.remakeConstraints { make in
                make.left.top.greaterThanOrEqualToSuperview()
                make.centerY.equalToSuperview()
                make.size.equalTo(info.valueSize)
                make.right.equalTo(editBtn.snp.left).offset(-valueEditSpace).priority(.high)
            }
            let enlargeInset = UIEdgeInsets(top: -info.contentInset.top, left: 0, bottom: -info.contentInset.bottom, right: 0)
            contentWrapper.enlargeInset = enlargeInset
            valueWrapper.enlargeInset = enlargeInset
        }
        errorMsgWrapper.snp.updateConstraints { make in
            make.height.equalTo(info.errorSize.height)
        }
        
        // 立即刷新布局，否子子类中 collectionView reloadData 布局可能会计算错误
        layoutIfNeeded()
    }
    
    private func innerSubviewsInit() {
        setupDebugBgColor()
        nameTextView.btDelegate = self
        descIconBtn.addTarget(self, action: #selector(onFieldNameAttachmentsBtnClick(_:)), for: .touchUpInside)
        warnIconBtn.addTarget(self, action: #selector(onFieldNameAttachmentsBtnClick(_:)), for: .touchUpInside)
        editBtn.addTarget(self, action: #selector(onFieldEditBtnClick(_:)), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onFieldValueEnlargeAreaClick(_:)))
        valueWrapper.addGestureRecognizer(tap)
        tap.delegate = self
        
        contentView.addSubview(contentWrapper)
        contentView.addSubview(bottomLine)
        contentView.addSubview(errorMsgWrapper)
        contentWrapper.addSubview(nameWrapper)
        contentWrapper.addSubview(valueWrapper)
        nameWrapper.addSubview(nameIconView)
        nameWrapper.addSubview(nameTextView)
        valueWrapper.addSubview(containerView)
        valueWrapper.addSubview(editBtn)
        nameTextView.addSubview(descIconBtn)
        nameTextView.addSubview(warnIconBtn)
        errorMsgWrapper.addSubview(errorTextView)
        
        descIconBtn.snp.makeConstraints { make in
            make.top.left.equalTo(0)
            make.size.equalTo(CGSize.zero)
        }
        
        warnIconBtn.snp.makeConstraints { make in
            make.top.left.equalTo(0)
            make.size.equalTo(CGSize.zero)
        }
        
        errorMsgWrapper.snp.makeConstraints { make in
            make.left.right.equalTo(contentWrapper)
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
        errorTextView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.left.right.equalTo(contentWrapper)
            make.bottom.equalTo(errorMsgWrapper.snp.top)
            make.height.equalTo(0.5)
        }
        nameIconView.snp.makeConstraints { make in
            let topOffset = (BTFV2Const.Font.fieldName.figmaHeight - BTFieldUIDataName.Const.nameIconSize) * 0.5
            make.left.equalToSuperview()
            make.width.height.equalTo(BTFieldUIDataName.Const.nameIconSize)
            make.top.equalToSuperview().offset(topOffset)
        }
        nameTextView.snp.makeConstraints { make in
            make.left.equalTo(nameIconView.snp.right).offset(BTFieldUIDataName.Const.nameIconRightMargin)
            make.top.right.bottom.equalToSuperview()
        }
        updateLayoutInfoIfNeeded(layoutInfo)
    }
}

extension BTFieldV2Base: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer.view == valueWrapper else {
            return true
        }
        let location1 = touch.location(in: containerView)
        let location2 = touch.location(in: editBtn)
        let tapInContainer = containerView.point(inside: location1, with: nil)
        let tapInEditBtn = editBtn.point(inside: location2, with: nil)
        if tapInContainer || tapInEditBtn {
            // container 和 editBtn 内部的事件，自己响应
            return false
        }
        return true
    }
}

// MARK: - BTFieldCellProtocol

extension BTFieldV2Base {
    func updateEditingStyle() {
        updateFieldColor()
    }
    
    // 这个方法不应该直接开放给子类去改，子类只应该去修改 model，父类计算显示何种样式
    @available(*, deprecated, message: "This method is deprecated. The external should not directly call the modification, but should refresh the data after modifying the fieldModel, and the parent class will finally calculate which style to display.")
    func updateBorderMode(_ mode: BorderMode) {
        innerSetBorderMode(mode)
        switch mode {
        case .normal, .error, .none, .noBorder:
            innerSetBackgroundHighlight(false)
        case .editing:
            innerSetBackgroundHighlight(true)
        }
    }
    
    func updateContainerHighlight(_ highlight: Bool) {
        isTemporarilyHighlighted = highlight
        updateFieldColor()
    }
    
    private func innerSetBorderMode(_ mode: BorderMode) {
        switch mode {
        case .normal:
            bottomLine.backgroundColor = UDColor.lineBorderCard
        case .editing:
            bottomLine.backgroundColor = UDColor.lineBorderCard
        case .error:
            bottomLine.backgroundColor = UDColor.functionDanger500
        case .none, .noBorder:
            // 新版 field 没有边框，旧版无边框的只读样式，新版和普通样式一致
            bottomLine.backgroundColor = UDColor.lineBorderCard
        }
    }
    
    private func innerSetBackgroundHighlight(_ highlight: Bool) {
        if highlight {
            contentView.backgroundColor = UDColor.primaryPri100
        } else {
            contentView.backgroundColor = UDColor.bgBody
        }
    }
    
    func updateDescriptionButton(toSelected selected: Bool) {
        // v1 打开字段描述面板 icon 会高亮为选中态， v2 先不加
    }
}

// MARK: - BTReadOnlyTextViewDelegate

extension BTFieldV2Base: BTReadOnlyTextViewDelegate {
    
    func readOnlyTextViewDidFinishLayout(_ textView: BTReadOnlyTextView) {
        // 这里暂时还是和之前线上保持一样，用 Button 处理点击事件，但是 Button 内容直接在 AttributeString 中显示
        let layoutManager = textView.layoutManager
        let textContainerInset = textView.textContainerInset
        
        descIconBtn.isHidden = !fieldModel.shouldShowDescIcon
        warnIconBtn.isHidden = !fieldModel.shouldShowWarnIcon
        
        let fullRange = NSRange(location: 0, length: textView.attributedText.length)
        layoutManager.enumerateLineFragments(forGlyphRange: fullRange) { (lineRect, _, textContainer, glyphRange, _) in
            for glyphIndex in glyphRange.location..<NSMaxRange(glyphRange) {
                let characterRange = layoutManager.characterRange(forGlyphRange: NSRange(location: glyphIndex, length: 1), actualGlyphRange: nil)
                var attachmentRange = NSRange(location: 0, length: 1)
                if let attachment = textView.attributedText.attribute(NSAttributedString.Key.attachment, at: characterRange.location, effectiveRange: &attachmentRange) as? NSTextAttachment {
                    let attachmentSize = attachment.bounds.size
                    let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
                    let originX = glyphRect.origin.x + textContainerInset.left
                    let originY = lineRect.origin.y + textContainerInset.top + (lineRect.height - attachmentSize.height) / 2
                    if attachment == self.fieldModel.nameUIData.descIconAttachment {
                        self.descIconBtn.snp.updateConstraints { make in
                            make.left.equalTo(originX)
                            make.top.equalTo(originY)
                            make.size.equalTo(attachmentSize)
                        }
                    } else if attachment == self.fieldModel.nameUIData.warnIconAttachment {
                        self.warnIconBtn.snp.updateConstraints { make in
                            make.left.equalTo(originX)
                            make.top.equalTo(originY)
                            make.size.equalTo(attachmentSize)
                        }
                    }
                }
            }
        }
    }
    
    func readOnlyTextView(_ textView: BTReadOnlyTextView, handleTapFromSender: UITapGestureRecognizer) {
        guard textView != nameTextView else {
            // 点击字段标题时退出编辑
            self.affiliatedViewController?.view.endEditing(true)
            return
        }
        let attributes = BTUtil.getAttributes(in: textView, sender: handleTapFromSender)
        if !attributes.isEmpty {
            delegate?.didTapView(withAttributes: attributes, inFieldModel: nil)
        }
    }
}

extension BTFieldV2Base {
    var baseContext: BaseContext? {
        get {
            delegate?.baseContext
        }
    }
}

extension BTFieldV2Base {
    func showUneditableToast() {
        BTFiledUtils.showUneditableToast(fieldModel: fieldModel, view: self)
        delegate?.track(
            event: DocsTracker.EventType.bitableCardEditDenyView.rawValue,
            params: ["reason": fieldModel.uneditableReason.rawValue]
        )
    }
}

private final class EnlargeTapAreaView: UIView {
    
    var enlargeInset: UIEdgeInsets = .zero
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.inset(by: enlargeInset).contains(point)
    }
}
