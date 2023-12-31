//
//  MenuButton.swift
//  Action
//
//  Created by 赵冬 on 2019/7/20.
//

import Foundation
import UIKit

private let iconSize: CGFloat = 20

public final class MenuButton: UIControl {
    public typealias TapCallback = (MenuButton) -> Void

    public lazy var icon: UIImageView = {
        let icon = UIImageView(frame: .zero)
        icon.contentMode = .scaleAspectFill
        return icon
    }()

    public var onTapped: TapCallback?

    public override var frame: CGRect {
        didSet {
            layout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(icon: UIImage) {
        self.icon.image = icon

        layout()
    }

    public class func getSize(_ size: CGSize) -> CGSize {

        return CGSize(
            width: iconSize + 4,
            height: iconSize + 4
        )
    }

    private func commonInit() {
        self.addSubview(icon)
        icon.frame = CGRect(origin: .zero, size: CGSize(width: iconSize, height: iconSize))
        icon.center = self.frame.center

        self.hitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        self.addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }

    @objc
    private func selfTapped() {
        self.onTapped?(self)
    }

    private func layout() {
        icon.frame = CGRect(origin: .zero, size: CGSize(width: iconSize, height: iconSize))
        icon.center = self.frame.center
    }
}
