//
//  PickerFocusStatusService.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/10/8.
//

import UIKit
import RustPB
import LarkListItem
import LarkFocusInterface
import LarkContainer

class PickerFocusStatusService: ItemStatusServiceType {
    func generateStatusView(status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?) -> UIView? {
        guard let topStatus = status?.topActive else { return nil }
        let tagView = service?.generateTagView()
        tagView?.config(with: topStatus)
        return tagView
    }

    var service: FocusService?
    var userId: String?
    init(userId: String?) {
        guard let userId else { return }
        self.userId = userId
        let resolver = try? Container.shared.getUserResolver(userID: userId)
        self.service = try? resolver?.resolve(assert: FocusService.self)
    }
}
