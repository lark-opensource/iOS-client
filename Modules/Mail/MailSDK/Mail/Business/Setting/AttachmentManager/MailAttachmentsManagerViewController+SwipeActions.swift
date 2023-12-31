//
//  MailAttachmentsManagerViewController+SwipeActions.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/4.
//

import Foundation
import LarkSwipeCellKit
import RustPB
import RxSwift
import LarkZoomable
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import LarkAlertController
import EENavigator
import LarkUIKit

public enum MailAttachmentsListCellSwipeAction: String {
    case deleteAttachment
}

extension MailAttachmentsListCellSwipeAction {
    
    func actionIcon() -> UIImage {
        switch self {
        case .deleteAttachment:
            return UDIcon.deleteTrashOutlined.ud.colorize(color: UIColor.ud.staticWhite)

        }
    }
    
    func actionBgColor() -> UIColor {
        switch self {
        case .deleteAttachment:
            return UIColor.ud.R500
        }
    }
}

extension MailAttachmentsManagerViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if isMultiSelecting {
            return nil
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? MailAttachmentsListCell else {
            return nil
        }
        
        let manager = viewModel
        if let cellViewModel = cell.cellViewModel {
            let swipeAction = MailAttachmentsListCellSwipeAction.deleteAttachment
            if orientation == .right {
                MailLogger.debug("[mail_swipe_actions] editActionsForRowAt orientation right: \(MailAttachmentsListCellSwipeAction.deleteAttachment)")
                return deleteAction(swipeAction, cell, cellViewModel)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // 微调左右滑动的样式
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    
        var options = SwipeOptions()

        // 消失动画。。有点模糊
        // disable-lint: magic_number
        let style = SwipeExpansionStyle(target: .edgeInset(120),
            additionalTriggers: [.overscroll(150)],
            elasticOverscroll: true,
            completionAnimation: .fill(.manual(timing: .after)))
        let readStyle = SwipeExpansionStyle(target: .percentage(0.3),
                                            additionalTriggers: [.overscroll(30)],
                                            elasticOverscroll: true,
                                            completionAnimation: .bounce)
        // enable-lint: magic_number
        if let cell = tableView.cellForRow(at: indexPath) as? MailAttachmentsListCell, let cellVM = cell.cellViewModel {
            options.expansionStyle = readStyle
            options.expansionStyle = style
            options.transitionStyle = SwipeTransitionStyle.custom(FeedBorderTransitionLayout())
        }
        // disable-lint: magic_number
        options.buttonHorizontalPadding = 12
        options.buttonSpacing = 4
        options.maximumButtonWidth = 84
        options.minimumButtonWidth = 84
        options.buttonWidthStyle = .auto
        options.buttonVerticalAlignment = .center
        // enable-lint: magic_number
        
        let angleLimit: Double = 1.3
        // 上下滑动触发机制, 调整角度使横向手势触发概率变小
        // 目前参数定制为拖拽角度小于 35 度触发
        options.shouldBegin = { (x, y) in
            return abs(y) * angleLimit < abs(x)
        }
        return options
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
    }
    
    func deleteAction(_ action: MailAttachmentsListCellSwipeAction,
                      _ cell: MailAttachmentsListCell,
                      _ cellViewModel: MailAttachmentsListCellViewModel) -> [SwipeAction] {
        var swipeAction: SwipeAction
        let icon = action.actionIcon()
        let bgColor = action.actionBgColor()
        switch action {
        case .deleteAttachment:
            var deleteAttachment = SwipeAction(style: .destructive, title:nil) { [weak self] (_, _, _) in
                guard let self = self else { return }
                self.markForAttachment(cell, cellModel: cellViewModel)
            }
            configAction(&deleteAttachment, bgColor: bgColor, iconImage: icon)
            swipeAction = deleteAttachment
        }
        return [swipeAction]
    }
    
    private func configAction(_ action: inout SwipeAction, bgColor: UIColor, iconImage: UIImage, onboard: Bool = false) {
        action.backgroundColor = bgColor
        action.image = iconImage.scaled(toPercentage: Zoom.currentZoom.scale)
        action.hidesWhenSelected = true
        action.transitionDelegate = ScaleTransition.default
    }
    
    func markForAttachment(_ cell: MailAttachmentsListCell, cellModel: MailAttachmentsListCellViewModel) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        if !viewModel.dataSource.isEmpty {
            if tableView.cellForRow(at: indexPath) != nil {
                if let fileToken = cellModel.fileToken,
                   let fileName = cellModel.fileName,
                   let fileSize = cellModel.fileSize{
                    let alert = LarkAlertController()
                    alert.setTitle(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Title)
                    alert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Desc(fileName))
                    alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Cancel)
                    alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Delete, dismissCompletion:  { [weak self] in
                        guard let self = self else { return }
                        let dic = [Int64(indexPath.row):fileToken]
                        self.viewModel.deleteData(deleteList: dic, indexPath: indexPath)
                        self.accountContext.securityAudit.audit(type:.largeAttachmentDelete(mailInfo: AuditMailInfo(smtpMessageID: cellModel.mailSmtpID ?? "",subject: "",sender: "", ownerID: nil, isEML: false), fileID: fileToken, fileSize: Int(fileSize), fileName: fileName))
                    })
                    self.accountContext.navigator.present(alert, from: self)
                }
            }
        } else {
            if tableView.cellForRow(at: indexPath) != nil {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

fileprivate extension UIImage {

    /// 将图片按比例缩放，返回缩放后的图片
    /// - Parameter percentage: 缩放比例
    /// - Parameter opaque: 当前图片是否有透明部分
    func scaled(toPercentage percentage: CGFloat, opaque: Bool = false) -> UIImage? {
        let factor = scale == 1.0 ? UIScreen.main.scale : 1.0
        let newWidth = floor(size.width * percentage / factor)
        let newHeight = floor(size.height * percentage / factor)
        let newRect = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        let format = imageRendererFormat
        format.opaque = opaque
        format.scale = 0
        return UIGraphicsImageRenderer(size: newRect.size, format: format).image { _ in
            draw(in: newRect)
        }
    }
}

