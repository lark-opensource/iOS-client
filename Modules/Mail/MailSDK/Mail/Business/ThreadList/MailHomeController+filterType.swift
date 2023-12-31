//
//  MailHomeController+filterType.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/12/26.
//

import Foundation
import Homeric
import EENavigator
import UniverseDesignMenu
import UniverseDesignIcon

extension MailHomeController {
    func getTagMenu() -> MailTagViewController {
        if let labelsMenuController = self.labelsMenuController {
            return labelsMenuController
        } else {
            self.labelsMenuController = makeTagMenu()
            return self.labelsMenuController!
        }
    }

    func showDropMenu() {
        guard let titleView = self.getLarkNavbar()?.getTitleTappedSourceView() else {
            return
        }
        let dropController = getTagMenu()
        dropController.updateInit(selectedLabelId: viewModel.currentLabelId, selectedFilter: viewModel.currentFilterType)
        guard !dropController.isBeingPresented else { return }
        guard self.presentedViewController == nil else { return }
        if rootSizeClassIsSystemRegular {
            dropController.modalPresentationStyle = .popover
            dropController.preferredContentSize = CGSize(width: MailTagViewController.Layout.popWidth, height: self.view.bounds.size.height / 2)
            dropController.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            dropController.popoverPresentationController?.sourceView = titleView
            dropController.popoverPresentationController?.sourceRect = titleView.bounds
            dropController.changeDisplayMode(mode: .popoverMode)

        } else {
            dropController.modalPresentationStyle = .overFullScreen
            dropController.changeDisplayMode(mode: .normalMode)
        }
        navigator?.present(dropController, from: self)
    }

    func createPopupMenu(filterType: MailThreadFilterType) -> PopupMenuActionItem? {
        switch filterType {
        case .unread:
            return PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_UnreadOnlyMobile_Button,
                                        icon: UDIcon.filterOutlined,
                                    callback: { [weak self] (menu, action) in
                guard let `self` = self else { return }
                self.switchLabelAndFilterType(self.viewModel.currentLabelId, labelName: self.viewModel.currentLabelName, filterType: .unread)
            })
        @unknown default:
            return nil
        }
    }
}
