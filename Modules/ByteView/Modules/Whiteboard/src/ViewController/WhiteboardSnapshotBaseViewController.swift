//
//  WhiteboardSnapshotBaseViewController.swift
//  Whiteboard
//
//  Created by helijian on 2023/11/6.
//

import Foundation
import LarkAlertController
import ByteViewNetwork
import UniverseDesignToast

public class WhiteboardSnapshotBaseViewController: UIViewController {
    func deleteOnePage(item: WhiteboardSnapshotItem?, whiteboardId: Int64, userId: String) {
        guard let item = item else { return }
        // 弹出确认删除弹窗
        WhiteboardTracks.trackBoardClick(.multiBoardDeletePage(pageNum: Int(item.page.pageNum)), whiteboardId: whiteboardId)
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.Whiteboard.View_G_ConfirmDeleteBoard)
        alert.addCancelButton()
        alert.addDestructiveButton(text: BundleI18n.Whiteboard.View_G_Delete, dismissCheck: {
            return true
        }, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let request = OperateWhiteboardPageRequest(action: .deletePage, whiteboardId: item.whiteboardId, pages: [item.page])
            HttpClient(userId: userId).getResponse(request) { r in
                switch r {
                case .success:
                    logger.info("operateWhiteboardPage deletePage success")
                case .failure(let error):
                    logger.info("operateWhiteboardPage deletePage error: \(error)")
                }
                DispatchQueue.main.async {
                    let config = UDToastConfig(toastType: .info, text: BundleI18n.Whiteboard.View_G_WhiteboardDeletedToast, operation: nil)
                    if let window = self.view.window {
                        UDToast.showToast(with: config, on: window)
                    }
                }
            }
        })
        self.present(alert, animated: true)
    }
}
