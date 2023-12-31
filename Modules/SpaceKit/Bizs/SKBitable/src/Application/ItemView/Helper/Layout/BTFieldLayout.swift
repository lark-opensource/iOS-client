//
// Created by duanxiaochen.7 on 2022/3/15.
// Affiliated with SKBitable.
//
// Description: BTRecord 里 collectionView 的 layout 对象
// swiftlint:disable file_length

import UIKit
import SKCommon
import SKBrowser
import SKFoundation
import RxDataSources
import UniverseDesignColor

final class BTFieldLayoutAttributes: UICollectionViewLayoutAttributes {
    var layoutInfo: BTFieldLayoutInfo?
}

final class BTFieldLayout: UICollectionViewFlowLayout {
    var context: BTContext?
    var hearderViewHeight: CGFloat = 0 {
        didSet {
            if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
                return
            }
            if oldValue != hearderViewHeight {
                setNeedsUpdateLayoutAttributes(for: [BTFieldExtendedType.itemViewHeader.mockFieldID])
                invalidateLayout()
            }
        }
    }
    // ui model
    private var latestSnapshot = BTRecordModel() {
        didSet {
            fieldIdentityList = latestSnapshot.wrappedFields.map({ $0.identity })
            fieldsModel.removeAll()
            for fieldModel in latestSnapshot.wrappedFields {
                fieldsModel[fieldModel.identity] = fieldModel
            }
        }
    }
    
    // data model
    private var realRecordModel = BTRecordModel()

    private var fieldIdentityList: [String] = []

    private var fieldsModel: [String: BTFieldModel] = [:]

    private var fieldIDsThatNeedUpdateLayoutAttributes: [String] = []
    
    private var cachedLayoutAttributes: [String: BTFieldLayoutAttributes] = [:]
    
    var descriptionHeights: [String: CGFloat] = [:]

    private var currentContenSize: CGSize = .zero
    
    // BTTextView 默认的textInset
    private let defaultTextContainerInset: UIEdgeInsets

    /// 设置需要重新计算高度的字段id
    func setNeedsUpdateLayoutAttributes(for fieldIDs: [String]) {
        fieldIDs.forEach { fieldID in
            descriptionHeights[fieldID] = nil
            cachedLayoutAttributes[fieldID] = nil
        }
        fieldIDsThatNeedUpdateLayoutAttributes.append(contentsOf: fieldIDs)
    }

    override func prepare() {
        super.prepare()
        updateLayoutAttributesIfNeeded()
    }
    
    override init() {
        let textView = BTTextView().construct { it in
            _ = it.layoutManager
        }
        defaultTextContainerInset = textView.textContainerInset
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadLayoutAttributes() {
        descriptionHeights = [:]
        cachedLayoutAttributes = [:]
        updateLayoutAttributesIfNeeded()
    }
    
    func getTheCalculatedLayoutAttrbutesForField(_ field: BTFieldModel) -> BTFieldLayoutAttributes?{
        cachedLayoutAttributes[field.identity]
    }

    private func updateLayoutAttributesIfNeeded() {
        if cachedLayoutAttributes.isEmpty {
            fieldIDsThatNeedUpdateLayoutAttributes = fieldIdentityList
        }
        if !fieldIDsThatNeedUpdateLayoutAttributes.isEmpty {
            for fieldID in fieldIDsThatNeedUpdateLayoutAttributes {
                cachedLayoutAttributes[fieldID] = layoutAttributesForFieldID(fieldID)
            }
            ensureFieldsLinearOrder()
            fieldIDsThatNeedUpdateLayoutAttributes.removeAll()

            updateLayoutAttributesIndexIfNeeded()
        }
    }

    private func updateLayoutAttributesIndexIfNeeded() {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        /*
         1. attributes 缓存只会更新对应 field
         2. 所以当插入一个 field 时，这个 field 后面所有 field 的 attributes 缓存里的 indexPath 都会错误
         3. 目前来看，插入一个 field，后面所有 field 的 attributes 不需要重新计算, 所有只是在这里简单更新一下 indexPath
         */
        for (fieldId, attributes) in cachedLayoutAttributes {
            guard let index = fieldIdentityList.firstIndex(of: fieldId) else {
                continue
            }
            attributes.indexPath.item = index
        }
    }

    private func ensureFieldsLinearOrder() {
        var lastItemMaxY: CGFloat = 0
        for fieldID in fieldIdentityList {
            if let layoutAttributes = cachedLayoutAttributes[fieldID] {
                let height = layoutAttributes.size.height
                
                if fieldID != BTFieldExtendedType.itemViewTabs.mockFieldID {
                    layoutAttributes.frame = CGRect(x: 0, y: lastItemMaxY, width: layoutAttributes.size.width, height: height)
                }
                lastItemMaxY += height
            }
        }
    }

    private func layoutAttributesForFieldID(_ fieldID: String) -> BTFieldLayoutAttributes? {
        guard let index = fieldIdentityList.firstIndex(of: fieldID), let fieldModel = fieldsModel[fieldID] else {
            // return nil 可以清掉缓存
            return nil
        }
        let attr: BTFieldLayoutAttributes
        if let exist = cachedLayoutAttributes[fieldID] {
            attr = exist
        } else {
            let newIndexPath = IndexPath(item: index, section: 0)
            attr = BTFieldLayoutAttributes(forCellWith: newIndexPath)
        }
        if fieldModel.usingLayoutV2 {
            let info = BTFieldLayoutCalculator.calculateLayoutInfoForField(fieldModel)
            attr.layoutInfo = info
            attr.frame.size = info.cellSize
            let zIndex = zIndexForField(withID: fieldID)
            attr.zIndex = zIndex
        } else {
            let newHeight = heightForField(withID: fieldID)
            attr.frame.size = CGSize(width: fieldModel.width, height: newHeight)
        }
        if UserScopeNoChangeFG.ZJ.btCardReform {
            let zIndex = zIndexForField(withID: fieldID)
            attr.zIndex = zIndex
        }
        return attr
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        if collectionView.bounds.size != newBounds.size {
            reloadLayoutAttributes()
            return true
        } else if context?.shouldShowItemViewTabs == true {
            updateItemViewTabsLayout()
            return true
        } else {
            return false
        }
    }

    override var collectionViewContentSize: CGSize {
        guard !latestSnapshot.wrappedFields.isEmpty else { return .zero }
        if latestSnapshot.viewMode.isForm {
            if let submitItemLayoutAttributes = cachedLayoutAttributes[BTFieldExtendedType.formSubmit.mockFieldID] {
                currentContenSize = CGSize(width: submitItemLayoutAttributes.size.width, height: submitItemLayoutAttributes.frame.maxY)
            } else if let unReadableLayoutAttributes = cachedLayoutAttributes[BTFieldExtendedType.unreadable.mockFieldID] {
                currentContenSize = CGSize(width: unReadableLayoutAttributes.size.width, height: unReadableLayoutAttributes.frame.maxY)
            } else if let recordLimitLayoutAttributes = cachedLayoutAttributes[BTFieldExtendedType.recordCountOverLimit.mockFieldID] {
                currentContenSize = CGSize(width: recordLimitLayoutAttributes.size.width, height: recordLimitLayoutAttributes.frame.maxY)
            } else {
                reloadLayoutAttributes()
                guard let submitItemLayoutAttributes = cachedLayoutAttributes[BTFieldExtendedType.formSubmit.mockFieldID] else {
                    spaceAssertionFailure("no layout attributes for bottom most item in cache!")
                    currentContenSize = .zero
                    return .zero
                }
                currentContenSize = CGSize(width: submitItemLayoutAttributes.size.width, height: submitItemLayoutAttributes.frame.maxY)
            }
        } else {
            // 经过咨询：这里原来的含义是「取最下边的进行计算」，之前的假设是「最下边一定是delete，所以用delete计算」
            if let lastFieldID = fieldIdentityList.last, let lastAttr = cachedLayoutAttributes[lastFieldID] {
                let height = lastAttr.frame.maxY + BTFieldLayout.Const.deleteButtonBottomInset
                currentContenSize = CGSize(width: lastAttr.size.width, height: height)
            } else {
                reloadLayoutAttributes()
                guard let lastFieldID = fieldIdentityList.last, let lastAttr = cachedLayoutAttributes[lastFieldID] else {
                    spaceAssertionFailure("no layout attributes for bottom most item in cache!")
                    currentContenSize = .zero
                    return .zero
                }
                
                let height = lastAttr.frame.maxY + BTFieldLayout.Const.deleteButtonBottomInset
                currentContenSize = CGSize(width: lastAttr.size.width, height: height)
            }
        }

        return currentContenSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var newLayoutAttributes = [UICollectionViewLayoutAttributes]()

        cachedLayoutAttributes.forEach { (fieldIdentity, attr)  in
            if rect.intersects(attr.frame) &&
               fieldIdentityList.contains(where: { $0 == fieldIdentity }) {
                 if #available(iOS 13.1, *) {
                     newLayoutAttributes.append(attr)
                }

                if currentContenSize != .zero,
                    attr.frame.minY > currentContenSize.height {
                    return
                }
                newLayoutAttributes.append(attr)
            } else {
                return
            }
        }

        if context?.shouldShowItemViewTabs == true,
           let itemViewTabsAttributes = layoutItemTabs() {
            //添加itemViewTabs
            newLayoutAttributes.append(itemViewTabsAttributes)
        }

        return newLayoutAttributes
    }
    
    private func layoutItemTabs() -> UICollectionViewLayoutAttributes? {
        let fieldId = BTFieldExtendedType.itemViewTabs.mockFieldID
        guard let itemViewTabsIndex = fieldIdentityList.firstIndex(where: { $0 == fieldId }) else {
            return nil
        }
        var currentAttributes: UICollectionViewLayoutAttributes
        if let attributes = cachedLayoutAttributes[fieldId] {
            currentAttributes = attributes
        } else {
            let attributes = BTFieldLayoutAttributes(forCellWith: IndexPath(item: itemViewTabsIndex, section: 0))
            currentAttributes = attributes
            cachedLayoutAttributes[fieldId] = attributes
        }
        
        updateItemViewTabsLayout()

        return currentAttributes
    }
    
    private func updateItemViewTabsLayout() {
        guard let attributes = cachedLayoutAttributes[BTFieldExtendedType.itemViewTabs.mockFieldID] else {
            return
        }
        let attachmentCoverHeight =
        context?.shouldShowAttachmentCover == true ? BTItemViewBannerView.bannerHeight(itemViewSize: latestSnapshot.size) : 0
        let titleFieldHeight = cachedLayoutAttributes[BTFieldExtendedType.itemViewHeader.mockFieldID]?.frame.height ?? 0
        let catalogueHeight = (!UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable && context?.shouldShowItemViewCatalogue == true) ? Const.itemViewCatalogueHeightWithTab : 0
        var sectionHeaderY = titleFieldHeight + attachmentCoverHeight + catalogueHeight
        let collectionViewContentOffsetY = collectionView?.contentOffset.y ?? 0

        if collectionViewContentOffsetY >= sectionHeaderY - hearderViewHeight {
            sectionHeaderY = collectionViewContentOffsetY + hearderViewHeight
            let originHeaderZIndex = Int(collectionView?.layer.zPosition ?? 0)
            attributes.zIndex = originHeaderZIndex >= Self.headerZIndex() ? originHeaderZIndex : Self.headerZIndex()
        }

        attributes.frame = CGRect(origin: CGPoint(x: 0, y: sectionHeaderY),
                                  size: CGSize(width: latestSnapshot.width, height: BTFieldLayout.Const.itemViewTabsHeight))
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < fieldIdentityList.count else {
            // https://slardar.bytedance.net/node/app_detail/?region=cn&os=iOS&aid=462391&type=app&lang=zh#/abnormal/detail/crash/aa27242b29d80032074a0ed24aca9c6c?params=%7B%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22start_time%22%3A1701673680%2C%22end_time%22%3A1702278480%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22event_index%22%3A1%7D
            // 字段被删除时布局不能返回nil，会导致crash，这里返回一个假的布局，因为字段已经被删除，返回假布局不会影响显示
            return UserScopeNoChangeFG.ZJ.btItemViewDiffCrashFixDisable ? nil : BTFieldLayoutAttributes(forCellWith: indexPath)
        }
        return cachedLayoutAttributes[fieldIdentityList[indexPath.item]]
    }
}

// MARK: - Diffing
extension BTFieldLayout {

    func reloadModel(_ model: BTRecordModel, _ dataModel: BTRecordModel) {
        latestSnapshot = model
        realRecordModel = dataModel
        reloadLayoutAttributes()
    }

    func acceptSnapshot(_ snapshot: BTRecordModel, _ realRecordModel: BTRecordModel, completion: ((Bool, [Changeset<BTRecordModel>]) -> Void)? = nil) {
        self.realRecordModel = realRecordModel
        if fieldIdentityList.isEmpty || cachedLayoutAttributes.isEmpty {
            latestSnapshot = snapshot
            updateLayoutAttributesIfNeeded()
            return
        }
        var differences = [Changeset<BTRecordModel>]()
        do {
            differences = try Diff.differencesForSectionedView(initialSections: [latestSnapshot], finalSections: [snapshot])
        } catch {
            DocsLogger.btError("[DIFF] [Field] diffing record model failed with error \(error.localizedDescription)")
        }
        guard !differences.isEmpty else {
            completion?(false, [])
            return
        }

        UIView.performWithoutAnimation {
            for difference in differences {
                guard let finalSectionForThisStep = difference.finalSections.first else {
                    latestSnapshot = snapshot
                    reloadLayoutAttributes()
                    break
                }
                latestSnapshot = finalSectionForThisStep
                
                if UserScopeNoChangeFG.ZJ.btCardReform {
                    if DifferencesCompletionManager.hasDeleteOrInsertOrMove(of: difference) {
                        latestSnapshot = snapshot
                        deleteItems(atIndices: difference.deletedItems.map(\.itemIndex))
                        insertItems(atIndices: difference.insertedItems.map(\.itemIndex))
                        difference.movedItems.forEach { (from: ItemPath, to: ItemPath) in
                            moveItem(fromIndex: from.itemIndex, toIndex: to.itemIndex)
                        }
                    }
                } else {
                    latestSnapshot = finalSectionForThisStep
                    deleteItems(atIndices: difference.deletedItems.map(\.itemIndex))
                    insertItems(atIndices: difference.insertedItems.map(\.itemIndex))
                    difference.movedItems.forEach { (from: ItemPath, to: ItemPath) in
                        moveItem(fromIndex: from.itemIndex, toIndex: to.itemIndex)
                    }
                }
                
                updateItems(atIndices: difference.updatedItems.map(\.itemIndex))
                updateLayoutAttributesIfNeeded()
                if !UserScopeNoChangeFG.YY.bitableFieldLayoutFixDisable {
                    invalidateLayout()
                }
                completion?(true, [difference])
            }
        }
    }

    func deleteItems(atIndices indices: [Int]) {
        guard !indices.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Field] delete layout items \(indices), current items count: \(latestSnapshot.wrappedFields.count)")
        for index in indices {
            cachedLayoutAttributes.filter { (_, value) in
                value.indexPath.item == index
            }.forEach { (key, _) in
                cachedLayoutAttributes[key] = nil
            }
        }
        var fieldIDs: [String] = []
        for field in latestSnapshot.wrappedFields {
            fieldIDs.append(field.identity)
        }
        setNeedsUpdateLayoutAttributes(for: fieldIDs)
    }

    func insertItems(atIndices indices: [Int]) {
        guard !indices.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Field] insert layout items \(indices), current items count: \(latestSnapshot.wrappedFields.count)")
        invalidateItems(atIndices: indices)
    }

    func updateItems(atIndices indices: [Int]) {
        guard !indices.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Field] update layout item \(indices), current items count: \(latestSnapshot.wrappedFields.count)")
        invalidateItems(atIndices: indices)
    }

    func moveItem(fromIndex oldIndex: Int, toIndex newIndex: Int) {
        DocsLogger.btInfo("[DIFF] [Field] move layout item from \(oldIndex) to \(newIndex), current items count: \(latestSnapshot.wrappedFields.count)")
        guard 0 <= oldIndex, oldIndex < latestSnapshot.wrappedFields.count,
              0 <= newIndex, newIndex < latestSnapshot.wrappedFields.count
        else { return }
        setNeedsUpdateLayoutAttributes(for: [latestSnapshot.wrappedFields[oldIndex].identity,
                                             latestSnapshot.wrappedFields[newIndex].identity])
    }

    private func invalidateItems(atIndices indices: [Int]) {
        var fieldIDs: [String] = []
        for index in indices {
            guard 0 <= index, index < latestSnapshot.wrappedFields.count else {
                spaceAssertionFailure("[DIFF] [Field] index out of bounds")
                break
            }
            fieldIDs.append(latestSnapshot.wrappedFields[index].identity)
        }
        setNeedsUpdateLayoutAttributes(for: fieldIDs)
    }
}


// MARK: - Calculating

private extension BTFieldLayout {

    /** 高度推导顺序：从下至上
        -----------------------------------------
           /\                |
          /||\      (fieldVerticalInset)
           ||                |
           ||     icon? - fieldName             [horizontalStackView]
           ||                |
           ||  (fieldElementVerticalSpacing / 2)?
           ||                |                   --------------------
           ||          descriptionText?                   ^
           ||                |                           /|\
           ||    (fieldElementVerticalSpacing)            |
           ||                |                            |
           ||            container                 verticalStackView
           ||                |                            |
           ||    (fieldElementVerticalSpacing)?           |
           ||                |                           \|/
           ||             errorMsg?                       v
           ||                |                   --------------------
           ||       (fieldVerticalInset)
           ||                |
        ------------------------------------------
     */
    func heightForField(withID fieldID: String) -> CGFloat {
        guard let fieldModel = fieldsModel[fieldID] else { return 0 }
        let cardWidth = fieldModel.width
        let stageContentWidth = cardWidth - Const.normalFieldContainerLeftRightMarginInStage * 2
        var contentWidth = cardWidth - Const.containerLeftRightMargin * 2
        if fieldModel.isInStage {
            contentWidth = stageContentWidth
        }
        
        if fieldModel.usingLayoutV2 {
            // 这里要用 usingLayoutV2 判断，表单视图还使用了旧版布局，不能使用新布局计算
            contentWidth = cardWidth - Const.newContainerLeftRightMargin * 2
        }
        
        // 最开始把 field 顶部的 padding 加上
        var finalHeight = Const.fieldVerticalInset // field.bottom -> (errorMsg ?? container).bottom

        // 先计算内容区域高度
        switch fieldModel.extendedType {
        case .formHeroImage:
            return Const.formHeroImageHeight
        case .customFormCover:
            return contentWidth * 8 / 25
        case .attachmentCover:
            let itemViewSize = CGSize(width: cardWidth, height: fieldModel.itemViewHeight)
            return BTItemViewBannerView.bannerHeight(itemViewSize: itemViewSize)
        case .formTitle:
            return calculateFormTitleHeight(fieldModel: fieldModel, maxWidth: contentWidth)
        case .inherent:
            let errorMsg = fieldModel.errorMsg
            if !errorMsg.isEmpty {
                finalHeight += Const.errorMsgHeight
                finalHeight += Const.fieldElementVerticalSpacing // errorMsg.top -> container.bottom
            }
            finalHeight += calculateFieldContainerHeight(withFieldModel: fieldModel, containerWidth: contentWidth)
            finalHeight += Const.fieldElementVerticalSpacing // container.top -> (descriptionText ?? fieldName).top

        case .hiddenFieldsDisclosure:
            return Const.disclosureItemHeight

        case .formSubmit:
            return Const.formSubmitHeight
        case .unreadable:
            return Const.unreadableHeight
        case .recordCountOverLimit:
            return BTFormRecordOverLimitCell.contentHeight(with: contentWidth)
        case .stageDetail:
            return Const.stageDetailNormalHeight + (fieldModel.isStageCancel ? 40 : 0)
        case .itemViewTabs:
            return Const.itemViewTabsHeight
        case .itemViewHeader:
            return calculateItemViewTitleHeight(fieldModel: fieldModel, maxWidth: contentWidth)
        case .itemViewCatalogue:
            return calculateItemViewCatalogueHeight(fieldModel: fieldModel)
        }

        let isForm = fieldModel.isInForm
        var shouldShowDescriptionIndicator = false
        var shouldShowDescriptionInField = false
        var shouldLimitDescriptionLines = false
        var descriptionSegments = [BTRichTextSegmentModel]()
        if let segments = fieldModel.description?.content, !segments.isEmpty {
            descriptionSegments = segments
            shouldShowDescriptionIndicator = !isForm
            shouldShowDescriptionInField = isForm
            shouldLimitDescriptionLines = fieldModel.isDescriptionTextLimited
        }

        // 再计算表单场景下的描述高度（夹在内容和字段名之间的部分）
        if shouldShowDescriptionInField {
            let font = Const.fieldDescriptionFont
            let descriptionAttrText = BTUtil.convert(descriptionSegments,
                                                     font: font,
                                                     plainTextColor: UDColor.textCaption)
            let fullDescHeight = calculateTextHeight(descriptionAttrText, font: font, inWidth: contentWidth)
            let lineHeight = Const.fieldDescriptionFont.figmaHeight
            if fullDescHeight <= BTDescriptionView.maxNumberOfLines * lineHeight && !shouldLimitDescriptionLines {
                // 在竖屏时点击了展开，转到横屏时可能由于宽度足够不再需要展示 limit button，这种情况下需要修正 flag，不然横屏下就会多出来收起按钮
                shouldLimitDescriptionLines = true
            }
            let descriptionHeight: CGFloat
            if shouldLimitDescriptionLines {
                descriptionHeight = min(fullDescHeight, BTDescriptionView.maxNumberOfLines * lineHeight)
            } else {
                descriptionHeight = fullDescHeight + lineHeight // 多出来的一行是收起按钮
            }
            descriptionHeights[fieldModel.identity] = descriptionHeight
            finalHeight += descriptionHeight
            finalHeight += Const.fieldElementVerticalSpacing / 2 // descriptionText.top -> fieldName.bottom
        }

        // 最后计算字段名的高度
        let fieldNameAttributedString = NSMutableAttributedString(string: fieldModel.name)
        if fieldModel.required && isForm {
            let asterisk = NSMutableAttributedString(string: "*")
            fieldNameAttributedString.append(asterisk)
        }
        let fieldNameFont = isForm ? Const.formQuestionFont : Const.fieldNameFont
        if shouldShowDescriptionIndicator {
            fieldNameAttributedString.append(NSMutableAttributedString(string: "ⓘ"))
        }
        let attributes = BTUtil.getFigmaHeightAttributes(font: fieldNameFont, alignment: .left)
        fieldNameAttributedString.addAttributes(attributes, range: NSRange(location: 0, length: fieldNameAttributedString.length))
        if !isForm { // 卡片场景下需要减去字段名左边的 icon
            contentWidth -= Const.fieldIconWidthHeight + Const.fieldIconRightPadding
        }
        // stage下的PrimaryField只有两行
        finalHeight += calculateTextHeight(fieldNameAttributedString,
                                           font: fieldNameFont,
                                           inWidth: contentWidth,
                                           numberOfLines: fieldModel.isPrimaryField ? 2 : 0)

        // 最后加上 field 顶部的 padding
        finalHeight += Const.fieldVerticalInset // field.top -> fieldName.top

        return finalHeight
    }

    private func zIndexForField(withID fieldID: String) -> Int {
        guard let fieldModel = fieldsModel[fieldID] else { return 1024 }
        switch fieldModel.extendedType {
        case .attachmentCover:
            return 1022
        case .itemViewHeader:
            return 1023
        default:
            return 1024
        }
    }

    private static func headerZIndex() -> Int {
        return 1025
    }

    // 该方法只返回 container 的高度，也就是内容高度，所以只看 metatype，不会涉及到特殊类型 cell
    // swiftlint:disable cyclomatic_complexity
    func calculateFieldContainerHeight(withFieldModel fieldModel: BTFieldModel, containerWidth: CGFloat) -> CGFloat {
        let textMaxHeight = fieldModel.isPrimaryField ?
            Const.textFieldMaxTextHeightInStage : Const.textFieldMaxTextHeight
        let font = Const.getFont(isPrimaryField: fieldModel.isPrimaryFieldInStage)
        let textContainerInset = fieldModel.isPrimaryFieldInStage ? Const.textContainerInsetInStageOfPrimaryField : Const.normalTextContainerInset
        switch fieldModel.extendedType {
        case .inherent(let compositeType):
            switch compositeType.uiType {
            case .text, .barcode, .email:
                let hasAssit = fieldModel.editable && (fieldModel.allowedEditModes.scan ?? false)
                let extraWidth = hasAssit ? Const.rightAssistIconWidth + Const.containerPadding : 0
                let textWidth = containerWidth - extraWidth
                return calculateTextFieldContainerHeight(textValue: fieldModel.textValue,
                                                         font: font,
                                                         maxHeight: textMaxHeight,
                                                         containerWidth: textWidth,
                                                         textContainerInset: textContainerInset,
                                                         useCache: true)
            case .url:
                // 这里 url 多了个编辑按钮的宽度
                let hasAssit = fieldModel.editable
                let extraWidth = hasAssit ? Const.rightAssistIconWidth + Const.containerPadding : 0
                let textWidth = containerWidth - extraWidth
                return calculateTextFieldContainerHeight(textValue: fieldModel.textValue,
                                                         font: Const.commonTextFieldFont,
                                                         containerWidth: textWidth,
                                                         textContainerInset: textContainerInset)
            case .formula, .lookup:
                return calculateTextFieldContainerHeight(textValue: fieldModel.textValue,
                                                         font: font,
                                                         maxHeight: textMaxHeight,
                                                         containerWidth: containerWidth,
                                                         textContainerInset: textContainerInset)
            case .autoNumber:
                return calculateAutoNumberFieldContainerHeight(fieldModel: fieldModel.autoNumberValue,
                                                               font: font,
                                                               maxHeight: textMaxHeight,
                                                               containerWidth: containerWidth,
                                                               textContainerInset: textContainerInset)
            case .number, .currency:
                return calculateNumberFieldContainerHeight(fieldModel: fieldModel.numberValue,
                                                           font: font,
                                                           maxHeight: textMaxHeight,
                                                           containerWidth: containerWidth,
                                                           textContainerInset: textContainerInset)
            case .progress:
                return calculateProgressFieldContainerHeight(fieldModel: fieldModel.numberValue, editable: fieldModel.editable, containerWidth: containerWidth)
            case .singleSelect, .multiSelect:
                return calculateOptionFieldContainerHeight(fieldModel: fieldModel, editable: fieldModel.editable, containerWidth: containerWidth)
                
            case .dateTime, .lastModifyTime, .createTime:
                return calculateDateFieldContainerHeight(value: fieldModel.dateValue,
                                                         font: font,
                                                         maxHeight: textMaxHeight,
                                                         containerWidth: containerWidth,
                                                         textContainerInset: textContainerInset)

            case .user, .lastModifyUser, .createUser:
                return calculateChatterFieldContainerHeight(chatters: fieldModel.users, editable: fieldModel.editable, containerWidth: containerWidth)
            case .attachment:
                let count = fieldModel.attachmentValue.count + fieldModel.uploadingAttachments.count + fieldModel.pendingAttachments.count
                return calculateAttachmentFieldContainerHeight(attachmentsCount: count, editable: fieldModel.editable, containerWidth: containerWidth)

            case .singleLink, .duplexLink:
                return calculateLinkFieldContainerHeight(linkedRecords: fieldModel.linkedRecords, editable: fieldModel.editable, containerWidth: containerWidth)

            case .checkbox:
                return Const.emptyContainerHeight

            case .location:
                return calculateLocationFieldContainerHeight(fieldModel: fieldModel,
                                                             containerWidth: containerWidth,
                                                             textContainerInset: textContainerInset)
            case .notSupport:
                return Const.emptyContainerHeight
                
            case .phone:
                return calculatePhoneFieldContainerHeight(fieldModel: fieldModel.phoneValue, containerWidth: containerWidth)
            case .group:
                return calculateChatterFieldContainerHeight(chatters: fieldModel.groups, editable: fieldModel.editable, containerWidth: containerWidth)
            case .button:
                return Const.buttonFieldContainerHeight
            case .rating:
                return calculateRatingFieldContainerHeight(fieldModel: fieldModel, containerWidth: containerWidth)
            case .stage:
                return calculateSrtageFieldContainerHeight(fieldModel: fieldModel, containerWidth: containerWidth)
            }
        default:
            spaceAssertionFailure("不应该走这里！")
            return Const.emptyContainerHeight
        }
    }
}

extension BTFieldLayout {
    enum Const {
        static let containerLeftRightMargin: CGFloat = 24 // |-()-container-()-|，｜是卡片边缘
        static let newContainerLeftRightMargin: CGFloat = 16 // itemView改造|-()-container-()-|，｜是卡片边缘
        static let containerBorderWidth: CGFloat = 1
        static let panelIndicatorWidthHeight: CGFloat = 12
        static let panelIndicatorRightMargin: CGFloat = 18
        static let fieldVerticalInset: CGFloat = 10
        static let fieldElementVerticalSpacing: CGFloat = 8
        static let fieldNameContainerSpacing: CGFloat = 8
        static let fieldIconWidthHeight: CGFloat = 16
        static let fieldIconRightPadding: CGFloat = 4
        static let containerPadding: CGFloat = 8
        static let textViewTopBottomInset: CGFloat = 11
        static let emptyContainerHeight: CGFloat = 42
        static let attachmentCellLength: CGFloat = 82
        static let attachmentCellHSpacing: CGFloat = 4
        static let attachmentCellVSpacing: CGFloat = 8
        static let formTitleTopPadding: CGFloat = 20
        static let formTitleDescSpacing: CGFloat = 12
        static let formTitleBottomPadding: CGFloat = 10
        static let formSubmitHeight: CGFloat = 254
        static let formHintHeight: CGFloat = 85
        static let formHeroImageHeight: CGFloat = 120
        static let errorMsgHeight: CGFloat = 20
        static let tableItemHeight: CGFloat = 36
        static let progressItemHeight: CGFloat = 24
        static let ratingItemHeight: CGFloat = 24
        static let ratingItemHeightInForm: CGFloat = 50
        static let tableItemSpacing: CGFloat = 4
        static let progressItemSpacing: CGFloat = 0
        static let ratingItemSpacing: CGFloat = 0
        static let disclosureItemHeight: CGFloat = 60
        static let deleteButtonTopInset: CGFloat = 60
        static let deleteButtonHeight: CGFloat = 40
        static let deleteButtonBottomInset: CGFloat = 24
        static let rightAssistIconWidth: CGFloat = 26 //右边辅助按钮的宽度
        static let urlEditBoardHeight: CGFloat = 240 //超链接编辑面板高度
        static let unreadableHeight: CGFloat = 300 // 有不可见的必填项的empty
        static let buttonFieldContainerHeight: CGFloat = 36
        static let stageFieldContainerHeight: CGFloat = 36
        static let textFieldMaxTextHeight: CGFloat = 204 // 文本高度最大限制
        static let textFieldMaxTextHeightInStage: CGFloat = 238 // 阶段字段详情文本高度最大限制
        static let primaryFieldContainerLeftRightMarginInStage: CGFloat = 16
        static let normalFieldContainerLeftRightMarginInStage: CGFloat = 12
        static let stageDetailNormalHeight: CGFloat = 196
        static let itemViewTabsHeight: CGFloat = 40 //itemView切换tab高度
        static let itemViewTitleLeftRightMargin: CGFloat = 16 //itemView标题头左右边距
        static let itemViewTitleTopMarginNoCover: CGFloat = 16 //itemView标题头顶部边距 无封面
        static let itemViewTitleTopMarginCover: CGFloat = 30 //itemView标题头顶部边距 有封面
        static let itemViewTitleNoTabsBootomMargin: CGFloat = 26 //itemView标题头底部边距， 无tab
        static let itemViewTitleTabsBootomMargin: CGFloat = 12 //itemView标题头底部边距， 有tab
        static let itemViewTitleMinHeight: CGFloat = 28 //itemView标题最小高度
        static let itemViewTitleMaxHeight: CGFloat = 56 //itemView标题最大高度, 两行文字
        static let itemViewCatalogueHeight: CGFloat = 50 // 目录高度
        static let itemViewCatalogueHeightWithTab: CGFloat = 34 // 目录高度(有tab情况)
        static let itemViewTitleCatalogueBootomMargin: CGFloat = 3 // itemView标题头底部边距， 有 Catalogue

        static let recordHeaderTitleFont = UIFont.boldSystemFont(ofSize: 16) // 卡片 header
        static let formTitleFont = UIFont.boldSystemFont(ofSize: 20) // 表单名字
        static let formDescriptionFont = UIFont.systemFont(ofSize: 16) // 表单副标题
        static let formQuestionFont = UIFont.systemFont(ofSize: 16) // 表单里问题的名字
        static let fieldNameFont = UIFont.systemFont(ofSize: 14) // 卡片里字段的名字
        static let fieldDescriptionFont = UIFont.systemFont(ofSize: 14) // 卡片里字段的描述
        static let primaryTextFieldFontInStage = UIFont.systemFont(ofSize: 20, weight: .medium)
        static let commonTextFieldFont = UIFont.systemFont(ofSize: 14)
        static let itemViewTitleFont = UIFont.systemFont(ofSize: 20, weight: .medium) // itemView标题

        static let userFieldCapsuleLayout = BTCapsuleUIConfiguration(rowSpacing: 10,
                                                                         colSpacing: 4,
                                                                         lineHeight: 28,
                                                                         textInsets: UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 8),
                                                                         font: .systemFont(ofSize: 14))

        static let optionFieldCapsuleLayout = BTCapsuleUIConfiguration(rowSpacing: 10,
                                                                           colSpacing: 4,
                                                                           lineHeight: 24,
                                                                           textInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12),
                                                                           font: .systemFont(ofSize: 14, weight: .medium))
        static let memberFieldCapsuleLayout = BTCapsuleUIConfiguration(rowSpacing: 10,
                                                                         colSpacing: 4,
                                                                         lineHeight: 28,
                                                                         textInsets: UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 8),
                                                                         font: .systemFont(ofSize: 14))
        static let newMemberFieldCapsuleLayout = BTCapsuleUIConfiguration(rowSpacing: 10,
                                                                          colSpacing: 10,
                                                                          lineHeight: 26,
                                                                          textInsets: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0),
                                                                          font: BTFV2Const.Font.fieldValue,
                                                                          backgroundColor: .clear,
                                                                          avatarConfig: .init(avatarLeft: 0, avatarSize: 20))
        
        static let textContainerInsetInStageOfPrimaryField = UIEdgeInsets(top: BTFieldLayout.Const.textViewTopBottomInset,
                                                                          left: 0,
                                                                          bottom: BTFieldLayout.Const.textViewTopBottomInset,
                                                                          right: 0)
        
        static let normalTextContainerInset = UIEdgeInsets(top: BTFieldLayout.Const.textViewTopBottomInset,
                                                           left: BTFieldLayout.Const.containerPadding,
                                                           bottom: BTFieldLayout.Const.textViewTopBottomInset,
                                                           right: BTFieldLayout.Const.containerPadding)
        
        static func getFont(isPrimaryField: Bool) -> UIFont {
            return isPrimaryField ? primaryTextFieldFontInStage : commonTextFieldFont
        }
    }

    static let textHeightCalculator = BTTextView().construct { it in
        _ = it.layoutManager
    }
    
    func calculateTextHeight(_ attrString: NSAttributedString,
                             font: UIFont,
                             inWidth width: CGFloat,
                             numberOfLines: Int = 0,
                             textContainerInset: UIEdgeInsets? = nil)  -> CGFloat {
        let cacheFG = UserScopeNoChangeFG.XM.ccmBitableCardOptimized
        if cacheFG, let cacheHeight = BTTextHeightStorage.shared.get(attrString, font: font, inWidth: width, numberOfLine: numberOfLines) {
            return cacheHeight
        }
        let textView = Self.textHeightCalculator
        textView.textContainerInset = textContainerInset ?? defaultTextContainerInset
        textView.attributedText = attrString
        textView.textContainer.maximumNumberOfLines = numberOfLines
        let textViewHeight = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        if cacheFG {
            BTTextHeightStorage.shared.set(attrString, font: font, inWidth: width, height: textViewHeight, numberOfLine: numberOfLines)
        }
        return ceil(textViewHeight)
    }

    private func calculateOptionFieldContainerHeight(fieldModel: BTFieldModel, editable: Bool, containerWidth: CGFloat) -> CGFloat {
        var selectedOptionIDs = fieldModel.optionIDs
        var allOptions = fieldModel.property.options

        if fieldModel.property.optionsType == .dynamicOption {
            //级联选项
            allOptions = fieldModel.dynamicOptions
            selectedOptionIDs = fieldModel.dynamicOptions.compactMap({ $0.id })
        }

        let options: [BTCapsuleModel] = BTUtil.getSelectedOptions(withIDs: selectedOptionIDs,
                                                                  colors: fieldModel.colors,
                                                                  allOptionInfos: allOptions)
        var width = containerWidth - Const.containerPadding * 2
        if editable { width -= Const.panelIndicatorRightMargin + Const.panelIndicatorWidthHeight - Const.containerPadding } // 减去下三角的宽度
        let panelHeight = BTCollectionViewWaterfallHelper.getSize(with: options, maxLineLength: width, layoutConfig: Const.optionFieldCapsuleLayout).height
        let containerHeight = ceil(panelHeight) + Const.containerPadding * 2
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(containerHeight, 260) : containerHeight
    }
    
    private func calculateSrtageFieldContainerHeight(fieldModel: BTFieldModel, containerWidth: CGFloat) -> CGFloat {
        return BTStageItemFlowLayout.getLayoutInfo(with: fieldModel, containerWidth: containerWidth).0
    }
    
    private func calculateChatterFieldContainerHeight(chatters: [BTChatterProtocol], editable: Bool, containerWidth: CGFloat) -> CGFloat {
        let options: [BTCapsuleModel] = chatters.map { (chatter) -> BTCapsuleModel in
            var model = BTCapsuleModel(id: "",
                                  text: DocsSDK.currentLanguage == .en_US ? (chatter.enName.isEmpty ? chatter.name : chatter.enName) : chatter.name,
                                  color: BTColorModel(),
                                  isSelected: false,
                                  font: .systemFont(ofSize: 14, weight: .regular),
                                  avatarUrl: chatter.avatarUrl,
                                  userID: chatter.chatterId)
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                model.avatarKey = chatter.avatarKey
            }
            return model
        }
        var width = containerWidth - Const.containerPadding * 2
        if editable { width -= Const.panelIndicatorRightMargin + Const.panelIndicatorWidthHeight } // 减去下三角的宽度
        let panelHeight = BTCollectionViewWaterfallHelper.getSize(with: options, maxLineLength: width, layoutConfig: Const.userFieldCapsuleLayout).height
        let containerHeight = ceil(panelHeight) + Const.containerPadding * 2
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(containerHeight, 260) : containerHeight
    }

    private func calculateTextFieldContainerHeight(textValue: [BTRichTextSegmentModel],
                                                   font: UIFont,
                                                   maxHeight: CGFloat = 0.0,
                                                   isMultiline: Bool = true,
                                                   containerWidth: CGFloat,
                                                   textContainerInset: UIEdgeInsets = Const.normalTextContainerInset,
                                                   useCache: Bool = false) -> CGFloat {
        // convert 函数默认值是 UIFont.systemFont(ofSize: 14)
        let attrString = BTUtil.convert(textValue, font: font)
        if attrString.string.isEmpty {
            return font.figmaHeight + textContainerInset.top + textContainerInset.bottom
        }
        let textHeight = self.calculateTextHeight(attrString,
                                                  font: font,
                                                  inWidth: containerWidth,
                                                  numberOfLines: isMultiline ? 0 : 1,
                                                  textContainerInset: textContainerInset)
        // 设置了containerInset直接计算，不搞那些弯弯绕绕
//        let containerHeight = textHeight + Const.textViewTopBottomInset * 2
        let height = maxHeight <= 0.0 ? Const.textFieldMaxTextHeight : maxHeight
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(textHeight, height) : textHeight
        // 为了让文本永远垂直居中，BTBaseTextField 里面固定了 textView.top.bottom.equalToSuperview().inset(10)
        // 这里上下间距不使用 8 而要用 10，因为当文本比较少，单行的时候，如果用 8，container 高度就只有 36，看起来很矮，不好点到。设计要求最低 40
    }

    private func calculateNumberFieldContainerHeight(fieldModel: [BTNumberModel],
                                                     font: UIFont,
                                                     maxHeight: CGFloat = 0.0,
                                                     containerWidth: CGFloat,
                                                     textContainerInset: UIEdgeInsets) -> CGFloat {
        var pseudoSegment = BTRichTextSegmentModel()
        pseudoSegment.type = .text
        pseudoSegment.text = fieldModel.reduce("", { (middleResult, newNumberModel) -> String in
            if middleResult.isEmpty {
                return "\(newNumberModel.formattedValue)"
            } else {
                return "\(middleResult),\(newNumberModel.formattedValue)"
            }
        })
        return calculateTextFieldContainerHeight(textValue: [pseudoSegment],
                                                 font: font,
                                                 maxHeight: maxHeight,
                                                 isMultiline: false,
                                                 containerWidth: containerWidth,
                                                 textContainerInset: textContainerInset)
    }

    private func calculateDateFieldContainerHeight(value: [BTDateModel],
                                                   font: UIFont,
                                                   maxHeight: CGFloat = 0.0,
                                                   containerWidth: CGFloat,
                                                   textContainerInset: UIEdgeInsets) -> CGFloat {
        var pseudoSegment = BTRichTextSegmentModel()
        pseudoSegment.type = .text
        pseudoSegment.text = value.reduce("", { (middleResult, newDateModel) -> String in
            let newDateString = BTUtil.dateFormate(newDateModel.value, dateFormat: "yyyy/MM/dd", timeFormat: "HH:mm")
            if middleResult.isEmpty {
                return "\(newDateString)"
            } else {
                return "\(middleResult),\(newDateString)"
            }
        })
        return calculateTextFieldContainerHeight(textValue: [pseudoSegment],
                                                 font: font,
                                                 maxHeight: maxHeight,
                                                 isMultiline: false,
                                                 containerWidth: containerWidth)
    }

    private func calculateAttachmentFieldContainerHeight(attachmentsCount: Int, editable: Bool, containerWidth: CGFloat) -> CGFloat {
        if attachmentsCount == 0 { return Const.emptyContainerHeight } // 没有附件时的 add button 高度
        let itemLength, numberOfColumns: CGFloat
        let attachmentViewWidth = containerWidth - Const.containerPadding * 2
        if attachmentViewWidth < 500 {
            numberOfColumns = 3.0
            itemLength = (attachmentViewWidth - Const.attachmentCellHSpacing * (numberOfColumns - 1.0)) / numberOfColumns
        } else {
            numberOfColumns = floor(attachmentViewWidth / (Const.attachmentCellLength + Const.attachmentCellHSpacing))
            itemLength = Const.attachmentCellLength
        }
        let numberOfItems: CGFloat = ceil(CGFloat(attachmentsCount) / numberOfColumns)
        let itemsHeight: CGFloat = numberOfItems * itemLength + (numberOfItems - 1) * Const.attachmentCellVSpacing
        var containerHeight: CGFloat = Const.containerPadding + itemsHeight + Const.containerPadding
        if editable { // 需要考虑 add button 高度
            containerHeight += Const.containerPadding + Const.tableItemHeight
        }
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(360, containerHeight) : containerHeight
    }

    private func calculateAutoNumberFieldContainerHeight(fieldModel: [BTAutoNumberModel],
                                                         font: UIFont,
                                                         maxHeight: CGFloat = 0.0,
                                                         containerWidth: CGFloat,
                                                         textContainerInset: UIEdgeInsets) -> CGFloat {
        var pseudoSegment = BTRichTextSegmentModel()
        pseudoSegment.type = .text
        pseudoSegment.text = fieldModel.reduce("", { (middleResult, newAutoNumberModel) -> String in
            if middleResult.isEmpty {
                return "\(newAutoNumberModel.number)"
            } else {
                return "\(middleResult),\(newAutoNumberModel.number)"
            }
        })
        return calculateTextFieldContainerHeight(textValue: [pseudoSegment],
                                                 font: font,
                                                 maxHeight: maxHeight,
                                                 isMultiline: true,
                                                 containerWidth: containerWidth,
                                                 textContainerInset: textContainerInset)
    }

    private func calculateLinkFieldContainerHeight(linkedRecords: [BTRecordModel], editable: Bool, containerWidth: CGFloat) -> CGFloat {
        let filteredLinkedRecords = linkedRecords.filter {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                // 目前架构上没有contested概念，tablemeta的信息需要层层传递，此处使用first可以拿到table上正确的isFormulaServiceSuspend
                if fieldsModel.first?.value.isFormulaServiceSuspend == true {
                    // 新文档不再筛选无权限的关联cell
                    return true
                } else {
                    return $0.visible
                }
            } else {
                return $0.visible
            }
        }
        if filteredLinkedRecords.count == 0 { return Const.emptyContainerHeight } // 没有关联记录时的 add button 高度
        let itemsHeight = Const.tableItemHeight * CGFloat(filteredLinkedRecords.count) + Const.tableItemSpacing * CGFloat(filteredLinkedRecords.count - 1)
        var containerHeight: CGFloat = Const.containerPadding + itemsHeight + Const.containerPadding
        if editable { // 需要考虑 add button 高度
            containerHeight += Const.tableItemSpacing + Const.tableItemHeight
        }
        
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(280, containerHeight) : containerHeight
    }
    
    private func calculateProgressFieldContainerHeight(fieldModel: [BTNumberModel], editable: Bool, containerWidth: CGFloat) -> CGFloat {
        let count = max(1, fieldModel.count)
        let limitCount: CGFloat = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(7.5, CGFloat(count)) : CGFloat(count)
        let itemsHeight = Const.progressItemHeight * limitCount + Const.progressItemSpacing * CGFloat(count - 1)
        let containerHeight: CGFloat = Const.containerPadding + itemsHeight + Const.containerPadding
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(280, containerHeight) : containerHeight
    }
    
    private func calculateRatingFieldContainerHeight(fieldModel: BTFieldModel, containerWidth: CGFloat) -> CGFloat {
        if fieldModel.isInForm, fieldModel.editable {
            return BTFieldLayout.Const.ratingItemHeightInForm
        }
        let count = max(1, fieldModel.numberValue.count)
        let limitCount: CGFloat = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(7.5, CGFloat(count)) : CGFloat(count)
        let itemsHeight = Const.ratingItemHeight * limitCount + Const.ratingItemSpacing * CGFloat(count - 1)
        let containerHeight: CGFloat = Const.containerPadding + itemsHeight + Const.containerPadding
        return UserScopeNoChangeFG.ZJ.btCellLargeContentOpt ? min(280, containerHeight) : containerHeight
    }

    private func calculateFormTitleHeight(fieldModel: BTFieldModel, maxWidth: CGFloat) -> CGFloat {
        let calculator = Self.textHeightCalculator
        let attributes = BTUtil.getFigmaHeightAttributes(font: Const.formTitleFont, alignment: .center)
        calculator.attributedText = NSAttributedString(string: fieldModel.name, attributes: attributes)
        let titleHeight = calculator.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude)).height
        var totalHeight = Const.formTitleTopPadding + ceil(titleHeight)
        if let descriptionHeight = calculateFormDescriptionHeight(fieldModel: fieldModel, maxWidth: maxWidth) {
            totalHeight += Const.formTitleDescSpacing + descriptionHeight
        }
        totalHeight += Const.formTitleBottomPadding
        return totalHeight
    }
    
    /// Header 标题底部的间距
    static func calculateItemViewTitleBottomOffset(shouldShowItemViewCatalogue: Bool, shouldShowItemViewTabs: Bool) -> CGFloat {
        if shouldShowItemViewCatalogue {
            // 有 catalogue
            return Const.itemViewTitleCatalogueBootomMargin
        } else if shouldShowItemViewTabs {
            // 有tab，无 catalogue
            return Const.itemViewTitleTabsBootomMargin
        } else {
            // 无tab，无 catalogue
            return Const.itemViewTitleNoTabsBootomMargin
        }
    }
    
    private func calculateItemViewTitleHeight(fieldModel: BTFieldModel, maxWidth: CGFloat) -> CGFloat {
        let bottomOffset = Self.calculateItemViewTitleBottomOffset(
            shouldShowItemViewCatalogue: realRecordModel.shouldShowItemViewCatalogue,
            shouldShowItemViewTabs: realRecordModel.shouldShowItemViewTabs
        )
        guard !fieldModel.name.isEmpty else {
            var titleHeight = Const.itemViewTitleMinHeight
            
            titleHeight += bottomOffset
            
            if !realRecordModel.shouldShowAttachmentCoverField() {
                // 无封面，需要加上headerView的高度
                titleHeight += hearderViewHeight + Const.itemViewTitleTopMarginNoCover
            } else {
                // 有封面
                titleHeight += Const.itemViewTitleTopMarginCover
            }
            return titleHeight
        }
        let attributes = BTUtil.getFigmaHeightAttributes(font: Const.itemViewTitleFont, alignment: .left)
        let attributeString = NSAttributedString(string: fieldModel.name, attributes: attributes)
        let titleHeight = calculateTextHeight(attributeString,
                                              font: Const.itemViewTitleFont,
                                              inWidth: maxWidth,
                                              textContainerInset: .zero)
        var totalHeight = ceil(max(titleHeight, Const.itemViewTitleMinHeight))
        
        totalHeight += bottomOffset
        if realRecordModel.shouldShowAttachmentCoverField() {
            // 有封面
            totalHeight += Const.itemViewTitleTopMarginCover
            return min(totalHeight, Const.itemViewTitleMaxHeight + bottomOffset + Const.itemViewTitleTopMarginCover)
        }
         
        totalHeight += Const.itemViewTitleTopMarginNoCover
        return min(totalHeight, Const.itemViewTitleMaxHeight + bottomOffset + Const.itemViewTitleTopMarginNoCover) + hearderViewHeight
    }
    
    private func calculateItemViewCatalogueHeight(fieldModel: BTFieldModel) -> CGFloat {
        guard !UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable else {
            return Const.itemViewCatalogueHeight
        }
        return context?.shouldShowItemViewTabs == true ? Const.itemViewCatalogueHeightWithTab : Const.itemViewCatalogueHeight
    }

    private func calculateFormDescriptionHeight(fieldModel: BTFieldModel, maxWidth: CGFloat) -> CGFloat? {
        let fieldID = BTFieldExtendedType.formTitle.mockFieldID
        var fullDescHeight: CGFloat = 0
        let font = Const.formDescriptionFont
        if let descriptionAttrText = formDescriptionAttrString(for: fieldModel) {
            fullDescHeight = calculateTextHeight(descriptionAttrText, font: font, inWidth: maxWidth)
        } else {
            return nil // 代表没有描述
        }
        let lineHeight = font.figmaHeight
        var shouldLimitDescriptionLines = fieldModel.isDescriptionTextLimited // 默认折叠
        if fullDescHeight <= BTDescriptionView.maxNumberOfLines * lineHeight && !shouldLimitDescriptionLines {
            // 在竖屏时点击了展开，转到横屏时可能由于宽度足够不再需要展示 limit button，这种情况下需要修正 flag，不然横屏下就会多出来收起按钮
            shouldLimitDescriptionLines = true
        }
        let descriptionHeight: CGFloat
        if shouldLimitDescriptionLines {
            descriptionHeight = min(fullDescHeight, BTDescriptionView.maxNumberOfLines * lineHeight)
        } else {
            descriptionHeight = fullDescHeight + lineHeight // 多出来的一行是收起按钮
        }
        descriptionHeights[fieldID] = descriptionHeight
        return descriptionHeight
    }

    private func formDescriptionAttrString(for fieldModel: BTFieldModel) -> NSAttributedString? {
        if let descriptionSegments = fieldModel.description?.content, !descriptionSegments.isEmpty {
            return BTUtil.convert(descriptionSegments, font: Const.formDescriptionFont)
        }
        return nil
    }
    
    private func calculatePhoneFieldContainerHeight(fieldModel: [BTPhoneModel], containerWidth: CGFloat) -> CGFloat {
        var pseudoSegment = BTRichTextSegmentModel()
        pseudoSegment.type = .text
        pseudoSegment.text = fieldModel.reduce("", { (middleResult, newPhoneModel) -> String in
            if middleResult.isEmpty {
                return "\(newPhoneModel.fullPhoneNum)"
            } else {
                return "\(middleResult),\(newPhoneModel.fullPhoneNum)"
            }
        })
        return calculateTextFieldContainerHeight(textValue: [pseudoSegment],
                                                 font: BTFieldLayout.Const.commonTextFieldFont,
                                                 isMultiline: false,
                                                 containerWidth: containerWidth)
    }
    
    private func calculateLocationFieldContainerHeight(fieldModel: BTFieldModel,
                                                       containerWidth: CGFloat,
                                                       textContainerInset: UIEdgeInsets) -> CGFloat {
        guard let first = fieldModel.geoLocationValue.first, !first.isEmpty else {
            return Const.emptyContainerHeight
        }
        var segment = BTRichTextSegmentModel()
        segment.type = .text
        segment.text = first.fullAddress ?? ""
        let inset: CGFloat = LKFeatureGating.bitableGeoLocationFieldEnable && fieldModel.editable ? 47 : 0
        return calculateTextFieldContainerHeight(textValue: [segment],
                                                 font: BTFieldLayout.Const.commonTextFieldFont,
                                                 isMultiline: true,
                                                 containerWidth: containerWidth - inset,
                                                 textContainerInset: textContainerInset)
    }
}
