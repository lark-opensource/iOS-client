//
//  BizAvatar.swift
//  BizAvatar
//
//  Created by 姚启灏 on 2020/6/18.
//

import UIKit
import Foundation
import LarkAvatarComponent
import AvatarComponent
import LarkBadge
import ByteWebImage
import UniverseDesignTheme
import UniverseDesignColor
import LarkExtensions
import AppReciableSDK

// swiftlint:disable missing_docs
public struct MiniIconProps {
    public enum TypeEnum {
        case unknown
        case dynamicURL(URL)
        case dynamicKey(String)
        case dynamicIcon(UIImage)
        case thread
        case topic
        case ppt
        case docs
        case sheet
        case mindmap
        case table
        case micoApp
    }

    public var type: TypeEnum
    public var placeholder: UIImage?

    public init(_ type: TypeEnum = .unknown, placeholder: UIImage? = nil) {
        self.type = type
        self.placeholder = placeholder
    }
}

open class BizAvatar: UIView {

    open lazy var avatar: LarkAvatar = {
        var config = AvatarComponentUIConfig()
        config.style = .circle
        let avatar = LarkAvatar(frame: .zero, config: config)
        // MyAI 引入了透明的头像，作为基础组件，LarkAvatar 不再设置背景颜色，由业务决定
        avatar.backgroundColor = .clear
        avatar.ud.setMaskView()
        return avatar
    }()

    open lazy var border: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        return imageView
    }()

    open lazy var topBadge: BadgeView = {
        let badge = BadgeView(with: .none)
        return badge
    }()

    open lazy var bottomBadge: BadgeView = {
        let badge = BadgeView(with: .none)
        return badge
    }()

    private var imageSource: ImageSource?

    var borderSize: CGSize?

    public var image: UIImage? {
        get {
            return avatar.image
        }
        set {
            avatar.image = newValue
        }
    }

    open var lastingColor: UIColor {
        get {
            return avatar.lastingColor
        }
        set {
            avatar.lastingColor = newValue
        }
    }

    open var borderImage: UIImage? {
        get {
            return border.image
        }
        set {
            border.image = newValue
        }
    }

    open override var backgroundColor: UIColor? {
        get {
            return avatar.backgroundColor
        }
        set {
            avatar.backgroundColor = newValue
        }
    }

    private var tapGesture: UITapGestureRecognizer?
    open var onTapped: ((BizAvatar) -> Void)? {
        didSet {
            if let gesture = self.tapGesture {
                self.removeGestureRecognizer(gesture)
                self.tapGesture = nil
            }
            if onTapped != nil {
                self.tapGesture = self.lu.addTapGestureRecognizer(action: #selector(tapEvent))
            }
        }
    }

    private var longPressGesture: UILongPressGestureRecognizer?
    open var onLongPress: ((BizAvatar) -> Void)? {
        didSet {
            if let gesture = self.longPressGesture {
                self.removeGestureRecognizer(gesture)
                self.longPressGesture = nil
            }
            if onLongPress != nil {
                self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(longPressEvent(_:)), duration: 0.2)
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(border)
        addSubview(avatar)
        addSubview(topBadge)
        addSubview(bottomBadge)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Use arcFactor to decide the top-right or bottom-right position of circular avatar.
    /// This is the ratio of x coordinate point in top-right or bottom-right corner by circle diameter.
    private lazy var arcFactor: CGFloat = {
        return CGFloat((1 - 1 / sqrt(2)) / 2)
    }()

    open override func layoutSubviews() {
        super.layoutSubviews()
        avatar.frame = bounds

        if let borderSize = borderSize {
            border.bounds = CGRect(x: bounds.minX, y: bounds.minY, width: borderSize.width, height: borderSize.height)
            border.center = avatar.center
        } else {
            border.frame = bounds
        }

        topBadge.frame.origin = {
            let W = bounds.width
            let H = bounds.height
            let w = topBadge.bounds.width
            let h = topBadge.bounds.height
            let x = W * (1 - arcFactor) - w + h / 2
            let y = H * arcFactor - h / 2
            // NOTE: Non-integral coordinate might cause cutting issue on some devices
            // with special physical scale, like iPhone Xr.
            return CGPoint(x: ceil(x), y: floor(y))
        }()

        bottomBadge.frame.origin = {
            let W = bounds.width
            let H = bounds.height
            let w = bottomBadge.bounds.width
            let h = bottomBadge.bounds.height
            let x = W * (1 - arcFactor) - w + h / 2
            let y = H * (1 - arcFactor) - h / 2
            return CGPoint(x: ceil(x), y: ceil(y))
        }()
    }

    /// Bind the identifier and the corresponding avatarKey
    /// - Parameters:
    ///   - identifier:
    ///   - avatarKey:
    ///   - completion: 当size超过阈值(98)时，会先下载middle，再下载big的image，此时completion会回调多次
    open func setAvatarByIdentifier(_ identifier: String,
                                    avatarKey: String,
                                    placeholder: UIImage? = nil,
                                    options: ImageRequestOptions? = nil,
                                    avatarViewParams: AvatarViewParams = .defaultMiddle,
                                    backgroundColorWhenError: UIColor = UIColor.ud.N300,
                                    completion: ImageRequestCompletion? = nil) {
//        if identifier.isEmpty {
//            assertionFailure("identifier is empty, please check the identifier")
//        }
        let dealedIdentifier = identifier.isEmpty ? "0" : identifier
        self.setAvatarByIdentifier(dealedIdentifier,
                                   avatarKey: avatarKey,
                                   scene: .Chat,
                                   placeholder: placeholder,
                                   options: options,
                                   avatarViewParams: avatarViewParams,
                                   backgroundColorWhenError: backgroundColorWhenError,
                                   completion: completion)
    }

    /// Bind the identifier and the corresponding avatarKey
    /// - Parameters:
    ///   - identifier:
    ///   - avatarKey:
    ///   - scene:
    ///   - completion: 当size超过阈值(98)时，会先下载middle，再下载big的image，此时completion会回调多次
    open func setAvatarByIdentifier(_ identifier: String,
                                    avatarKey: String,
                                    scene: Scene,
                                    placeholder: UIImage? = nil,
                                    options: ImageRequestOptions? = nil,
                                    avatarViewParams: AvatarViewParams = .defaultMiddle,
                                    backgroundColorWhenError: UIColor = UIColor.ud.N300,
                                    completion: ImageRequestCompletion? = nil) {
        if identifier.isEmpty {
            assertionFailure("identifier is empty, please check the identifier")
        }
        let dealedIdentifier = identifier.isEmpty ? "0" : identifier
        avatar.setAvatarKeyByIdentifier(dealedIdentifier,
                                        avatarKey: avatarKey,
                                        scene: scene,
                                        placeholder: placeholder,
                                        options: options,
                                        avatarViewParams: avatarViewParams,
                                        backgroundColorWhenError: backgroundColorWhenError,
                                        completion: completion)
    }

    /// Set configuration and update component properties
    /// - Parameter config: AvatarComponent UI Config
    open func setAvatarUIConfig(_ config: AvatarComponentUIConfig) {
        avatar.updateConfig(config)
    }

    @objc
    func tapEvent() {
        self.onTapped?(self)
    }

    @objc
    func longPressEvent(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if let avatarView = recognizer.view as? BizAvatar {
                self.onLongPress?(avatarView)
                return
            }
        default:
            break
        }
    }
}

/// avatarBorderView related extensions
public extension BizAvatar {
    func updateBorderImage(_ image: UIImage?) {
        borderImage = image
        border.isHidden = image == nil ? true : false
    }

    func updateBorderSize(_ size: CGSize?) {
        borderSize = size
        setNeedsLayout()
    }
    
    func updateBorderColorAndWidth(_ color: UIColor?, _ width: CGFloat) {
        guard let color = color, width > 0 else {
            border.isHidden = true
            return
        }
        border.layer.borderWidth = width
        border.ud.setLayerBorderColor(color)
        border.isHidden = false
    }
}

/// topBadgeView related extensions
public extension BizAvatar {
    func updateBadge(_ type: BadgeType, style: BadgeStyle) {
        topBadge.type = type
        topBadge.style = style
        setNeedsLayout()
    }
}

/// bottomImageView related extensions
public extension BizAvatar {
    func setMiniIcon(_ miniIcon: MiniIconProps?) {
        self.setBottomIcon(Self.convertToBadge(miniIcon))
        setNeedsLayout()
    }

    func setBottomIcon(_ imageSource: ImageSource?) {
        guard let source = imageSource else {
            bottomBadge.type = .none
            return
        }
        bottomBadge.type = BadgeType.image(source)
    }

    @inline(__always)
    static func convertToBadge(_ miniIcon: MiniIconProps?) -> ImageSource? {
        guard let miniIcon = miniIcon else {
            return nil
        }
        var imageSource: ImageSource
        switch miniIcon.type {
        case .unknown:
            return nil
        case let .dynamicIcon(image):
            imageSource = .image(image)
        case let .dynamicKey(key):
            imageSource = .key(key)
        case let .dynamicURL(url):
            imageSource = .web(url)
        case .docs:
            imageSource = .image(Resources.doc)
        case .ppt:
            imageSource = .image(Resources.ppt)
        case .mindmap:
            imageSource = .image(Resources.mindmap)
        case .sheet:
            imageSource = .image(Resources.sheet)
        case .table:
            imageSource = .image(Resources.table)
        case .micoApp:
            imageSource = .image(Resources.micoApp)
        case .thread:
            imageSource = .image(Resources.thread)
        case .topic:
            imageSource = .image(Resources.topic)
        }
        return imageSource
    }
}
// swiftlint:disable missing_docs
