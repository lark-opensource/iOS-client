//
//  ImageViewAligned.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/12/3.
//

// Refactor from UIImageViewAligned: UIImageViewAligned继承自UIImageView，
// 在复用等复杂刷新场景下有Bug（如不能清除supper ImageView的image等）
import UIKit
import Foundation
public struct ImageViewAlignmentMask: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// The option to align the content to the center.
    public static let center = ImageViewAlignmentMask(rawValue: 0)
    /// The option to align the content to the left.
    public static let left = ImageViewAlignmentMask(rawValue: 1)
    /// The option to align the content to the right.
    public static let right = ImageViewAlignmentMask(rawValue: 2)
    /// The option to align the content to the top.
    public static let top = ImageViewAlignmentMask(rawValue: 4)
    /// The option to align the content to the bottom.
    public static let bottom = ImageViewAlignmentMask(rawValue: 8)
    /// The option to align the content to the top left.
    public static let topLeft: ImageViewAlignmentMask = [top, left]
    /// The option to align the content to the top right.
    public static let topRight: ImageViewAlignmentMask = [top, right]
    /// The option to align the content to the bottom left.
    public static let bottomLeft: ImageViewAlignmentMask = [bottom, left]
    /// The option to align the content to the bottom right.
    public static let bottomRight: ImageViewAlignmentMask = [bottom, right]
}

open class ImageViewAligned: UIView {
    public private(set) var realImageView: UIImageView

    open var image: UIImage? {
        set {
            realImageView.image = newValue
            setNeedsLayout()
        }
        get {
            return realImageView.image
        }
    }

    open var alignment: ImageViewAlignmentMask = .center {
        didSet {
            guard alignment != oldValue else { return }
            updateLayout()
        }
    }

    open override var contentMode: UIView.ContentMode {
        didSet {
            realImageView.contentMode = contentMode
        }
    }

    private var realContentSize: CGSize {
        var size = bounds.size
        guard let image = image, image.size.width > 0, image.size.height > 0 else { return size }

        let scaleX = size.width / image.size.width
        let scaleY = size.height / image.size.height

        switch contentMode {
        case .scaleAspectFill:
            let scale = max(scaleX, scaleY)
            size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        case .scaleAspectFit:
            let scale = min(scaleX, scaleY)
            size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        case .scaleToFill:
            size = CGSize(width: image.size.width * scaleX, height: image.size.height * scaleY)
        default:
            size = image.size
        }
        return size
    }

    public override init(frame: CGRect) {
        realImageView = UIImageView(image: nil)
        super.init(frame: frame)
        realImageView.frame = bounds
        realImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        realImageView.contentMode = contentMode
        addSubview(realImageView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        updateLayout()
    }

    private func updateLayout() {
        let realSize = realContentSize
        var realFrame = CGRect(origin: CGPoint(x: (bounds.size.width - realSize.width) / 2.0,
                                               y: (bounds.size.height - realSize.height) / 2.0),
                               size: realSize)

        if alignment.contains(.left) {
            realFrame.origin.x = 0.0
        } else if alignment.contains(.right) {
            realFrame.origin.x = bounds.maxX - realFrame.size.width
        }

        if alignment.contains(.top) {
            realFrame.origin.y = 0.0
        } else if alignment.contains(.bottom) {
            realFrame.origin.y = bounds.maxY - realFrame.size.height
        }

        realImageView.frame = realFrame.integral
    }
}

public final class ImageViewAlignedWrapper: ImageViewAligned {
    public typealias SetImageCompletion = (Config) -> Void
    public typealias SetImageTask = (CGSize, @escaping SetImageCompletion) -> Void

    public struct Config {
        public var image: UIImage?
        public var contentMode: UIView.ContentMode
        public var alignment: ImageViewAlignmentMask
        public var error: Error?

        public init(image: UIImage?,
                    contentMode: UIView.ContentMode = .scaleAspectFill,
                    alignment: ImageViewAlignmentMask = .top,
                    error: Error? = nil) {
            self.image = image
            self.contentMode = contentMode
            self.alignment = alignment
            self.error = error
        }
    }

    private var identifier: String?
    private var oldSize: CGSize = .zero

    public func setImage(identifier: String?, task: SetImageTask?) {
        assert(Thread.isMainThread, "must call on main thread")
        // VM可能在请求返回前被提前deinit，导致SetImageCompletion未回调，会造成image和url之间状态不匹配，
        // 这样下次设置相同url会被拦截使得图片无法展示；因此此处提前重置一下image和url的状态
        if self.image == nil {
            self.identifier = nil
            self.oldSize = .zero
        }

        if !shouldUpdate(identifier: identifier) {
            return
        }
        // reset
        self.image = nil
        self.contentMode = .scaleAspectFill
        self.alignment = .top

        self.identifier = identifier
        self.oldSize = self.bounds.size
        task?(self.bounds.size, { [weak self] config in
            assert(Thread.isMainThread, "must call on main thread")
            guard let self = self, !self.shouldUpdate(identifier: identifier) else { return }
            self.image = config.image
            self.contentMode = config.contentMode
            self.alignment = config.alignment
            if config.error != nil {
                self.identifier = nil
            }
        })
    }

    private func shouldUpdate(identifier: String?) -> Bool {
        // SetImageTask图片下载还依赖于size，因此size改变也需要作为重置条件
        if let newIdentifier = identifier, let oldIdentifier = self.identifier, newIdentifier == oldIdentifier, oldSize == self.bounds.size {
            return false
        }
        return true
    }
}
