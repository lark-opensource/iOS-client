//
//  AttachmentRunBox.swift
//  LKRichView
//
//  Created by qihongye on 2020/1/12.
//

import UIKit
import Foundation

public protocol LKRichAttachment {
    var size: CGSize { get }
    var verticalAlign: VerticalAlign { get }
    var padding: Edges? { get }
    func getAscent(_ mode: WritingMode) -> CGFloat
    func createView() -> UIView
}

public final class LKRichAttachmentImp: LKRichAttachment {
    public typealias AscentProvider = (WritingMode) -> CGFloat

    public let size: CGSize

    public let verticalAlign: VerticalAlign

    public var padding: Edges?

    public func getAscent(_ mode: WritingMode) -> CGFloat {
        if let provider = ascentProvider {
            return provider(mode)
        }
        return 0
    }

    public func createView() -> UIView {
        return view
    }

    private let view: UIView
    private let ascentProvider: AscentProvider?

    // 兼容二进制
    public init(view: UIView, ascentProvider: AscentProvider? = nil) {
        self.view = view
        self.size = view.frame.size
        self.ascentProvider = ascentProvider
        self.verticalAlign = .middle
    }

    public init(view: UIView, ascentProvider: AscentProvider? = nil, verticalAlign: VerticalAlign = .middle) {
        self.view = view
        self.size = view.frame.size
        self.ascentProvider = ascentProvider
        self.verticalAlign = verticalAlign
    }
}

public final class LKAsyncRichAttachmentImp: LKRichAttachment {
    public typealias AscentProvider = (WritingMode) -> CGFloat
    public typealias ViewProvider = () -> UIView

    public let size: CGSize

    public let verticalAlign: VerticalAlign

    public var padding: Edges?

    public func getAscent(_ mode: WritingMode) -> CGFloat {
        if let provider = ascentProvider {
            return provider(mode)
        }
        return 0
    }

    private var view: UIView?
    public func createView() -> UIView {
        if let ui = self.view { return ui }
        let view = viewProvider()
        view.frame.size = self.size
        self.view = view
        return view
    }

    private let ascentProvider: AscentProvider?
    private let viewProvider: ViewProvider

    // 兼容二进制
    public init(size: CGSize, viewProvider: @escaping ViewProvider, ascentProvider: AscentProvider? = nil) {
        self.size = size
        self.viewProvider = viewProvider
        self.ascentProvider = ascentProvider
        self.verticalAlign = .middle
    }

    public init(size: CGSize, viewProvider: @escaping ViewProvider, ascentProvider: AscentProvider? = nil, verticalAlign: VerticalAlign = .middle) {
        self.size = size
        self.viewProvider = viewProvider
        self.ascentProvider = ascentProvider
        self.verticalAlign = verticalAlign
    }
}

final class AttachmentRunBox: RunBox {

    weak var ownerLineBox: LineBox?
    weak var ownerRenderObject: RenderObject?
    var writingMode: WritingMode {
        style.writingMode
    }
    var crossAxisAlign: VerticalAlign {
        style.verticalAlign
    }
    var isSplit: Bool = false

    var isLineBreak: Bool = false

    var debugOptions: ConfigOptions?

    // MARK: - origin

    var origin: CGPoint = .zero {
        didSet {
            ownerRenderObject?.boxOrigin = globalOrigin
        }
    }
    var baselineOrigin: CGPoint {
        get {
            CGPoint(x: origin.x, y: origin.y + descent + leading)
        }
        set {
            origin = CGPoint(x: newValue.x, y: newValue.y - descent - leading)
        }
    }
    var globalOrigin: CGPoint {
        let baseOrigin = ownerLineBox?.origin ?? .zero
        return CGPoint(x: origin.x + baseOrigin.x, y: origin.y + baseOrigin.y)
    }
    var globalBaselineOrigin: CGPoint {
        let origin = ownerLineBox?.baselineOrigin ?? .zero
        return CGPoint(x: baselineOrigin.x + origin.x, y: baselineOrigin.y + origin.y)
    }

    // MARK: - width

    var mainAxisWidth: CGFloat {
        contentMainAxisWidth
    }
    var contentMainAxisWidth: CGFloat {
        contentSize.mainAxisWidth(writingMode: writingMode)
    }
    var crossAxisWidth: CGFloat {
        contentCrossAxisWidth
    }
    var contentCrossAxisWidth: CGFloat {
        return contentSize.crossAxisWidth(writingMode: writingMode)
    }

    // MARK: - size

    lazy var ascent: CGFloat = {
        attachment.getAscent(writingMode)
    }()
    lazy var descent: CGFloat = {
        contentCrossAxisWidth - ascent
    }()
    let leading: CGFloat = 0
    private(set) var contentSize: CGSize = .zero
    let edges: UIEdgeInsets = .zero
    var size: CGSize {
        if writingMode == .horizontalTB {
            return CGSize(width: mainAxisWidth, height: crossAxisWidth)
        }
        return CGSize(width: crossAxisWidth, height: mainAxisWidth)
    }

    // MARK: - context

    var _renderContextLocation: Int
    let renderContextLength: Int = 1

    // MARK: - out of RunBox protocol

    private let style: RenderStyleOM
    private let attachment: LKRichAttachment
    private let avaliableMainAxisWidth: CGFloat
    private let avaliableCrossAxisWidth: CGFloat

    init(
        style: RenderStyleOM,
        attachment: LKRichAttachment,
        avaliableMainAxisWidth: CGFloat,
        avaliableCrossAxisWidth: CGFloat,
        renderContextLocation: Int
    ) {
        self.style = style
        self.attachment = attachment
        self.avaliableMainAxisWidth = avaliableMainAxisWidth
        self.avaliableCrossAxisWidth = avaliableCrossAxisWidth
        self._renderContextLocation = renderContextLocation
    }

    func layoutIfNeeded(context: LayoutContext?) {
        if contentSize != attachment.size {
            layout(context: context)
        }
    }

    func layout(context: LayoutContext?) {
        let maxLine = calcMaxLine(style: style, context: context)
        if maxLine == 0 {
            return
        }
        let width = style.storage.width
        let height = style.storage.height
        var size = computeSizeBy(
            writingMode: style.writingMode,
            main: avaliableMainAxisWidth,
            cross: avaliableCrossAxisWidth
        )

        var isWidthAuto = false
        var isHeightAuto = false

        if let value = width.value {
            switch width.type {
            case .point, .value:
                size.width = value
            case .auto, .inherit, .unset:
                isWidthAuto = true
            case .em:
                size.width = style.fontSize * value
            case .percent:
                size.width = value * size.width
            }
        } else {
            isWidthAuto = true
        }

        if let value = height.value {
            switch height.type {
            case .point, .value:
                size.height = value
            case .auto, .inherit, .unset:
                isHeightAuto = false
            case .em:
                size.height = style.fontSize * value
            case .percent:
                size.height = value * size.height
            }
        } else {
            isHeightAuto = true
        }

        let widthHeightRatio = attachment.size.width / attachment.size.height
        let heightWidthRatio = 1 / widthHeightRatio

        if !isWidthAuto && !isHeightAuto {
            contentSize = size
        } else if !isHeightAuto {
            size.width = size.height * widthHeightRatio
            contentSize = size
        } else if !isWidthAuto {
            size.height = size.width * heightWidthRatio
            contentSize = size
        } else {
            size.width = CGFloat(attachment.size.width)
            size.height = CGFloat(attachment.size.height)

            switch style.writingMode {
            case .horizontalTB:
                if size.width > avaliableMainAxisWidth {
                    size.width = avaliableMainAxisWidth
                    size.height = avaliableMainAxisWidth * heightWidthRatio
                }

                // min 优先于 max，优先的放在后面，可以覆盖前面的结果
                // 宽度是主轴，宽度优先
                if let value = style.maxHeight(avalidHeight: avaliableCrossAxisWidth), size.height > value {
                    size.height = value
                    size.width = value * widthHeightRatio
                }
                if let value = style.maxWidth(avalidWidth: avaliableMainAxisWidth), size.width > value {
                    size.width = value
                    size.height = value * heightWidthRatio
                }
                if let value = style.minHeight(avalidHeight: avaliableCrossAxisWidth), size.height < value {
                    size.height = value
                    size.width = value * widthHeightRatio
                }
                if let value = style.minWidth(avalidWidth: avaliableMainAxisWidth), size.width < value {
                    size.width = value
                    size.height = value * heightWidthRatio
                }
            case .verticalLR, .verticalRL:
                if size.height > avaliableMainAxisWidth {
                    size.height = avaliableMainAxisWidth
                    size.width = avaliableMainAxisWidth * widthHeightRatio
                }

                // min 优先于 max，优先的放在后面，可以覆盖前面的结果
                // 高度是主轴，高度优先
                if let value = style.maxWidth(avalidWidth: avaliableCrossAxisWidth), size.width > value {
                    size.width = value
                    size.height = value * heightWidthRatio
                }
                if let value = style.maxHeight(avalidHeight: avaliableMainAxisWidth), size.height > value {
                    size.height = value
                    size.width = value * widthHeightRatio
                }
                if let value = style.minWidth(avalidWidth: avaliableCrossAxisWidth), size.width < value {
                    size.width = value
                    size.height = value * heightWidthRatio
                }
                if let value = style.minHeight(avalidHeight: avaliableMainAxisWidth), size.height < value {
                    size.height = value
                    size.width = value * widthHeightRatio
                }
            }

            contentSize = size
        }
    }

    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult {
        return .disable(lhs: self, rhs: nil)
    }

    func draw(_ paintInfo: PaintInfo) {
        guard let renderObject = self.ownerRenderObject else { return }
        let attachment = self.attachment
        let renderObjectID = ObjectIdentifier(renderObject).hashValue
        runInMain {
            paintInfo.addSubView(renderObject: renderObject) {
                let view = attachment.createView()
                view.attachmentID = renderObjectID
                view.frame.size = self.contentSize
                return view
            }
        }
    }

    /// Attachment是一个整体，没办法进行拆分，所以truncate的逻辑比较简单：删除自身
    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat) {
        guard let ownerLineBox = ownerLineBox else { return }

        remainedMainAxisWidth += self.mainAxisWidth
        ownerLineBox.runBoxs.removeLast()
    }
}

private var attachmentIDKey: UInt8 = 0
private var isValidKey: UInt8 = 1
extension UIView {
    fileprivate(set) var attachmentID: Int? {
        get {
            return objc_getAssociatedObject(self, &attachmentIDKey) as? Int
        }
        set {
            objc_setAssociatedObject(self, &attachmentIDKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /// 标识View是否有效
    var isValid: Bool {
        // swiftlint:disable:next implicit_getter
        get {
            return objc_getAssociatedObject(self, &isValidKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &isValidKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
