//
//  BTFieldV2Base+EditButton.swift
//  SKBitable
//
//  Created by zhysan on 2023/8/14.
//

import SKFoundation
import SKResource
import UniverseDesignIcon
import SKCommon

extension BTFieldModel {
    var isValueEmpty: Bool {
        switch extendedType {
        case .inherent(let cmpType):
            let uiType = cmpType.uiType
            switch uiType {
            case .notSupport, .checkbox, .progress, .button, .rating, .stage:
                return false
            case .text, .barcode, .url, .lookup, .formula, .email:
                return textValue.isEmpty
            case .number, .currency:
                return numberValue.isEmpty
            case .singleSelect, .multiSelect:
                if self.property.optionsType == .dynamicOption {
                    return self.dynamicOptions.isEmpty
                } else {
                    return self.optionIDs.isEmpty
                }
            case .dateTime, .createTime, .lastModifyTime:
                return dateValue.isEmpty
            case .user, .lastModifyUser, .createUser:
                return users.isEmpty
            case .phone:
                return phoneValue.isEmpty
            case .attachment:
                return attachmentValue.isEmpty && pendingAttachments.isEmpty && uploadingAttachments.isEmpty
            case .singleLink, .duplexLink:
                return linkedRecords.isEmpty
            case .location:
                return geoLocationValue.isEmpty
            case .autoNumber:
                return autoNumberValue.isEmpty
            case .group:
                return groups.isEmpty
            }
        case .formHeroImage, .customFormCover, .formTitle, .formSubmit, .hiddenFieldsDisclosure, .unreadable, .recordCountOverLimit, .stageDetail, .itemViewTabs, .itemViewHeader, .attachmentCover, .itemViewCatalogue:
            return false
        }
    }
    
    var editType: BTFieldEditButtonType {
        if mode == .addRecord || (mode == .submit && UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable) {
            if uneditableReason == .isExtendField || uneditableReason == .isSyncTable {
                return isValueEmpty ? .placeholder(text: BundleI18n.SKResource.Bitable_QuickAdd_AutoFillAfterSubmit_Placeholder) : .none
            }
        }
        switch extendedType {
        case .inherent(let cmpType):
            switch cmpType.uiType {
            case .notSupport, .checkbox, .progress, .button, .rating, .stage:
                // 这一类 Field 都一定有一个值样式，没有编辑按钮和空值样式
                return .none
            case .lookup, .formula, .createTime, .lastModifyTime, .createUser, .lastModifyUser, .autoNumber:
                if mode == .addRecord || (mode == .submit && UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable) {
                    return isValueEmpty ? .placeholder(text: BundleI18n.SKResource.Bitable_QuickAdd_AutoFillAfterSubmit_Placeholder) : .none
                }
                // 这一类 Field 都是只读的，有值显示值，无值显示横杠
                return isValueEmpty ? .dashLine : .none
            case .text, .number, .currency, .email:
                // 这一类 Field 可以读写，但是编辑按钮是 placeholder text，没有单独编辑按钮，空值切不能编辑时显示横杠
                return (isValueEmpty && !editable) ? .dashLine : .none
            case .singleSelect, .multiSelect:
                if !isValueEmpty {
                    return .none
                } else {
                    return editable ? .emptyRoundDashButton(image: UDIcon.addOutlined) : .dashLine
                }
            case .dateTime:
                if !isValueEmpty {
                    return .none
                } else {
                    return editable ? .emptyRoundDashButton(image: UDIcon.calendarAddOutlined) : .dashLine
                }
            case .user:
                if !isValueEmpty {
                    return .none
                } else {
                    return editable ? .emptyRoundDashButton(image: UDIcon.memberAddOutlined) : .dashLine
                }
            case .group:
                if !isValueEmpty {
                    return .none
                } else {
                    return editable ? .emptyRoundDashButton(image: UDIcon.addChatOutlined) : .dashLine
                }
            case .url:
                if !isValueEmpty {
                    return editable ? .fixedTopRightRoundedButton(image: UDIcon.globalLinkOutlined) : .none
                } else {
                    return editable ? .fixedTopRightRoundedButton(image: UDIcon.globalLinkOutlined) : .dashLine
                }
            case .attachment:
                if !isValueEmpty {
                    let image = onlyCamera ? UDIcon.cameraOutlined : UDIcon.addOutlined
                    return editable ? .fixedTopRightRoundedButton(image: image) : .none
                } else {
                    let image = onlyCamera ? UDIcon.cameraOutlined : UDIcon.uploadOutlined
                    return editable ? .emptyRoundDashButton(image: image) : .dashLine
                }
            case .singleLink, .duplexLink:
                if !isValueEmpty {
                    return editable ? .fixedTopRightRoundedButton(image: UDIcon.addOutlined) : .none
                } else {
                    return editable ? .emptyRoundDashButton(image: UDIcon.addOutlined) : .dashLine
                }
            case .barcode:
                if allowedEditModes.scan == true, allowedEditModes.manual == false {
                    // 1. 仅支持手机扫码的条码字段
                    if !isValueEmpty {
                        return editable ? .fixedTopRightRoundedButton(image: UDIcon.scanOutlined) : .none
                    } else {
                        return editable ? .emptyRoundDashButton(image: UDIcon.scanOutlined) : .dashLine
                    }
                } else {
                    // 2. 支持手动编辑的条码字段
                    let isManualEditAllow = editable && allowedEditModes.manual == true
                    if !isValueEmpty {
                        return isManualEditAllow ? .fixedTopRightRoundedButton(image: UDIcon.scanOutlined) : .none
                    } else {
                        return isManualEditAllow ? .fixedTopRightRoundedButton(image: UDIcon.scanOutlined) : .dashLine
                    }
                }
            case .phone:
                switch phoneAssistType {
                case .none:
                    return .none
                case .empty:
                    return .dashLine
                case .contact:
                    // 显示通讯录
                    return .fixedTopRightRoundedButton(image: UDIcon.contactsOutlined)
                case .call:
                    // 显示拨打电话
                    return .fixedTopRightRoundedButton(image: UDIcon.callMessageOutlined)
                }
            case .location:
                if !LKFeatureGating.bitableGeoLocationFieldEnable {
                    return .none
                }
                if property.inputType != .onlyMobile {
                    // 1. 可手动输入的位置字段
                    if isValueEmpty {
                        // 当前位置信息为空，不展示按钮
                        return editable ? .emptyRoundDashButton(image: UDIcon.addOutlined) : .dashLine
                    } else {
                        // 当前位置信息不为空，右侧展示编辑按钮
                        return editable ? .fixedTopRightRoundedButton(image: UDIcon.editOutlined) : .none
                    }
                } else {
                    // 2. 仅手机定位的位置字段
                    if isValueEmpty {
                        // 当前位置信息为空
                        if isFetchingGeoLocation {
                            // 显示刷新动画 + "获取中"
                            return .centerVerticallyWithIconText(image: UDIcon.locatedOutlined, text: BundleI18n.SKResource.Bitable_Field_GettingLocation)
                        } else {
                            // 显示定位图标 + "获取当前位置"
                            return editable ? .emptyRoundDashButton(image: UDIcon.locatedOutlined) : .dashLine
                        }
                    } else {
                        // 当前位置信息不为空，右侧显示刷新按钮
                        return editable ? .fixedTopRightRoundedButton(image: UDIcon.refreshOutlined) : .none
                    }
                }
            }
        case .formHeroImage, .customFormCover, .formTitle, .formSubmit, .hiddenFieldsDisclosure, .unreadable, .recordCountOverLimit, .stageDetail, .itemViewTabs, .itemViewHeader, .attachmentCover, .itemViewCatalogue:
            return .none
        }
    }
    
    var isInEditLoadingStatus: Bool {
        if case .inherent(let cmpType) = extendedType {
            if case .location = cmpType.uiType {
                return property.inputType == .onlyMobile && isFetchingGeoLocation
            }
        }
        return false
    }
    
    var editButtonSize: CGSize {
        switch editType {
        case .none:
            return .zero
        case .dashLine:
            return CGSize(width: BTFV2Const.Dimension.valueAssistBtnExternalSize, height: BTFV2Const.Dimension.valueAssistBtnExternalSize)
        case .emptyRoundDashButton:
            return CGSize(width: BTFV2Const.Dimension.valueAssistDashBtnExtSize, height: BTFV2Const.Dimension.valueAssistDashBtnExtSize)
        case .fixedTopRightRoundedButton:
            switch extendedType {
            case .inherent(let cmpType):
                switch cmpType.uiType {
                case .attachment:
                    return CGSize(width: BTFieldUIDataAttachment.Const.itemSize, height: BTFieldUIDataAttachment.Const.itemSize)
                case .singleLink, .duplexLink:
                    return CGSize(width: BTFV2Const.Dimension.valueAssistBtnWidenWidth, height: BTFieldUIDataLink.Const.lineHeight)
                default:
                    return CGSize(width: BTFV2Const.Dimension.valueAssistBtnExternalSize, height: BTFV2Const.Dimension.valueAssistBtnExternalSize)
                }
            default:
                return .zero
            }
        case .centerVerticallyWithIconText:
            let btn = BTFieldEditButton()
            btn.editType = editType
            // 高度和 emptyRoundDashButton 一致，避免形态转换时高度抖动
            let btnH = BTFV2Const.Dimension.valueAssistDashBtnExtSize
            let fitSize = btn.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: btnH))
            return CGSize(width: fitSize.width, height: btnH)
        case .placeholder:
            let btn = BTFieldEditButton()
            btn.editType = editType
            let btnH = BTFV2Const.Dimension.valueAssistBtnExternalSize
            let fitSize = btn.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: btnH))
            return CGSize(width: fitSize.width, height: btnH)
        }
    }
}


enum BTFieldEditButtonType {
    /// 没有编辑按钮
    case none
    /// 短横杠
    case dashLine
    /// 圆形虚线框的按钮
    case emptyRoundDashButton(image: UIImage)
    /// 固定右上角的圆角按钮
    case fixedTopRightRoundedButton(image: UIImage)
    /// 垂直居中带文字的按钮（图标+文字）
    /// 历史上仅扫码录入的条码字段，和仅定位录入的地理位置字段使用了这个样式，但是后续这两个被优化为 emptyRoundDashButton
    /// 目前，只有仅定位录入的地理位置字段，在点击后显示  "loading + 获取中..." 时用到了这个样式（图标隐藏）
    /// 因此这个样式目前基本作为 emptyRoundDashButton 的 loading 样式使用
    case centerVerticallyWithIconText(image: UIImage, text: String)
    /// 自定义文本占位，不支持编辑
    case placeholder(text: String)
}
