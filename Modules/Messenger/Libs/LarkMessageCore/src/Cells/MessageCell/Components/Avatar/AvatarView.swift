//
//  AvatarView.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/14.
//

import UIKit
import Foundation
import LarkUIKit

//public class AvatarView: UIControl {
//    lazy private(set) var imageView: UIImageView = {
//        var imageView = UIImageView(image: nil)
//        imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
//        imageView.contentMode = .scaleAspectFill
//        return imageView
//    }()
//
//    public var lastingColor: UIColor = UIColor.ud.N50
//
//    private var tapGesture: UITapGestureRecognizer?
//    public var onTapped: ((AvatarView) -> Void)? {
//        didSet {
//            if let gesture = self.tapGesture {
//                self.removeGestureRecognizer(gesture)
//                self.tapGesture = nil
//            }
//            if onTapped != nil {
//                self.tapGesture = self.lu.addTapGestureRecognizer(action: #selector(tapEvent))
//            }
//        }
//    }
//
//    private var longPressGesture: UILongPressGestureRecognizer?
//    public var onLongPress: ((AvatarView) -> Void)? {
//        didSet {
//            if let gesture = self.longPressGesture {
//                self.removeGestureRecognizer(gesture)
//                self.longPressGesture = nil
//            }
//            if onLongPress != nil {
//                self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(longPressEvent(_:)), duration: 0.2)
//            }
//        }
//    }
//
//    public convenience init() {
//        self.init(frame: .zero)
//    }
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        commonInit()
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//
//    private func commonInit() {
//        self.backgroundColor = UIColor.ud.N300
//        self.addSubview(imageView)
//        self.clipsToBounds = true
//        self.imageView.frame = bounds
//        self.layer.cornerRadius = bounds.width / 2
//        self.clipsToBounds = true
//    }
//
//    public override var frame: CGRect {
//        didSet {
//            imageView.frame = bounds
//            layer.cornerRadius = bounds.width / 2
//        }
//    }
//
//    public override func draw(_ rect: CGRect) {
//        lastingColor.setFill()
//        UIRectFill(rect)
//        super.draw(rect)
//    }
//
//    public func set(avatarKey: String = "", placeholder: UIImage? = nil, image: UIImage? = nil) {
//        guard !avatarKey.isEmpty else {
//            self.imageView.image = image
//            return
//        }
//        var fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
//        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
//        self.imageView.lk.setAvatar(key: fixedKey, placeholder: placeholder)
//    }
//
//    @objc
//    func tapEvent() {
//        self.onTapped?(self)
//    }
//
//    @objc
//    func longPressEvent(_ recognizer: UILongPressGestureRecognizer) {
//        switch recognizer.state {
//        case .began:
//            if let avatarView = recognizer.view as? AvatarView {
//                self.onLongPress?(avatarView)
//                return
//            }
//        default:
//            break
//        }
//    }
//}
