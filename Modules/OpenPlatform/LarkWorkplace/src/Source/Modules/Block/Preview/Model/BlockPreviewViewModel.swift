//
//  BlockPreviewViewModel.swift
//  LarkWorkplace
//
//  Created by yinyuan on 2021/2/24.
//

import Foundation
import LarkUIKit
import SwiftyJSON
import LarkWorkplaceModel

enum BlockPreviewViewModel {

    /// 生成真机预览需要的 ViewModel 数据
    static func generatePreviewModel(
        containerWidth: CGFloat,
        appID: String,
        blockTypeID: String,
        previewToken: String?,
        dataManager: AppCenterDataManager
    ) -> WorkPlaceViewModel? {

        // 先生成一个空的 WorkPlaceViewModel
        let dataModel = WorkPlaceDataModel(json: JSON())
        let previewViewModle = WorkPlaceViewModel(
            dataModel: dataModel,
            containerWidth: containerWidth,
            dataManager: dataManager
        )

        // 构造 Preview 界面数据，按照视觉设计构造
        // icon分组：没有 title ， 4个空图标
        let iconGroup0 = GroupUnit(
            category: generateItemCategory(categoryName: nil, showBlock: false),
            itemUnits: [
                generatePreviewIconUnit(),
                generatePreviewIconUnit(),
                generatePreviewIconUnit(),
                generatePreviewIconUnit()
            ]
        )
        // block 分组
        let blockGroup = GroupUnit(
            category: generateItemCategory(categoryName: nil, showBlock: true),
            itemUnits: [
                generatePreviewBlockUnit(appID: appID, blockTypeID: blockTypeID, previewToken: previewToken)
            ]
        )
        // 应用分组 1：有 title ， 3个空图标
        let iconGroup1 = GroupUnit(
            category: generateItemCategory(
                categoryName: BundleI18n.LarkWorkplace.OpenPlatform_WidgetPreview_AppGroup1,
                showBlock: false
            ),
            itemUnits: [
                generatePreviewIconUnit(),
                generatePreviewIconUnit(),
                generatePreviewIconUnit()
            ]
        )
        // 应用分组 2：有 title ， 2个空图标
        let iconGroup2 = GroupUnit(
            category: generateItemCategory(
                categoryName: BundleI18n.LarkWorkplace.OpenPlatform_WidgetPreview_AppGroup2,
                showBlock: false
            ),
            itemUnits: [
                generatePreviewIconUnit(),
                generatePreviewIconUnit()
            ]
        )
        previewViewModle.sectionsList = [
            SectionModel(group: iconGroup0),
            SectionModel(group: blockGroup),
            SectionModel(group: iconGroup1),
            SectionModel(group: iconGroup2)
        ]

        // 生成视图数据
        previewViewModle.updateDisplaySections()

        return previewViewModle
    }

    /// 构造一个分组
    static func generateItemCategory(categoryName: String?, showBlock: Bool) -> ItemCategory {
        return ItemCategory(
            categoryId: "",
            categoryName: categoryName ?? "",
            showTagHeader: categoryName != nil,
            subTags: nil,
            tag: .init(
                id: "",
                showTagHeader: categoryName != nil,
                name: "",
                showWidget: showBlock
            )
        )
    }

    /// 构造一个预览icon
    static func generatePreviewIconUnit() -> ItemUnit {
        return .init(
            type: .icon,
            subType: .normal,
            itemID: "",
            item: WPAppItem.buildBlockDemoItem(
                appId: "", blockInfo: WPBlockInfo(blockId: "", blockTypeId: ""
            ))
        )
    }

    // swiftlint:disable todo
    // TODO: previewToken 需要放到正确的位置
    // swiftlint:enable todo
    /// 构造一个预览 block
    static func generatePreviewBlockUnit(
        appID: String,
        blockTypeID: String,
        previewToken: String?
    ) -> ItemUnit {
        return .init(
            type: .block,
            subType: .common,
            itemID: blockTypeID,
            item: WPAppItem.buildBlockDemoItem(
                appId: appID, 
                blockInfo: WPBlockInfo(blockId: "", blockTypeId: blockTypeID),
                previewToken: previewToken
            )
        )
    }
}
