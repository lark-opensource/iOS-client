//
//  EditTextViewAttachment.swift
//  LarkUIKit
//
//  Created by 李晨 on 2019/3/6.
//

import Foundation
import UIKit
import UniverseDesignColor

/// 提供预览图片的自定义 View
public protocol AttachmentPreviewableView: UIView {
    /// DragPreview & TextCanvas 层 显示的 image
    var previewImage: () -> UIImage? { get }
    var followSuperViewBackgroundColor: Bool { get }
}

public extension AttachmentPreviewableView {
    var previewImage: () -> UIImage? { { nil } }
    var followSuperViewBackgroundColor: Bool { false }
}

public final class CustomTextAttachment: NSTextAttachment {

    // 附件被选中时候的蒙层
    public var highlightColor: UIColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.4) {
        didSet {
            lazySelectedMask?.backgroundColor = self.highlightColor
        }
    }

    /// 父view 即textView的背景色
    public internal(set) var superViewBackgroundColor: UIColor? {
        didSet {
            if let preview = self.customView as? AttachmentPreviewableView, preview.followSuperViewBackgroundColor {
                self.customView.backgroundColor = superViewBackgroundColor
            }
        }
    }

    // attachment view 是否已经加载
    private var loaded: Bool = false

    // attachment wrapper view
    lazy var attachmentView: UIView = { [weak self] in
        let attachmentView = CustomTextAttachmentView()
        if let customView = self?.customView {
            attachmentView.addSubview(customView)
        }
        loaded = true
        return attachmentView
    }()

    // attachment 是否被选中
    var selected: Bool = false {
        didSet {
            guard needCustomSelectedMask && self.selected != oldValue else { return }
            if selected {
                self.attachmentView.addSubview(self.selectedMask)
            } else {
                self.selectedMask.removeFromSuperview()
            }
        }
    }

    /// 是否需要自定义选择遮罩
    var needCustomSelectedMask: Bool = true

    var selectedMask: UIView {
        if let mask = self.lazySelectedMask { return mask }
        let mask = UIView()
        mask.backgroundColor = self.highlightColor
        self.lazySelectedMask = mask
        return mask
    }
    var lazySelectedMask: UIView?

    // attachment 相对 textView 的布局
    var frame: CGRect? {
        didSet {
            if let frame = frame {
                self.attachmentView.frame = frame
                self.selectedMask.frame = attachmentView.bounds
                self.customView.frame = attachmentView.bounds
            }
        }
    }

    /// 自定义 view
    public private(set) var customView: UIView

    @available(*, deprecated, message: "customView should conform to AttachmentPreviewableView to support drag preview")
    public init(customView: UIView, bounds: CGRect) {
        self.customView = customView
        super.init(data: nil, ofType: nil)
        self.bounds = bounds
    }

    public init(customView: AttachmentPreviewableView, bounds: CGRect) {
        self.customView = customView
        super.init(data: nil, ofType: nil)
        self.bounds = bounds
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func image(
        forBounds imageBounds: CGRect,
        textContainer: NSTextContainer?,
        characterIndex charIndex: Int
    ) -> UIImage? {
        return (customView as? AttachmentPreviewableView)?.previewImage()
    }

    deinit {
        self.clearAttachmentView()
    }

    func clearAttachmentView() {
        guard loaded else { return }
        if Thread.isMainThread {
            self.attachmentView.removeFromSuperview()
        } else {
            let view = self.attachmentView
            DispatchQueue.main.async {
                view.removeFromSuperview()
            }
        }
    }

    // 把 view 生成对应的 layer 提升性能
    private func createViewLayer() -> UIImage? {
        var screenshot: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.customView.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return screenshot
    }
}

final class CustomTextAttachmentView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            let subviews = self.subviews
            for subview in subviews {
                let newPoint = self.convert(point, to: subview)
                if let view = subview.hitTest(newPoint, with: event) {
                    return view
                }
            }
        }
        return nil
    }
}
