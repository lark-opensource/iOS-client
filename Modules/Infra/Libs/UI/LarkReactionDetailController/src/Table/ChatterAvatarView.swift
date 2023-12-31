//
//  ChatterAvatarView.swift
//  LarkReactionDetailController
//
//  Created by 李晨 on 2019/6/17.
//

import Foundation
import UIKit

open class ChatterAvatarView: UIView {

    lazy private(set) var imageView: UIImageView = {
        var imageView = UIImageView(image: nil)
        imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public var lastingColor: UIColor = UIColor.ud.colorfulRed

    public override func draw(_ rect: CGRect) {
        lastingColor.setFill()
        UIRectFill(rect)
        super.draw(rect)
    }

    private func commonInit() {
        self.backgroundColor = UIColor.ud.N300
        self.lastingColor = UIColor.ud.N50
        self.addSubview(self.imageView)
        self.clipsToBounds = true
        self.imageView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(self)
        }

        self.imageView.accessibilityIdentifier = "chatter.avatar.image"
    }
}
