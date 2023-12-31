//
//  WhiteboardToolBarElement.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/8.
//

import UIKit
import UniverseDesignColor
import SnapKit
import ByteViewCommon
import ByteViewUDColor
import UniverseDesignIcon
import WbLib

/// 白板工具栏的有关组件或者数据结构
protocol ToolBarActionDelegate: AnyObject {
    // 从未选中到选中状态, 需要同时切换到对应配置的笔画粗细和颜色
    func didChangeToolType(toolType: ActionToolType)
    func didChangeColor(color: ColorType)
    func didChangeBrushType(brushType: BrushType)
    func didChangeShapeType(shapeTool: ActionToolType)
    // 选中状态时的点击事件（用于隐藏工具栏，仅限有二级菜单的pen和shape）
    func didTapActionWithSelectedState(action: ActionToolType)
    func didTapUndo()
    func didTapRedo()
    func didTapMore()
    func didTapMove()
    func didTapEraser()
    func didTapExit()

    var hasMultiBoards: Bool { get }
}

extension ToolBarActionDelegate {
    func didChangeToolType(toolType: ActionToolType) {}
    func didChangeColor(color: ColorType) {}
    func didChangeBrushType(brushType: BrushType) {}
    func didChangeShapeType(shapeTool: ActionToolType) {}
    func didTapActionWithSelectedState(action: ActionToolType) {}
    func didTapUndo() {}
    func didTapRedo() {}
    func didTapMore() {}
    func didTapMove() {}
    func didTapEraser() {}
    func didTapExit() {}
}

public struct DefaultWhiteboardToolConfig {
    public let penBrushAndColor: BrushAndColorMemory
    public let highlighterBrushAndColor: BrushAndColorMemory
    public let shapeTypeAndColor: ShapeTypeAndColor

    public init(pen: BrushAndColorMemory,
                highlighter: BrushAndColorMemory,
                shape: ShapeTypeAndColor) {
        self.penBrushAndColor = pen
        self.highlighterBrushAndColor = highlighter
        self.shapeTypeAndColor = shape
    }
}

// 笔画粗细和颜色选择
public struct BrushAndColorMemory {
    public var color: ColorType = .black
    public var brushType: BrushType = .light

    public init(color: ColorType, brushType: BrushType) {
        self.color = color
        self.brushType = brushType
    }
}

public struct ShapeTypeAndColor {
    public var shape: ActionToolType = .rectangle
    public var color: ColorType = .black

    public init(shape: ActionToolType, color: ColorType) {
        self.shape = shape
        self.color = color
    }
}

public enum BrushType {
    case light
    case middle
    case bold

    var brushValue: UInt32 {
        switch self {
        case .light:
            return 3
        case .middle:
            return 6
        case .bold:
            return 9
        }
    }
}

// MARK: 工具栏类型
public enum ActionToolType {
    case move
    case pen
    case highlighter
    case rectangle
    case ellipse
    case triangle
    case line
    case arrow
    case eraser
    case shape
    case lightBrush
    case middleBrush
    case boldBrush
    case undo
    case redo
    case more
    case exit
    case save

    var detail: String {
        switch self {
        case .pen:
            return BundleI18n.Whiteboard.View_G_PenTool
        case .highlighter:
            return BundleI18n.Whiteboard.View_G_HighlighterTool
        case .shape:
            return BundleI18n.Whiteboard.View_G_ShapeTool
        case .eraser:
            return BundleI18n.Whiteboard.View_G_EraserTool
        case .undo:
            return BundleI18n.Whiteboard.View_G_UndoTool
        case .redo:
            return BundleI18n.Whiteboard.View_G_RedoTool
        case .more:
            return BundleI18n.Whiteboard.View_G_More
        case .exit:
            return BundleI18n.Whiteboard.View_MV_HideTools
        case .rectangle:
            return BundleI18n.Whiteboard.View_G_RectangleTool
        case .ellipse:
            return BundleI18n.Whiteboard.View_G_OvalTool
        case .triangle:
            return BundleI18n.Whiteboard.View_G_TriangleTool
        case .line:
            return BundleI18n.Whiteboard.View_G_StraightLineTool
        case .arrow:
            return BundleI18n.Whiteboard.View_G_ArrowTool
        case .save:
            return BundleI18n.Whiteboard.View_G_SaveAnnoWhiteBoard_Button
        default:
            return ""
        }
    }

    var trackOptionName: String {
        switch self {
        case .pen:
            return "pen"
        case .highlighter:
            return "highlighter"
        case .lightBrush:
            return "thin"
        case .middleBrush:
            return "medium"
        case .boldBrush:
            return "thick"
        case .ellipse:
            return "oval"
        case .triangle:
            return "triangle"
        case .rectangle:
            return "rectangle"
        case .line:
            return "line"
        case .arrow:
            return "arrow"
        default:
            return ""
        }
    }

    // 返回笔刷类型，用于笔刷选择类型保存
    var brushType: BrushType? {
        switch self {
        case .lightBrush:
            return .light
        case .middleBrush:
            return .middle
        case .boldBrush:
            return .bold
        default:
            return nil
        }
    }

    var wbTool: WbTool {
        switch self {
        case .move:
            return .Move
        case .pen:
            return .Pencil
        case .highlighter:
            return .Highlighter
        case .eraser:
            return .Eraser
        case .rectangle:
            return .Rect
        case .ellipse:
            return .Ellipse
        case .triangle:
            return .Triangle
        case .line:
            return .Line
        case .arrow:
            return .Arrow
        default:
            return .Move
        }
    }

    static func create(with wbTool: WbTool?) -> Self {
        guard let wbTool = wbTool else { return .move }
        switch wbTool {
        case .Move:
            return .move
        case .Pencil:
            return .pen
        case .Highlighter:
            return .highlighter
        case .Eraser:
            return .eraser
        case .Rect:
            return .rectangle
        case .Ellipse:
            return .ellipse
        case .Triangle:
            return .triangle
        case .Line:
            return .line
        case .Arrow:
            return .arrow
        default:
            return .move
        }
    }

    func getImage(size: CGSize, color: UIColor) -> UIImage {
        switch self {
        case .move:
            return UDIcon.getIconByKey(.vcMovetoolOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .pen:
            return UDIcon.getIconByKey(.vcPaintbrushOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .highlighter:
            return UDIcon.getIconByKey(.highlighterOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .rectangle:
            return UDIcon.getIconByKey(.rectangleOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .ellipse:
            return UDIcon.getIconByKey(.ellipseOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .triangle:
            return UDIcon.getIconByKey(.triangleOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .line:
            return UDIcon.getIconByKey(.ccmStraightLineOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .arrow:
            return UDIcon.getIconByKey(.arrowOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .eraser:
            return UDIcon.getIconByKey(.eraserOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .shape:
            return UDIcon.getIconByKey(.shapeOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .lightBrush:
            return UDIcon.getIconByKey(.brushLightOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .middleBrush:
            return UDIcon.getIconByKey(.brushMediumOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .boldBrush:
            return UDIcon.getIconByKey(.brushBoldOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .undo:
            return UDIcon.getIconByKey(.undoOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .redo:
            return UDIcon.getIconByKey(.redoOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .more:
            return UDIcon.getIconByKey(.moreOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .exit:
            return UDIcon.getIconByKey(.wikiSideFoldOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        case .save:
            return UDIcon.getIconByKey(.downloadOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
        }
    }
}

// MARK: 颜色按钮
protocol ColorButtonDelegate: AnyObject {
    func didTapColor(color: ColorType)
}

struct ColorItem {
    var type: ColorType
    var isSelected: Bool = false
}

public enum ColorType: String {
    case black
    case red
    case blue
    case yellow
    case green
    case purple

    var color: UIColor {
        switch self {
        case .red:
            return UIColor.ud.colorfulRed
        case .black:
            return UIColor.ud.N700
        case .blue:
            return UIColor.ud.colorfulBlue
        case .yellow:
            return UIColor.ud.colorfulYellow
        case .green:
            return UIColor.ud.colorfulGreen
        case .purple:
            return UIColor.ud.colorfulPurple
        }
    }
}

class ColorView: UIView {

    enum Layout {
        static var viewSize: CGSize { Display.phone ? CGSize(width: 50, height: 44) : CGSize(width: 32, height: 32) }
        static var imageSize: CGSize { Display.phone ? CGSize(width: 18, height: 18) : CGSize(width: 20, height: 20) }
        static var checkSize = CGSize(width: 16, height: 16)
        static var selectedSize: CGSize { Display.phone ? CGSize(width: 24, height: 24) : CGSize(width: 28, height: 28) }
    }

    private var selectedView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.selectedSize.width / 2
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private var checkImage: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.listCheckOutlined, iconColor: UIColor.ud.N00, size: Layout.checkSize)
        view.isHidden = true
        return view
    }()

    private lazy var colorImage: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.vc.fromColor(colorType.color, size: Layout.imageSize, cornerRadius: Layout.imageSize.width / 2)
        return view
    }()

    private lazy var colorButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(didTapColorButton), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    var colorType: ColorType {
        didSet {
            setImage()
        }
    }
    weak var delegate: ColorButtonDelegate?
    var lastButtonSize: CGSize?
    init(colorType: ColorType, isSelected: Bool = false, withButton: Bool = false) {
        self.colorType = colorType
        super.init(frame: .zero)
        self.backgroundColor = .clear
        snp.makeConstraints { maker in
            maker.size.equalTo(Layout.viewSize)
        }

        addSubview(colorImage)
        colorImage.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(Layout.imageSize)
        }

        addSubview(selectedView)
        selectedView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(Layout.selectedSize)
        }

        addSubview(checkImage)
        checkImage.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(Layout.checkSize)
        }

        if withButton {
            colorButton.isHidden = false
            addSubview(colorButton)
            colorButton.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }
    }

    convenience init(item: ColorItem) {
        self.init(colorType: item.type, isSelected: item.isSelected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setImage() {
        colorImage.image = UIImage.vc.fromColor(colorType.color, size: Layout.imageSize, cornerRadius: Layout.imageSize.width / 2)
    }

    func setSelectedState(isSelected: Bool) {
        selectedView.isHidden = !isSelected
        checkImage.isHidden = !isSelected
        colorButton.isSelected = isSelected
    }

    @objc func didTapColorButton() {
        guard !self.colorButton.isSelected else { return }
        delegate?.didTapColor(color: colorType)
    }

    func remakeSize(size: CGSize? = nil) {
        if size == nil {
            snp.remakeConstraints { make in
                make.size.equalTo(Layout.viewSize)
            }
            return
        }
        guard let size = size, size != lastButtonSize else { return }
        snp.remakeConstraints { make in
            make.size.equalTo(size)
        }
        lastButtonSize = size
    }
}

// MARK: 工具按钮（带选中激活背景色）
protocol StatusToolButtonDelegate: AnyObject {
    func didTapStatusToolButton(type: ActionToolType)
    func didTapActionWithSelectedState(action: ActionToolType)
}

struct StatusToolItem {
    var type: ActionToolType = .pen
    var isSelected: Bool = false
}

class StatusToolButton: UIButton {
    var imageSize: CGSize { (styleIsPhone || Display.phone) ? CGSize(width: 22, height: 22) : CGSize(width: 20, height: 20) }
    var buttonSize: CGSize { (styleIsPhone || Display.phone) ? CGSize(width: 56, height: 44) : CGSize(width: 32, height: 32)}
    var buttonBackgroundColor: UIColor { (styleIsPhone || Display.phone) ? UIColor.ud.vcTokenVCBtnFillSelected : UIColor.ud.B100 }
    var normalColor: UIColor { (styleIsPhone || Display.phone) ? UIColor.ud.iconN2 : UIColor.ud.iconN1 }
    var selectedColor: UIColor = UIColor.ud.primaryContentDefault
    var radio: CGFloat = 6

    var type: ActionToolType
    weak var delegate: StatusToolButtonDelegate?
    // customSize的优先级最高
    var customSize: CGSize?
    // 用于在ipad分屏情况下使用iPhone的布局大小
    let styleIsPhone: Bool
    // 用于控制是否在已选择状态下响应
    let isReactWithSelectedState: Bool

    init(type: ActionToolType, styleIsPhone: Bool, customSize: CGSize? = nil, userInteractionEnabled: Bool = true, isReactWithSelectedState: Bool = true) {
        self.type = type
        self.customSize = customSize
        self.styleIsPhone = styleIsPhone
        self.isReactWithSelectedState = isReactWithSelectedState
        super.init(frame: .zero)
        self.isUserInteractionEnabled = userInteractionEnabled
        let buttonSize = customSize ?? buttonSize
        let normalImage = type.getImage(size: imageSize, color: normalColor)
        self.setImage(normalImage, for: .normal)
        self.setImage(type.getImage(size: imageSize, color: selectedColor), for: .selected)
        self.setBackgroundImage(UIImage.vc.fromColor(buttonBackgroundColor, size: buttonSize, cornerRadius: radio), for: .selected)
        self.setImage(type.getImage(size: imageSize, color: selectedColor), for: .highlighted)
        self.setBackgroundImage(UIImage.vc.fromColor(buttonBackgroundColor, size: buttonSize, cornerRadius: radio), for: .highlighted)
        addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        snp.makeConstraints { maker in
            maker.size.equalTo(buttonSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTapButton() {
        if self.isSelected, isReactWithSelectedState {
            delegate?.didTapActionWithSelectedState(action: self.type)
            return
        }
        delegate?.didTapStatusToolButton(type: self.type)
    }

    func setSelectedState(isSelected: Bool) {
        self.isSelected = isSelected
    }

    func setTypeAndSelectedState(type: ActionToolType, isSelected: Bool = false) {
        DispatchQueue.main.async {
            self.type = type
            let normalImage = type.getImage(size: self.imageSize, color: self.normalColor)
            self.setImage(normalImage, for: .normal)
            self.setImage(type.getImage(size: self.imageSize, color: self.selectedColor), for: .selected)
            self.isSelected = isSelected
        }
    }

    func remakeSize(size: CGSize? = nil) {
        self.customSize = size
        let buttonSize = self.customSize ?? self.buttonSize
        let normalImage = type.getImage(size: self.imageSize, color: self.normalColor)
        self.setBackgroundImage(UIImage.vc.fromColor(buttonBackgroundColor, size: buttonSize, cornerRadius: radio), for: .selected)
        self.setImage(normalImage, for: .normal)
        self.setImage(type.getImage(size: imageSize, color: selectedColor), for: .selected)
        self.setBackgroundImage(UIImage.vc.fromColor(buttonBackgroundColor, size: buttonSize, cornerRadius: radio), for: .highlighted)
        self.setImage(type.getImage(size: imageSize, color: selectedColor), for: .highlighted)
        snp.remakeConstraints { maker in
            maker.size.equalTo(buttonSize)
        }
    }
}

// MARK: 手机一级菜单按钮
protocol PhoneActionToolDelegate: AnyObject {
    func didTapAction(action: ActionToolType)
    func didTapActionWithSelectedState(action: ActionToolType)
}

class PhoneActionToolView: UIView {

    enum Layout {
        static let ActionViewSize = CGSize(width: 62, height: 70)
        static let iconTopMargin: CGFloat = 17
        static let labelBottomMargin: CGFloat = 6
        static let iconSize = CGSize(width: 22, height: 22)
    }

    let type: ActionToolType
    weak var delegate: PhoneActionToolDelegate?
    var customSize: CGSize?
    private var viewSize: CGSize {
        customSize ?? Layout.ActionViewSize
    }

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        button.addInteraction(type: .lift)
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        return button
    }()

    lazy var actionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    init(type: ActionToolType) {
        self.type = type
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        snp.makeConstraints { (make) in
            make.size.equalTo(viewSize)
        }
        actionLabel.text = type.detail
        let normalImage = type.getImage(size: Layout.iconSize, color: UIColor.ud.iconN2)
        let selectedImage = type.getImage(size: Layout.iconSize, color: UIColor.ud.primaryContentDefault)
        let disableImage = type.getImage(size: Layout.iconSize, color: UIColor.ud.iconDisabled)
        actionButton.setImage(normalImage, for: .normal)
        actionButton.setImage(selectedImage, for: .selected)
        actionButton.setImage(disableImage, for: .disabled)
        actionButton.imageEdgeInsets = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
        addSubview(actionButton)
        actionButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        addSubview(actionLabel)
        actionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().inset(6)
        }
        if case .exit = type {
            addSubview(line)
            line.snp.makeConstraints { maker in
                maker.left.equalToSuperview()
                maker.top.equalToSuperview().inset(13)
                maker.width.equalTo(1)
                maker.height.equalTo(30)
            }
        }
    }

    func remakeSize() {
        snp.remakeConstraints { (make) in
            make.size.equalTo(viewSize)
        }
    }

    func setSelectedState(isSelected: Bool) {
        if isSelected {
            self.actionLabel.textColor = UIColor.ud.colorfulBlue
            self.actionButton.isSelected = true
        } else {
            self.actionLabel.textColor = UIColor.ud.N600
            self.actionButton.isSelected = false
        }
    }
    func setEnableStatus(_ enable: Bool) {
        self.actionButton.isEnabled = enable
    }

    @objc func didTap() {
        if self.actionButton.isSelected {
            if [.pen, .shape].contains(self.type) {
                delegate?.didTapActionWithSelectedState(action: self.type)
            }
        } else {
            delegate?.didTapAction(action: self.type)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            let convertedPoint = actionButton.convert(point, from: self)
            let resultView = actionButton.hitTest(convertedPoint, with: event) ?? self
            return resultView
        }
        return nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

// MARK: 工具栏返回按钮
protocol LeftArrowButtonDelegate: AnyObject {
    func didTapLeftArrow(type: ActionToolType)
}

class LeftArrowToolButton: UIButton {
    enum Layout {
        static let buttonSize = CGSize(width: 32, height: 44)
    }

    private var type: ActionToolType
    weak var delegate: LeftArrowButtonDelegate?

    init(toolType: ActionToolType) {
        self.type = toolType
        super.init(frame: .zero)
        backgroundColor = .clear
        setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20)), for: .normal)
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        snp.makeConstraints { maker in
            maker.size.equalTo(Layout.buttonSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTap() {
        delegate?.didTapLeftArrow(type: self.type)
    }

    func changeType(type: ActionToolType) {
        self.type = type
    }
}

// MARK: Ipad shape工具栏二级菜单button（用于橡皮擦选项）
enum EraserType {
    case clear // 对应橡皮擦，永久状态，剩余三个位点击事件，点击单次生效
    case clearMine
    case clearOther
    case clearAll

    var detail: String {
        switch self {
        case .clear:
            return BundleI18n.Whiteboard.View_G_EraseVerbTool
        case .clearMine:
            return BundleI18n.Whiteboard.View_G_EraseOwnContent
        case .clearOther:
            return BundleI18n.Whiteboard.View_G_EraseOthersContent
        case .clearAll:
            return BundleI18n.Whiteboard.View_G_EraseAll
        }
    }

    var trackEraserName: String {
        switch self {
        case .clear:
            return "clear_drawing"
        case .clearAll:
            return "clear_all_drawings"
        case .clearMine:
            return "clear_my_drawings"
        case .clearOther:
            return "clear_others_drawings"
        }
    }

    func getImage(size: CGSize, color: UIColor) -> UIImage {
        return UDIcon.getIconByKey(.listCheckBoldOutlined, renderingMode: .alwaysOriginal, iconColor: color, size: size)
    }
}

protocol EraserButtonDelegate: AnyObject {
    func didTapEraserButton(type: EraserType)
    func didTapEraserButtonWithSelectedState(type: EraserType)
}

class BackColorAndArrowView: UIView {
    enum Layout {
        static let arrowSize = CGSize(width: 12, height: 12)
        static let viewSize = CGSize(width: 180, height: 42)
    }

    let type: EraserType
    weak var delegate: EraserButtonDelegate?

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
        button.setBackgroundColor(.clear, for: .normal)
        button.setBackgroundColor(.ud.fillHover, for: .highlighted)
        button.clipsToBounds = true
        button.layer.cornerRadius = 4.0
        return button
    }()

    lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = type.getImage(size: Layout.arrowSize, color: UIColor.ud.primaryContentDefault)
        view.isHidden = true
        return view
    }()

    lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.text = type.detail
        return label
    }()

    init(type: EraserType) {
        self.type = type
        super.init(frame: .zero)
        snp.makeConstraints { maker in
            maker.size.equalTo(Layout.viewSize)
        }
        addSubview(actionButton)
        actionButton.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(3)
            maker.top.bottom.equalToSuperview().inset(1)
        }
        addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { maker in
            maker.right.equalToSuperview().inset(11)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGSize(width: 12, height: 12))
        }
        addSubview(detailLabel)
        detailLabel.snp.makeConstraints { maker in
            maker.left.equalToSuperview().inset(11)
            maker.right.lessThanOrEqualTo(arrowImageView.snp.left).offset(-8)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectedState(isSelected: Bool) {
        if isSelected {
            self.arrowImageView.isHidden = false
            detailLabel.textColor = UIColor.ud.primaryContentDefault
            actionButton.isUserInteractionEnabled = false
        } else {
            self.arrowImageView.isHidden = true
            detailLabel.textColor = UIColor.ud.textTitle
            actionButton.isUserInteractionEnabled = true
        }
    }

    @objc func didTapAction() {
        guard !actionButton.isSelected else {
            delegate?.didTapEraserButtonWithSelectedState(type: self.type)
            return
        }
        delegate?.didTapEraserButton(type: self.type)
    }
}
