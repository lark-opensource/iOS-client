//
//  BTLayoutCalculator.swift
//  SKBitable
//
//  Created by zhysan on 2023/7/27.
//

import SKFoundation
import SKResource
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon

enum BTFieldLayoutStyle {
    /// 左右布局（Left-Right）
    case lr
    /// 上下布局（Top-Bottom）
    case tb
}

struct BTFieldLayoutInfo: Equatable {
    /// 布局结构
    var style: BTFieldLayoutStyle = .lr
    
    /// 整个字段的区域大小
    var cellSize: CGSize = .zero
    
    /// 字段值区域大小
    var valueSize: CGSize = .zero
    
    /// 字段编辑按钮的大小
    var editSize: CGSize = .zero
    
    /// 字段值错误信息区域大小
    var errorSize: CGSize = .zero
    
    /// 主内容区域的 Inset
    var contentInset: UIEdgeInsets = .zero
}

struct BTFV2Const {
    static var debugEnable = false
    
    struct Dimension {
        /// Cell 内容的水平 Padding
        static let contentDefaultPaddingH: CGFloat = 16.0
        
        /// Cell 内容的垂直 Padding（默认）
        static let contentDefaultPaddingV: CGFloat = 16.0
        
        /// 左右结构下，字段名与字段值间的水平距离
        static let nameValueLRSpace: CGFloat = 12.0
        
        /// 上下结构下，字段名与字段值间的垂直距离
        static let nameValueTBSpace: CGFloat = 8.0
        
        
        /// 字段值功能按钮与字段值区域水平间隔
        static let valueAssistHSpace: CGFloat = 12.0
        
        /// 字段值功能按钮（带文本）高度
        static let valueFullAssistH: CGFloat = 22.0
        
        /// 加宽型功能按钮外部容器宽度（级联字段加号）
        static let valueAssistBtnWidenWidth: CGFloat = 32.0
        
        /// 字段值功能按钮外部容器尺寸
        static let valueAssistBtnExternalSize: CGFloat = 24.0
        
        /// 字段值功能按钮外部容器尺寸
        static let valueAssistDashBtnExtSize: CGFloat = 32.0
        
        /// 字段值功能按钮内部图标尺寸
        static let valueAssistBtnInternalSize: CGFloat = 16.0
        
        /// 字段值功能新增内容虚线边框按钮尺寸
        static let valueAssistDashedBtnInternalSize: CGFloat = 34.0
        
        /// 字段值和错误信息之间的垂直距离
        static let valueErrorTBSpace: CGFloat = 8.0
        
        /// 字段值通用最大行数
        static let valueCommonMaxRowCount = 10
        
        /// 单行左右布局时，单个 Cell 的默认高度
        static let designSingleLineCellHeight = 56.0
        
        /// 文本高度最大限制
        static let textFieldMaxTextHeight: CGFloat = 232.0
        
        static let optionUserLinkFieldMaxHeight: CGFloat = 260.0
    }
    
    struct Font {
        /// 字段名字体
        static let fieldName: UIFont = UDFont.body2
        
        static let fieldValue: UIFont = UDFont.body0
        
        static let fieldError: UIFont = UDFont.body2
    }
    
    struct Color {
        
        static let fieldNameText: UIColor = UDColor.textCaption
        
        static let fieldNameIcon: UIColor = UDColor.iconN2
        
        static let fieldValueText: UIColor = UDColor.textTitle
        
        static let fieldErrorText: UIColor = UDColor.functionDanger500
    }
    
    struct TextAttributes {
        static let fieldName: [NSAttributedString.Key: Any] = {
            var attributes = BTUtil.getFigmaHeightAttributes(font: Font.fieldName, alignment: .left)
            attributes[.foregroundColor] = Color.fieldNameText
            return attributes
        }()
        
        static let fieldValue: [NSAttributedString.Key: Any] = {
            var attributes = BTUtil.getFigmaHeightAttributes(font: Font.fieldValue, alignment: .left)
            attributes[.foregroundColor] = Color.fieldValueText
            return attributes
        }()
        
        static let fieldError: [NSAttributedString.Key: Any] = {
            var attributes = BTUtil.getFigmaHeightAttributes(font: Font.fieldError, alignment: .left)
            attributes[.foregroundColor] = Color.fieldErrorText
            return attributes
        }()
    }
    
}

class BTFieldLayoutCalculator {
    
    // MARK: - public data structure
    
    // MARK: - public funcs
    
    static func calculateLayoutInfoForField(_ field: BTFieldModel) -> BTFieldLayoutInfo {
        var info = BTFieldLayoutInfo()
        
        let cellW: CGFloat = field.width
        
        var padding = UIEdgeInsets(
            horizontal: BTFV2Const.Dimension.contentDefaultPaddingH,
            vertical: BTFV2Const.Dimension.contentDefaultPaddingV
        )
        let contentW = cellW - padding.left - padding.right
        
        // 1. 计算字段名的布局
        let nameIconW = BTFieldUIDataName.Const.nameIconSize + BTFieldUIDataName.Const.nameIconRightMargin
        let nameTextMaxW = contentW - nameIconW
        let nameLayout = calculateFieldNameTextSizeForField(field, maxWidth: nameTextMaxW)
        let nameTotalW = nameIconW + nameLayout.fitSize.width + BTFV2Const.Dimension.nameValueLRSpace
        
        let editBtnSize = field.editButtonSize
        let editTotalW = editBtnSize.width > 0 ? editBtnSize.width + BTFV2Const.Dimension.valueAssistHSpace : 0
        
        // 2. 计算字段值布局以及布局结构
        let maxValueWidthForSingleLine: CGFloat
        if nameLayout.numberOfLines > 1 {
            maxValueWidthForSingleLine = 0
        } else {
            maxValueWidthForSingleLine = contentW - nameTotalW - editTotalW
        }
        let maxValueWidthForMultipleLine = contentW - editTotalW

        // 3. 根据剩余宽度数据，计算字段值的布局结构
        let (style, valueSize) = calculateFieldValueSizeForField(
            field,
            maxWidthForSingleLine: maxValueWidthForSingleLine,
            maxWidthForMultipleLine: maxValueWidthForMultipleLine
        )
        
        // 设置最终布局结构数据
        info.style = style
        
        // 设置最终编辑按钮 size
        switch style {
        case .lr:
            // 左右布局时，直接按编辑按钮的原始尺寸展示
            info.valueSize = valueSize
            info.editSize = editBtnSize
        case .tb:
            switch field.editType {
            case .none, .fixedTopRightRoundedButton:
                // 上下布局时，让 value container 占满左侧区域，固定右上侧的按钮按原始尺寸展示
                info.valueSize = CGSize(width: maxValueWidthForMultipleLine, height: valueSize.height)
                info.editSize = editBtnSize
            case .emptyRoundDashButton, .dashLine, .centerVerticallyWithIconText, .placeholder:
                if field.isValueEmpty {
                    // 上下布局时，这几种按钮如果 value 为空，让编辑按钮占满宽度，内容居中或者靠左展示
                    info.valueSize =  .zero
                    info.editSize = CGSize(width: contentW, height: editBtnSize.height)
                } else {
                    // 这几种按钮正常不会走这里
                    info.valueSize = CGSize(width: maxValueWidthForMultipleLine, height: valueSize.height)
                    info.editSize = editBtnSize
                }
                
            }
        }
        
        // 计算错误信息提示的布局
        let errorLayout = calculateFieldErrorTextSizeForField(field, maxWidth: contentW)
        var errorH = errorLayout.fitSize.height
        errorH += (errorH > 0 ? BTFV2Const.Dimension.valueErrorTBSpace : 0)
        info.errorSize = CGSize(width: contentW, height: errorH)
        
        var cellH: CGFloat = 0
        switch style {
        case .lr:
            var maxH = max(nameLayout.fitSize.height, valueSize.height)
            maxH = max(maxH, editBtnSize.height)
            let limit = BTFV2Const.Dimension.designSingleLineCellHeight
            if maxH <= limit {
                // 如果单行内容不超过通用 Cell 高度，让整个高度=通用高度
                padding.top = (limit - maxH) * 0.5
                padding.bottom = (limit - maxH) * 0.5
                cellH += limit
            } else {
                // 如果单行内容超过通用 Cell 高度（目前没有这样的设计），使用默认 padding
                padding.top = BTFV2Const.Dimension.contentDefaultPaddingV
                padding.bottom = BTFV2Const.Dimension.contentDefaultPaddingV
                cellH += (maxH + padding.top + padding.bottom)
            }
            cellH += errorH
        case .tb:
            padding.top = BTFV2Const.Dimension.contentDefaultPaddingV
            padding.bottom = BTFV2Const.Dimension.contentDefaultPaddingV
            cellH += padding.top
            cellH += nameLayout.fitSize.height
            cellH += BTFV2Const.Dimension.nameValueTBSpace
            cellH += max(valueSize.height, editBtnSize.height)
            cellH += padding.bottom
            cellH += errorH
        }
        info.contentInset = padding
        info.cellSize = CGSize(width: cellW, height: cellH)
        
        return info
    }
    
    // MARK: - private business funcs
    
    private static let calculator = BTTextView().construct { it in
        _ = it.layoutManager
    }
    
    private static func calculateFieldNameTextSizeForField(_ field: BTFieldModel, maxWidth: CGFloat) -> TextLayout {
        let nameFont = BTFV2Const.Font.fieldName
        let nameAttrText = field.nameUIData.fieldNameAttributeString
        return calculateAttrTextLayout(nameAttrText,
                                       calculator: Self.calculator,
                                       textFont: nameFont,
                                       maxWidth: maxWidth,
                                       isEditing: field.isEditing,
                                       placeHoldeAttrString: field.placeHolderAttrText)
        
    }
    
    private static func calculateFieldErrorTextSizeForField(_ field: BTFieldModel, maxWidth: CGFloat) -> TextLayout {
        guard field.shouldShowErrorMsg else {
            return TextLayout(fitSize: .zero, numberOfLines: 0)
        }
        let errorFont = BTFV2Const.Font.fieldError
        let errorAttrText = NSAttributedString(string: field.errorMsg, attributes: BTFV2Const.TextAttributes.fieldError)
        return calculateAttrTextLayout(errorAttrText, calculator: Self.calculator,
                                       textFont: errorFont,
                                       maxWidth: maxWidth,
                                       isEditing: field.isEditing,
                                       placeHoldeAttrString: field.placeHolderAttrText)
    }
    
    private static func calculateFieldValueSizeForField(
        _ field: BTFieldModel,
        maxWidthForSingleLine: CGFloat,
        maxWidthForMultipleLine: CGFloat
    ) -> (style: BTFieldLayoutStyle, size: CGSize) {
        switch field.extendedType {
        case .inherent(let realType):
            switch realType.uiType {
            case .notSupport:
                let font = BTFV2Const.Font.fieldValue
                let str = BundleI18n.SKResource.Doc_Block_NoSupportFieldType
                let attrs = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
                let attrString = NSAttributedString(string: str, attributes: attrs)
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .text, .barcode, .formula, .lookup, .email:
                let font = BTFV2Const.Font.fieldValue
                let attrString = BTUtil.convert(field.textValue, font: font)
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .number, .currency:
                let font = BTFV2Const.Font.fieldValue
                let attrString = field.numberUIData.attributedText
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .autoNumber:
                let font = BTFV2Const.Font.fieldValue
                let attrString = field.autoNumberUIData.attributedText
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .checkbox:
                // 按照至少一个 item 进行计算布局
                let itemCount = max(1, field.selectValue.count)
                let itemSize = BTFieldUIDataCheckbox.Const.itemSize
                let itemSpace = BTFieldUIDataCheckbox.Const.itemSpace
                if maxWidthForSingleLine > 0 {
                    let w = CGFloat(itemCount) * (itemSize + itemSpace) - itemSpace
                    if maxWidthForSingleLine >= w {
                        return (.lr, .init(width: w, height: itemSize))
                    }
                }
                let maxColumnCount = Int((maxWidthForMultipleLine + itemSpace) / (itemSize + itemSpace))
                let columnCount = min(itemCount, maxColumnCount)
                let w = CGFloat(columnCount) * (itemSize + itemSpace) - itemSpace
                var rowCount = ceil(Double(itemCount) / Double(columnCount))
                rowCount = min(rowCount, Double(BTFV2Const.Dimension.valueCommonMaxRowCount))
                let h = rowCount * itemSize + (rowCount - 1) * itemSpace
                return (.tb, CGSize(width: w, height: h))
            case .url:
                let font = BTFV2Const.Font.fieldValue
                let attrString: NSAttributedString
                if !field.editable, field.textValue.count > 1 {
                    // 非编辑场景，需要支持多链接点击，开启 shouldUseTextAsLinkForURLSegment = true
                    attrString = BTUtil.convert(field.textValue, font: font, shouldUseTextAsLinkForURLSegment: true)
                } else {
                    // 编辑 URL 场景不支持多URL，所以不需要支持多链接点击
                    attrString = BTUtil.convert(field.textValue, font: font, shouldUseTextAsLinkForURLSegment: false)
                }
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .attachment:
                let itemCount = field.attachmentValue.count + field.pendingAttachments.count + field.uploadingAttachments.count
                let itemSize = BTFieldUIDataAttachment.Const.itemSize
                let itemSpace = BTFieldUIDataAttachment.Const.itemSpace
                if maxWidthForSingleLine > 0 {
                    let itemsWidth = itemCount > 0 ? CGFloat(itemCount) * (itemSize + itemSpace) - itemSpace : 0
                    let itemsHeight = itemCount > 0 ? itemSize : 0
                    if maxWidthForSingleLine >= itemsWidth {
                        return (.lr, .init(width: itemsWidth, height: itemsHeight))
                    }
                }
                let maxColumnCount = Int((maxWidthForMultipleLine + itemSpace) / (itemSize + itemSpace))
                let columnCount = min(itemCount, maxColumnCount)
                var rowCount = columnCount > 0 ? ceil(Double(itemCount) / Double(columnCount)) : 0
                rowCount = min(rowCount, Double(BTFV2Const.Dimension.valueCommonMaxRowCount))
                let h = max(0, rowCount * itemSize + (rowCount - 1) * itemSpace)
                return (.tb, CGSize(width: maxWidthForMultipleLine, height: h))
            case .progress:
                let itemCount = max(field.numberValue.count, 1)
                if maxWidthForSingleLine > 0, itemCount <= 1 {
                    let barWidth: CGFloat   = BTFieldUIDataProgress.Const.barMinWidth
                    let barSpaceR: CGFloat  = BTFieldUIDataProgress.Const.progressBarSpaceH
                    
                    let text = field.numberValue.first?.formattedValue ?? ""
                    let label = UILabel()
                    label.font = BTFieldUIDataProgress.Const.textFont
                    label.text = text
                    label.sizeToFit()
                    let minTextWidth = text.isEmpty ? 0 : BTFieldUIDataProgress.Const.textMinWidth
                    let textWidth = max(minTextWidth, label.bounds.width)
                    let w = barWidth + barSpaceR + textWidth
                    if maxWidthForSingleLine >= w {
                        return (.lr, CGSize(width: w, height: BTFieldUIDataProgress.Const.lineHeight))
                    }
                }
                let rowCount = min(itemCount, BTFV2Const.Dimension.valueCommonMaxRowCount)
                let h = CGFloat(rowCount) * BTFieldUIDataProgress.Const.lineHeight
                return (.tb, CGSize(width: maxWidthForMultipleLine, height: h))
            case .phone:
                let font = BTFV2Const.Font.fieldValue
                let attrs = BTFV2Const.TextAttributes.fieldValue
                let attrString = NSAttributedString(string: field.phoneStringValue, attributes: attrs)
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .singleLink, .duplexLink:
                if maxWidthForSingleLine > 0 {
                    let lrLayout = BTLinkFieldFlowLayout.calculate(field.linkedRecords, maxWidth: CGFloat.greatestFiniteMagnitude)
                    if lrLayout.size.width <= maxWidthForSingleLine {
                        return (.lr, lrLayout.size)
                    }
                }
                let tbLayout = BTLinkFieldFlowLayout.calculate(field.linkedRecords, maxWidth: maxWidthForMultipleLine)
                let w = maxWidthForMultipleLine
                let h = min(BTFV2Const.Dimension.optionUserLinkFieldMaxHeight, tbLayout.size.height)
                return (.tb, CGSize(width: w, height: h))
            case .location:
                let font = BTFV2Const.Font.fieldValue
                let attrString = field.locationAttributeText
                return calculateAttrTextLayout(
                    attrString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            case .stage:
                let trySingleLineWidth = BTStageItemFlowLayoutV2.caculateWidthForSingleLine(with: field, maxWidth: maxWidthForSingleLine)
                if trySingleLineWidth <= maxWidthForSingleLine {
                    return (.lr, CGSize(width: trySingleLineWidth, height: BTFieldV2Stage.itemHeight))
                } else {
                    let height = BTStageItemFlowLayoutV2.getLayoutInfo(with: field, containerWidth: maxWidthForMultipleLine).0
                    return (.tb, CGSize(width: maxWidthForMultipleLine, height: height))
                }
            case .rating:
                let count = max(1, field.numberValue.count)
                if count > 1 {
                    // 评分字段一行最多方一个，所以多行就直接上下排布
                    let limitCount: CGFloat = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(7.5, CGFloat(count)) : CGFloat(count)
                    let itemsHeight = BTFieldLayout.Const.ratingItemHeight * limitCount + BTFieldLayout.Const.ratingItemSpacing * CGFloat(count - 1)
                    let containerHeight: CGFloat = BTFieldLayout.Const.containerPadding + itemsHeight + BTFieldLayout.Const.containerPadding
                    return (.tb, CGSize(width: maxWidthForMultipleLine, height: containerHeight))
                } else {
                    let size = BTRatingView.ratingSizeForSingleLine(with: Int(field.property.min ?? 1), maxValue: Int(field.property.max ?? 5), maxWidth: maxWidthForSingleLine)
                    if size.width <= maxWidthForSingleLine {
                        return (.lr, size)
                    } else {
                        return (.tb, CGSize(width: min(size.width, maxWidthForMultipleLine), height: BTFieldLayout.Const.ratingItemHeight))
                    }
                }
            case .button:
                let fitSize = BTFieldUIDataButton.calculateButtonFieldFitSize(field)
                if maxWidthForSingleLine >= fitSize.width {
                    return (.lr, fitSize)
                }
                return (.tb, CGSize(width: maxWidthForMultipleLine, height: fitSize.height))
            case .singleSelect, .multiSelect:
                if maxWidthForSingleLine > 0 {
                    let (singLineSize, row) = BTFieldUIDataOption.calculateOptionFieldFitSize(field, maxLineLength: .greatestFiniteMagnitude)
                    if row <= 1 && singLineSize.width <= maxWidthForSingleLine {
                        return (.lr, singLineSize)
                    }
                }
                let (multiLineSize, _) = BTFieldUIDataOption.calculateOptionFieldFitSize(field, maxLineLength: maxWidthForMultipleLine)
                return (.tb, multiLineSize)
            case .user, .group, .createUser, .lastModifyUser:
                if maxWidthForSingleLine > 0 {
                    let (singLineSize, row) = BTFieldChatterCaculate.calculateChatterFieldFitSize(field, maxLineLength: .greatestFiniteMagnitude)
                    if row <= 1 && singLineSize.width <= maxWidthForSingleLine {
                        return (.lr, singLineSize)
                    }
                }
                let (multiLineSize, _) = BTFieldChatterCaculate.calculateChatterFieldFitSize(field, maxLineLength: maxWidthForMultipleLine)
                return (.tb, multiLineSize)
            case .dateTime, .lastModifyTime, .createTime:
                let font = BTFV2Const.Font.fieldValue
                let mutableAttributedString = BTFieldUIDataDate(fieldModel: field).getDateFieldAttr()
                return calculateAttrTextLayout(
                    mutableAttributedString,
                    font: font,
                    maxWidthForSingleLine: maxWidthForSingleLine,
                    maxWidthForMultipleLine: maxWidthForMultipleLine,
                    isEditing: field.isEditing,
                    placeHoldeAttrString: field.placeHolderAttrText
                )
            }
        default:
            return (.lr, .zero)
        }
    }
    
    // MARK: - private util funcs
    
    private struct TextLayout {
        let fitSize: CGSize
        let numberOfLines: Int
    }
    
    private struct TextLayoutCacheKey: Hashable {
        let attrText: NSAttributedString
        let textFont: UIFont
        let maxWidth: CGFloat
        let isEditing: Bool
        let maxLines: Int = 0
        let placeHoldeAttrString: NSAttributedString?
    }
    
    private static var layoutCache = LRUCache<TextLayoutCacheKey, TextLayout>(maxSize: 500)
    
    private static func calculateAttrTextLayout(
        _ attrString: NSAttributedString,
        font: UIFont,
        maxWidthForSingleLine: CGFloat,
        maxWidthForMultipleLine: CGFloat,
        isEditing: Bool,
        placeHoldeAttrString: NSAttributedString? = nil
    ) -> (style: BTFieldLayoutStyle, size: CGSize) {
        if maxWidthForSingleLine > 0 {
            let lrLayout = calculateAttrTextLayout(
                attrString,
                calculator: Self.calculator,
                textFont: font,
                maxWidth: maxWidthForSingleLine,
                isEditing: isEditing,
                maxHeight: BTFV2Const.Dimension.textFieldMaxTextHeight,
                placeHoldeAttrString: placeHoldeAttrString
            )
            if lrLayout.numberOfLines <= 1 {
                return (.lr, lrLayout.fitSize)
            }
        }
        let tbLayout = calculateAttrTextLayout(
            attrString,
            calculator: Self.calculator,
            textFont: font,
            maxWidth: maxWidthForMultipleLine,
            isEditing: isEditing,
            maxHeight: BTFV2Const.Dimension.textFieldMaxTextHeight,
            placeHoldeAttrString: placeHoldeAttrString
        )
        return (.tb, tbLayout.fitSize)
    }
    
    private static func calculateAttrTextLayout(
        _ attrText: NSAttributedString,
        calculator: UITextView,
        textFont: UIFont,
        maxWidth: CGFloat,
        isEditing: Bool,
        maxLines: Int = 0,
        maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude,
        placeHoldeAttrString: NSAttributedString? = nil
    ) -> TextLayout {
        if attrText.string.isEmpty && placeHoldeAttrString?.string.isEmpty != false {
            // 文本和 Placeholder 都为空，返回字体高度
            return TextLayout(
                fitSize: CGSize(width: 0, height: textFont.figmaHeight),
                numberOfLines: 0
            )
        }
        let cacheKey = TextLayoutCacheKey(
            attrText: attrText,
            textFont: textFont,
            maxWidth: maxWidth,
            isEditing: isEditing,
            placeHoldeAttrString: placeHoldeAttrString
        )
        if let cache = layoutCache.getCachedValue(for: cacheKey) {
            return cache
        }
        
        let fitSize: CGSize
        let textMinWidth: CGFloat
        if !attrText.string.isEmpty {
            calculator.attributedText = attrText
            calculator.textContainer.maximumNumberOfLines = maxLines
            // 计算标题文字的自适应宽高
            let maxBoxSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
            fitSize = calculator.sizeThatFits(maxBoxSize)
            if !isEditing {
                textMinWidth = 0
            } else {
                textMinWidth = fitSize.width
            }
        } else {
            calculator.attributedText = placeHoldeAttrString
            calculator.textContainer.maximumNumberOfLines = 1
            let maxBoxSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
            fitSize = calculator.sizeThatFits(maxBoxSize)
            textMinWidth = fitSize.width
        }
        
        calculator.frame = CGRect(origin: .zero, size: fitSize)
        
        // 计算行数
        let numberOfGlyphs = calculator.layoutManager.numberOfGlyphs
        var index = 0, numberOfLines = 0
        var lineRange = NSRange(location: NSNotFound, length: 0)
        while index < numberOfGlyphs {
            calculator.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        
        if calculator.attributedText.docs.containsNewline {
            // 文本内包含换行，则至少有两行
            numberOfLines = max(2, numberOfLines)
        }
        
        // 文本最大高度
        let fixHeight: CGFloat
        if UserScopeNoChangeFG.ZYS.baseFieldNameHeightNoLimitRevert {
            // 这个函数里面不应该写死高度限制，是否要限制最大高度应该由调用方决定：
            // 比如字段值高度计算时，需要限制高度;但是字段名高度计算时，不应该限制
            fixHeight = min(BTFV2Const.Dimension.textFieldMaxTextHeight, fitSize.height)
        } else {
            fixHeight = min(maxHeight, fitSize.height)
        }
        // 文本最小宽度应该是placeholder的宽度
        let fixWidth = max(textMinWidth, fitSize.width)
        let textLayout = TextLayout(fitSize: CGSize(width: fixWidth, height: fixHeight), numberOfLines: numberOfLines)
        layoutCache.setCacheValue(textLayout, for: cacheKey)
        return textLayout
    }
}

private final class LRUCache<Key: Hashable, Value> {
    private final class CacheNode<Key, Value> {
        let key: Key
        var value: Value
        var previous: CacheNode?
        var next: CacheNode?

        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    private var cache: [Key: CacheNode<Key, Value>] = [:]
    private var head: CacheNode<Key, Value>?
    private var tail: CacheNode<Key, Value>?
    private let maxSize: Int

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    func getCachedValue(for key: Key) -> Value? {
        if let node = cache[key] {
            moveNodeToHead(node)
            return node.value
        }
        return nil
    }

    func setCacheValue(_ value: Value, for key: Key) {
        if let node = cache[key] {
            node.value = value
            moveNodeToHead(node)
        } else {
            let newNode = CacheNode(key: key, value: value)
            cache[key] = newNode
            insertNodeAtHead(newNode)

            if cache.count > maxSize {
                if let tailNode = tail {
                    removeNode(tailNode)
                    cache.removeValue(forKey: tailNode.key)
                }
            }
        }
    }

    private func moveNodeToHead(_ node: CacheNode<Key, Value>) {
        if node === head {
            return
        }

        removeNode(node)
        insertNodeAtHead(node)
    }

    private func insertNodeAtHead(_ node: CacheNode<Key, Value>) {
        node.previous = nil
        node.next = head

        if head == nil {
            tail = node
        } else {
            head?.previous = node
        }

        head = node
    }

    private func removeNode(_ node: CacheNode<Key, Value>) {
        node.previous?.next = node.next
        node.next?.previous = node.previous

        if node === head {
            head = node.next
        }

        if node === tail {
            tail = node.previous
        }

        node.previous = nil
        node.next = nil
    }
}
