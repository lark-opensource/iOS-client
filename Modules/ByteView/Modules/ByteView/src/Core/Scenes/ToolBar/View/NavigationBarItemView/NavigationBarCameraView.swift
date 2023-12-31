//
//  NavigationBarCameraView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/13.
//

import UIKit

class NavigationBarCameraView: NavigationBarItemView {
    static let unauthorizedIconSize = CGSize(width: 16, height: 16)
    let unauthorizedView = UIImageView()

    override func setupSubviews() {
        super.setupSubviews()
        unauthorizedView.image = BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: Self.unauthorizedIconSize)
        unauthorizedView.contentMode = .scaleAspectFill
        addSubview(unauthorizedView)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarCameraItem else { return }
        unauthorizedView.isHidden = !item.unauthorized
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let newFrame = CGRect(origin: CGPoint(x: button.frame.minX + 16,
                                              y: button.frame.minY + 12),
                              size: Self.unauthorizedIconSize)
        if unauthorizedView.frame != newFrame {
            unauthorizedView.frame = newFrame
        }
    }
}
