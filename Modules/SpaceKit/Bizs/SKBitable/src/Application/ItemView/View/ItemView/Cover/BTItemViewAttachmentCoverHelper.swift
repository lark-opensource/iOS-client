//
//  BTItemViewAttachmentCoverHelper.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/2.
//

import Foundation
import SKUIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKFoundation
import UniverseDesignEmpty
import HandyJSON

final class BTItemViewAttachmentCoverHelper {
    static func attachmentCoverHandlePanGesture(_ gesture: UIPanGestureRecognizer, currentCard: BTRecord?) {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        guard let attachmentCoverCells = currentCard?.fieldsView.visibleCells.filter({ $0 is BTAttachmentCoverCell }) else {
            return
        }
        guard let attachmentCoverCell = attachmentCoverCells.first as? BTAttachmentCoverCell else {
            return
        }
        switch gesture.state {
        case .began:
            attachmentCoverCell.update(isScrollEnabled: false)
        case .changed:
            break
        case .ended, .cancelled, .failed:
            attachmentCoverCell.update(isScrollEnabled: true)
        default:
            attachmentCoverCell.update(isScrollEnabled: true)
        }
    }

    static func operateItemViewCover(
        hostVC: UIViewController,
        recordModel: BTRecordModel,
        sourceView: UIView,
        editEngine: BTViewModel,
        trackParams: [String: Any],
        baseContext: BaseContext
    ) -> BTPanelController {
        var vc: BTPanelController?

        let selectCallback: BTCommonDataItem.SelectCallback = { [weak editEngine] (_, id, useInfo) in
            guard let itemId = id else { return }
            let index = Int(itemId) ?? 0

            if let editEngine = editEngine {
                Self.executeCommands(index: index, editEngine: editEngine, record: recordModel)
            }

            vc?.dismiss(animated: true)
            Self.logPanelDismiss(isCover: index != 0, trackParams: trackParams)
        }

        let panelData = Self.panelData(recordModel: recordModel, selectCallback: selectCallback)
        let panel = BTPanelController(
            title: BundleI18n.SKResource.Bitable_ItemView_SetRecordCover_Title,
            data: panelData,
            delegate: nil,
            hostVC: hostVC,
            baseContext: baseContext
        )
        panel.setCaptureAllowed(true)
        panel.popoverDisappearBlock = {
            Self.logPanelDismiss(isCover: recordModel.currentCoverAttachmentField != nil, trackParams: trackParams)
        }
        vc = panel
        panel.modalPresentationStyle = .overCurrentContext
        panel.dismissalStrategy = [SKPanelDismissalStrategy.viewSizeChanged, SKPanelDismissalStrategy.larkSizeClassChanged, SKPanelDismissalStrategy.systemSizeClassChanged]

        if SKDisplay.pad {
            panel.modalPresentationStyle = .popover
            panel.popoverPresentationController?.sourceView = sourceView
            panel.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            panel.popoverPresentationController?.backgroundColor = UDColor.bgFloatBase.withAlphaComponent(0.9)
        }

        return panel
    }

    private static func logPanelDismiss(isCover: Bool, trackParams: [String: Any]) {
        var params = trackParams
        params["is_cover"] = isCover ? "true" : "false"
        DocsTracker.newLog(
            enumEvent: .bitableCardAttachmentCoverSettingViewHide,
            parameters: params
        )
    }

    private static func executeCommands(index: Int, editEngine: BTViewModel, record: BTRecordModel) {
        var cardCoverId = ""
        if index > 0 {
            let attachmentIndex = index - 1
            let attachments = record.allAttachmentFields
            if attachmentIndex < attachments.count, attachmentIndex >= 0 {
                let attachment = attachments[attachmentIndex]
                cardCoverId = attachment.fieldID
            }
        }

        let fieldInfo = BTJSFieldInfoArgs()
        let args = BTExecuteCommandArgs(
            command: .setExType,
            tableID: editEngine.actionParams.data.tableId,
            viewID: editEngine.actionParams.data.viewId,
            fieldInfo: fieldInfo,
            property: nil,
            checkConfirmValue: nil,
            extraParams: ["tableExInfo": ["cardCoverId": cardCoverId]]
        )
        editEngine.dataService?.executeCommands(args: args, resultHandler: { failReason, error in
            DocsLogger.btError("[Attachment cover] executeCommands fail \(failReason?.rawValue ?? -1), \(error?.localizedDescription ?? "")")
        })
    }

    private static func panelData(
        recordModel: BTRecordModel,
        selectCallback: BTCommonDataItem.SelectCallback
    ) -> BTCommonDataModel {
        let attachments = recordModel.allAttachmentFields
        if attachments.isEmpty {
            let model = BTPanelEmptyContentModel (
                contentImage: .noContent,
                desc: BundleI18n.SKResource.Bitable_ItemView_NoAttachmentField_Desc
            )
            return BTCommonDataModel(groups: [], contentExtendModel: .EMPTY_VIEW, extra: model.toJSONString())
        }
        let group = Self.panelGroup(recordModel: recordModel, selectCallback: selectCallback)
        return BTCommonDataModel(groups: group)
    }

    private static func panelGroup(
        recordModel: BTRecordModel,
        selectCallback: BTCommonDataItem.SelectCallback
    ) -> [BTCommonDataGroup] {
        let currentCoverAttachment = recordModel.currentCoverAttachmentField
        let isUnCover = !recordModel.shouldShowAttachmentCoverField()
        let uncoverIconColor = Self.iconColor(isSelected: isUnCover)
        let uncoverTextColor = Self.textColor(isSelected: isUnCover)
        let unCoverIcon = UDIcon.getIconByKey(.banOutlined).ud.withTintColor(uncoverIconColor)
        let selectedIcon = Self.selectedIcon()
        let unCoverList = [
            BTCommonDataItem(
                id: "0",
                selectable: true,
                selectCallback: selectCallback,
                leftIcon: .init(
                    image: unCoverIcon,
                    size: CGSize(width: 20, height: 20),
                    alignment: BTCommonDataItemIconInfo.ItemIconAlignment.top(offset: 0)
                ),
                mainTitle: .init(text: BundleI18n.SKResource.Bitable_ItemView_NoCover_Option, color: uncoverTextColor),
                rightIcon: isUnCover ? selectedIcon: nil
            )
        ]

        var fieldList = [BTCommonDataItem]()
        let attachments = recordModel.allAttachmentFields
        for (index, attachment) in attachments.enumerated() {
            let showRightIcon = currentCoverAttachment?.fieldID == attachment.fieldID

            let iconColor = Self.iconColor(isSelected: showRightIcon)
            let textColor = Self.textColor(isSelected: showRightIcon)
            let item = BTCommonDataItem(
                id: "\(index + 1)",
                selectable: true,
                selectCallback: selectCallback,
                leftIcon: .init(
                    image: UDIcon.attachmentOutlined.ud.withTintColor(iconColor),
                    size: CGSize(width: 20, height: 20),
                    alignment: BTCommonDataItemIconInfo.ItemIconAlignment.top(offset: 0)
                ),
                mainTitle: .init(text: attachment.name, color: textColor),
                rightIcon: showRightIcon ? selectedIcon : nil
            )
            fieldList.append(item)
        }

        let group = [
            BTCommonDataGroup(groupName: "attachmentCover-unCover", items: unCoverList),
            BTCommonDataGroup(groupName: "attachmentCover-field", items: fieldList)
        ]
        return group
    }

    static private func iconColor(isSelected: Bool) -> UIColor {
        return isSelected ? UDColor.primaryPri500 : UIColor.ud.iconN1
    }

    static private func textColor(isSelected: Bool) -> UIColor {
        return isSelected ? UDColor.primaryPri500 : UIColor.ud.textTitle
    }

    static private func selectedIcon() -> BTCommonDataItemIconInfo {
        let image = UDIcon.getIconByKey(
            .doneOutlined,
            iconColor: UDColor.primaryContentDefault
        )
        return BTCommonDataItemIconInfo(image: image, size: CGSize(width: 20, height: 20))
    }
}
