//
//  BTFieldEditViewManager+LinkField.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/7/3.
//  

import UniverseDesignColor
import UniverseDesignIcon
import SKResource
import SKCommon
import UIKit
import SKFoundation

extension BTFieldEditViewManager {
    /// 构建关联字段(支持筛选)的 HeaderView
    func constructLinkHeaderView() -> UIView {
        return UIView().construct { it in
            let linkTableLabel = UILabel()
            linkTableLabel.textColor = UDColor.textPlaceholder
            linkTableLabel.font = .systemFont(ofSize: 14)
            linkTableLabel.text = BundleI18n.SKResource.Bitable_Field_LinkToTable
            
            let linkRangeLabel = UILabel()
            linkRangeLabel.textColor = UDColor.textPlaceholder
            linkRangeLabel.font = .systemFont(ofSize: 14)
            linkRangeLabel.text = BundleI18n.SKResource.Bitable_Relation_AvailableDataScope

            it.backgroundColor = .clear
            it.addSubview(linkTableLabel)
            it.addSubview(linkTableChooseTableButton)
            it.addSubview(linkRangeLabel)
            it.addSubview(linkTableChooseRangeButton)
            it.addSubview(linkTableMeetConditionView)

            linkTableLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(14)
                make.height.equalTo(20)
                make.left.equalToSuperview()
                make.bottom.equalTo(linkTableChooseTableButton.snp.top).offset(-2)
            }

            linkTableChooseTableButton.snp.makeConstraints { make in
                make.trailing.leading.equalToSuperview()
                make.top.equalTo(linkTableLabel.snp.bottom).offset(2)
                make.height.equalTo(52)
            }
            
            linkRangeLabel.snp.makeConstraints { make in
                make.top.equalTo(linkTableChooseTableButton.snp.bottom).offset(14)
                make.height.equalTo(20)
                make.left.equalToSuperview()
            }

            linkTableChooseRangeButton.snp.makeConstraints { make in
                make.trailing.leading.equalToSuperview()
                make.top.equalTo(linkRangeLabel.snp.bottom).offset(2)
                make.height.equalTo(52)
            }
            
            linkTableMeetConditionView.snp.makeConstraints { make in
                make.trailing.leading.equalToSuperview()
                make.top.equalTo(linkTableChooseRangeButton.snp.bottom).offset(16)
                make.height.equalTo(52)
            }
        }
    }
    
    func constructLinkTableChooseTableButton() -> BTFieldCustomButton {
        return BTFieldCustomButton().construct { it in
            it.setLeftIconVisible(isVisible: false)
            it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
            it.addTarget(self, action: #selector(didClickChooseRelatedTable), for: .touchUpInside)
            it.setTitleString(text: BundleI18n.SKResource.Bitable_Field_SelectATable)
            it.setSubTitleString(text: BundleI18n.SKResource.Bitable_Field_Select)
        }
    }
    
    /// 构建是否允许添加多条记录的view
    func constructLinkTableCanAddMultiRecordView() -> UIView {
        return UIView().construct { it in
            it.backgroundColor = .clear
            it.addSubview(linkCanAddMultiRecordView)

            linkCanAddMultiRecordView.snp.makeConstraints { make in
                make.top.trailing.leading.equalToSuperview()
                make.height.equalTo(88)
            }
        }
    }
    
    func getLinkTableFooterView(filterConditionCount: Int,
                                conditionContainNotSupport: Bool,
                                isLinkAllRecord: Bool,
                                canAddMultiViewSelected: Bool
    ) -> UIView {
        return UIView().construct { it in
            let canAddMultiView = constructLinkTableCanAddMultiRecordView()
            linkCanAddMultiRecordView.setSelected(canAddMultiViewSelected)
            if filterConditionCount >= 1 && !isLinkAllRecord {
                it.addSubview(linkTableAddFilterOptionButton)
                it.addSubview(canAddMultiView)
                linkTableAddFilterOptionButton.isHidden = false
                /*
                linkTableAddFilterOptionButton.buttonIsEnabled = filterConditionCount < 5 && !conditionContainNotSupport
                 */
                var buttonIsEnabled: Bool
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    buttonIsEnabled = filterConditionCount < 5 && !isLinkTablePartialDenied
                } else {
                    buttonIsEnabled = filterConditionCount < 5 && !conditionContainNotSupport
                }
                linkTableAddFilterOptionButton.buttonIsEnabled = buttonIsEnabled
                linkTableAddFilterOptionButton.snp.makeConstraints { make in
                    make.left.right.equalToSuperview().inset(16)
                    make.top.equalTo(8)
                    make.height.equalTo(48)
                }
                canAddMultiView.snp.makeConstraints { make in
                    make.top.equalTo(linkTableAddFilterOptionButton.snp.bottom)
                    make.left.right.equalToSuperview().inset(16)
                    make.height.equalTo(88)
                }
            } else {
                linkTableAddFilterOptionButton.isHidden = true
                it.addSubview(canAddMultiView)
                canAddMultiView.snp.makeConstraints { make in
                    make.top.equalToSuperview()
                    make.left.right.equalToSuperview().inset(16)
                    make.height.equalTo(88)
                }
            }
        }
    }
    
    func calLinkTableHeaderHeight() -> CGFloat {
        var headerHeight: CGFloat = 238
        if linkTableMeetConditionView.isHidden {
            headerHeight -= 60
        }
        if linkTableChooseRangeButton.isHidden {
            headerHeight -= 92
        }
        if !fieldEditModel.isLinkAllRecord {
            headerHeight += 14
        }
        return headerHeight
    }
    
    func calLinkTableFooterHeight() -> CGFloat {
        var headerHeight: CGFloat = 224
        if linkTableAddFilterOptionButton.isHidden {
            headerHeight -= 56
        }
        return headerHeight
    }
    
    // 更新关联字段 Header 内容数据
    func updateLinkTableHeaderData() {
        var subTitleText = ""
        var titleColor = UDColor.textTitle
        var shouldWarning = false
        var chooseRangeEnable = true
        let linkTableId = fieldEditModel.fieldProperty.tableId
        if fieldEditModel.fieldProperty.tableId.isEmpty {
            // 没有选择数据表
            subTitleText = BundleI18n.SKResource.Bitable_Field_Select
            titleColor = UDColor.textTitle
            shouldWarning = false
            chooseRangeEnable = false
        } else if let relatedTableName = fieldEditModel.tableNameMap.first(where: { $0.tableId == linkTableId })?.tableName {
            // 已选择数据表
            subTitleText = relatedTableName
            titleColor = UDColor.textTitle
            shouldWarning = false
            chooseRangeEnable = true
        } else if commonData.tableNames.first(where: { $0.tableId == linkTableId })?.readPerimission == false {
            // 关联数据表无权限
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                subTitleText = BundleI18n.SKResource.Bitable_AdvancedPermission_NotAccessibleTable
            } else {
            subTitleText = BundleI18n.SKResource.Bitable_SingleOption_NoPermToReferencedTableTip_Mobile
            }
            titleColor = UDColor.textTitle
            shouldWarning = true
            chooseRangeEnable = false
        } else if isLinkTablePartialDenied {
            // 部分无权限，读取tableName失败场景兜底逻辑
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                subTitleText = "" // PM申请文案，ready后修改为文案
                titleColor = UDColor.textTitle
            }
        } else {
            // 关联数据表被删
            subTitleText = BundleI18n.SKResource.Bitable_Relation_TableDeletedReselectTip_Mobile
            titleColor = UDColor.textTitle
            shouldWarning = true
            chooseRangeEnable = false
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if isLinkTablePartialDenied {
                shouldWarning = true
                chooseRangeEnable = false
            }
        }
        linkTableChooseTableButton.setSubTitleString(text: subTitleText)
        linkTableChooseTableButton.setTitleColor(color: titleColor)
        linkTableChooseTableButton.setWaringIconVisible(isVisible: shouldWarning)
        linkTableChooseRangeButton.setButtonEnable(enable: chooseRangeEnable)

        // "所有记录"/"指定范围内的记录"
        let text = fieldEditModel.isLinkAllRecord ? BundleI18n.SKResource.Bitable_Relation_AllRecord : BundleI18n.SKResource.Bitable_Relation_SpecifiedRecord
        linkTableChooseRangeButton.setTitleString(text: text)
        
        // 符合"任一条件"/"所有条件"
        if let conjuction = commonData.filterOptions.conjunctionOptions.first(where: { $0.value == fieldEditModel.fieldProperty.filterInfo?.conjunction }) {
            let model = BTConditionConjuctionModel(id: conjuction.value, text: conjuction.text)
            linkTableMeetConditionView.configModel(model)
        }
    }
}
