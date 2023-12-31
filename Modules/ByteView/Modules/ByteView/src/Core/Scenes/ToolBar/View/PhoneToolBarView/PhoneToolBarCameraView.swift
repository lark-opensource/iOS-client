//
//  PhoneToolBarCameraView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/10.
//

import UIKit
import UniverseDesignIcon

class PhoneToolBarCameraView: PhoneToolBarItemView {
    static let unauthorizedIconSize = CGSize(width: 16, height: 16)
    let unauthorizedView = UIImageView()
    private var isUIMuted = false

    deinit {
        item.meeting.syncChecker.unregisterCamera(self)
    }

    override func setupSubviews() {
        super.setupSubviews()

        unauthorizedView.image = BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: Self.unauthorizedIconSize)
        unauthorizedView.contentMode = .scaleAspectFill
        button.addSubview(unauthorizedView)
        item.meeting.syncChecker.registerCamera(self)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarCameraItem else { return }
        unauthorizedView.isHidden = !item.unauthorized
        isUIMuted = item.isMuted || item.unauthorized
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        unauthorizedView.frame = CGRect(origin: CGPoint(x: iconView.frame.minX + 12.5,
                                                        y: iconView.frame.minY + 8.5),
                                        size: Self.unauthorizedIconSize)
    }
}

extension PhoneToolBarCameraView: CameraStateRepresentable {
    var isCameraMuted: Bool? {
        isUIMuted
    }

    var cameraIdentifier: String {
        "ToolBarCamera"
    }
}
