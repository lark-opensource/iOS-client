//
//  WhiteboardPhoneToolBar.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/8.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

internal extension UIView {
    var isPhoneLandscape: Bool {
        return !isPhonePortrait
    }

    var isPhonePortrait: Bool {
        return Display.phone && self.traitCollection.horizontalSizeClass == .compact && self.traitCollection.verticalSizeClass == .regular
    }

    var orientation: UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            return self.window?.windowScene?.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
}

class WhiteboardPhoneToolBar: UIView {
    private let shouldShowMenuFirst: Bool
    // 一级工具栏按钮
    private let actionView: [PhoneActionToolView] = [
        PhoneActionToolView(type: .pen),
        PhoneActionToolView(type: .shape),
        PhoneActionToolView(type: .eraser),
        PhoneActionToolView(type: .undo),
        PhoneActionToolView(type: .more),
        PhoneActionToolView(type: .exit)
    ]

    private let colorButtons: [ColorView] = [
        ColorView(colorType: .black, withButton: true),
        ColorView(colorType: .red, withButton: true),
        ColorView(colorType: .yellow, withButton: true),
        ColorView(colorType: .green, withButton: true),
        ColorView(colorType: .blue, withButton: true),
        ColorView(colorType: .purple, withButton: true)
    ]

    // 笔和荧光笔
    private let penStackElement: [StatusToolButton] = [
        StatusToolButton(type: .pen, styleIsPhone: true, isReactWithSelectedState: false),
        StatusToolButton(type: .highlighter, styleIsPhone: true, isReactWithSelectedState: false)
    ]

    private let shapeStackElement: [StatusToolButton] = [
        StatusToolButton(type: .rectangle, styleIsPhone: true),
        StatusToolButton(type: .ellipse, styleIsPhone: true),
        StatusToolButton(type: .triangle, styleIsPhone: true),
        StatusToolButton(type: .line, styleIsPhone: true),
        StatusToolButton(type: .arrow, styleIsPhone: true)
    ]

    // 笔刷工具
    private let brushElements: [StatusToolButton] = [
        StatusToolButton(type: .lightBrush, styleIsPhone: true),
        StatusToolButton(type: .middleBrush, styleIsPhone: true),
        StatusToolButton(type: .boldBrush, styleIsPhone: true)
    ]

    private enum Layout {
        /// 工具栏高度
        static let toolBarHeight: CGFloat = 70.0
        /// 二级工具栏高度
        static let detailToolBarHeight: CGFloat = 52.0
        /// 底部工具栏顶部的分隔线高度
        static let saperateLintHeight: CGFloat = 0.5
        /// 底部工具栏与二级工具栏的间距
        static let toolBarHorizontalSpacing: CGFloat = 12.0
    }

    /// 工具栏
    private let bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    // 一级工具栏按钮容器
    private let toolBarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private let toolBarLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    /// 二级工具栏，多种二级菜单共用
    private let topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 3
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    // 二级工具栏容器
    private let detailToolContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    private let splitLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        line.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 1, height: 24))
        }
        return line
    }()

    // 笔刷选择按钮
    private lazy var selectBrushButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.setImage(UDIcon.getIconByKey(.brushLightOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: CGSize(width: 22, height: 22)), for: .normal)
        button.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 56, height: 44))
        }
        button.addTarget(self, action: #selector(didTapSelectBrushButton), for: .touchUpInside)
        return button
    }()

    private lazy var selectColorButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.setImage(UIImage.vc.fromColor(.ud.N900, size: CGSize(width: 18, height: 18), cornerRadius: 9), for: .normal)
        button.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 56, height: 44))
        }
        button.addTarget(self, action: #selector(didTapSelectColorButton), for: .touchUpInside)
        return button
    }()

    /// 笔画粗细和颜色菜单
    private var brushOrColorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 3
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    // 笔刷或者颜色选择盘容器
    private var brushOrColorContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        view.layer.borderWidth = 1
        view.isHidden = true
        return view
    }()

    // 笔刷或者颜色选择盘的返回按钮
    private lazy var leftArrow: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.setImage(UDIcon.getIconByKey(.leftOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20)), for: .normal)
        button.addTarget(self, action: #selector(didTapLeftArrow), for: .touchUpInside)
        button.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 32, height: 44))
        }
        return button
    }()

    private let brushOrColorSplitLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        line.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 1, height: 24))
        }
        return line
    }()

    // 当前一级菜单的选择
    private var currentActionToolType: ActionToolType?
    // 当前pen的具体选项（包括笔和荧光笔）
    private var currentPenType: ActionToolType = .pen
    // 当前具体工具的（笔刷或形状）和颜色配置
    var currentPenToolConfig: BrushAndColorMemory
    var currentHighlighterToolConfig: BrushAndColorMemory
    var currentShapeToolConfig: ShapeTypeAndColor
    let whiteboardId: Int64

    weak var delegate: ToolBarActionDelegate?

    init(shouldShowMenuFirst: Bool, toolConfig: DefaultWhiteboardToolConfig, whiteboardId: Int64) {
        self.shouldShowMenuFirst = shouldShowMenuFirst
        self.currentPenToolConfig = toolConfig.penBrushAndColor
        self.currentHighlighterToolConfig = toolConfig.highlighterBrushAndColor
        self.currentShapeToolConfig = toolConfig.shapeTypeAndColor
        self.whiteboardId = whiteboardId
        super.init(frame: .zero)
        configDelegate()
        layoutUI()
        if shouldShowMenuFirst {
            configBar(tool: .pen)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        remakeConstraintsOnOrientationChange()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = Float(self.frame.width / 6)
        // 由于ipad 分屏时以及小屏手机可能存在宽度较小问题，因此需要根据宽度自适应工具栏工具的宽度
        if size < 62.0, actionView.first?.customSize == nil {
            for view in actionView {
                view.customSize = CGSize(width: CGFloat(floor(size)), height: 70)
                view.remakeSize()
            }
        } else if size >= 62.0, actionView.first?.customSize != nil {
            for view in actionView {
                view.customSize = nil
                view.remakeSize()
            }
        }
        let shapeSize = Float((self.frame.width - 27) / 6)
        if shapeSize < 56.0, shapeStackElement.first?.customSize == nil {
            for shape in shapeStackElement {
                shape.remakeSize(size: CGSize(width: CGFloat(floor(shapeSize)), height: 44))
            }
        } else if shapeSize >= 56.0, shapeStackElement.first?.customSize != nil {
            for shape in shapeStackElement {
                shape.remakeSize(size: nil)
            }
        }
        let colorSize = Float((self.frame.width - 13 - 43 - 4 - 15) / 6)
        if colorSize < 50 {
            for button in colorButtons {
                let customSize = CGSize(width: CGFloat(floor(colorSize)), height: 44)
                button.remakeSize(size: customSize)
            }
        } else if colorSize >= 50 {
            for button in colorButtons {
                button.remakeSize(size: CGSize(width: 50, height: 44))
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configDelegate() {
        for view in actionView {
            view.delegate = self
        }
        for view in penStackElement {
            view.delegate = self
        }
        for view in shapeStackElement {
            view.delegate = self
        }
        for view in brushElements {
            view.delegate = self
        }
        for button in colorButtons {
            button.delegate = self
        }
    }

    private func layoutUI() {
        backgroundColor = .clear
        addSubview(toolBarContainerView)
        toolBarContainerView.snp.makeConstraints { maker in
            let spacing = isPhoneLandscape ? 0 : Layout.toolBarHorizontalSpacing
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalToSuperview().offset(Layout.detailToolBarHeight + spacing)
        }
        toolBarContainerView.addSubview(toolBarLine)
        toolBarLine.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalToSuperview().offset(-(Layout.saperateLintHeight / 2.0))
            maker.height.equalTo(Layout.saperateLintHeight)
        }
        for view in actionView {
            view.removeFromSuperview()
            bottomStackView.addArrangedSubview(view)
        }
        toolBarContainerView.addSubview(bottomStackView)
        bottomStackView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview()
            maker.right.lessThanOrEqualToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.lessThanOrEqualTo(safeAreaLayoutGuide)
            maker.height.equalTo(Layout.toolBarHeight)
        }
        addSubview(detailToolContainerView)
        detailToolContainerView.snp.makeConstraints { maker in
            maker.centerX.top.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview()
            maker.right.lessThanOrEqualToSuperview()
            maker.height.equalTo(Layout.detailToolBarHeight)
        }
        detailToolContainerView.addSubview(topStackView)
        topStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(4)
        }
        addSubview(brushOrColorContainerView)
        brushOrColorContainerView.snp.makeConstraints { maker in
            maker.centerX.top.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview()
            maker.right.lessThanOrEqualToSuperview()
            maker.height.equalTo(Layout.detailToolBarHeight)
        }
        brushOrColorContainerView.addSubview(brushOrColorStackView)
        brushOrColorStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(4)
        }
    }

    private func remakeConstraintsOnOrientationChange() {
        toolBarContainerView.snp.remakeConstraints {
            let spacing = isPhoneLandscape ? 0 : Layout.toolBarHorizontalSpacing
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(Layout.detailToolBarHeight + spacing)
        }
    }

    // 上一级二级菜单需要实时展示颜色选择盘或者笔刷选择盘选择的选项，因此每次选完后要重置按钮样式
    private func configSelectBrushButtonImage(tool: ActionToolType) {
        if tool == .pen {
            selectBrushButton.setImage(self.getBrushImage(brush: currentPenToolConfig.brushType), for: .normal)
        } else if tool == .highlighter {
            selectBrushButton.setImage(self.getBrushImage(brush: currentHighlighterToolConfig.brushType), for: .normal)
        }
    }

    private func configSelectColorButtonImage(tool: ActionToolType) {
        switch tool {
        case .pen:
            let image = getColorImage(color: currentPenToolConfig.color)
            selectColorButton.setImage(image, for: .normal)
        case .highlighter:
            let image = getColorImage(color: currentHighlighterToolConfig.color)
            selectColorButton.setImage(image, for: .normal)
        case .shape:
            let image = getColorImage(color: currentShapeToolConfig.color)
            selectColorButton.setImage(image, for: .normal)
        default:
            break
        }
    }

    private func getColorImage(color: ColorType) -> UIImage? {
        UIImage.vc.fromColor(color.color, size: CGSize(width: 18, height: 18), cornerRadius: 9)
    }

    private func getBrushImage(brush: BrushType) -> UIImage {
        switch brush {
        case .light:
            return UDIcon.getIconByKey(.brushLightOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: CGSize(width: 22, height: 22))
        case .bold:
            return UDIcon.getIconByKey(.brushBoldOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: CGSize(width: 22, height: 22))
        case .middle:
            return UDIcon.getIconByKey(.brushMediumOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: CGSize(width: 22, height: 22))
        }
    }

    // 出现在ipad分屏的情况下
    // 外面来控制整个phontToolBar的hidden状态，内部根据配置来做具体配置以及显隐设置
    func configToolBarWithCurentSettings(pen: BrushAndColorMemory, highlighter: BrushAndColorMemory, shape: ShapeTypeAndColor, currentTool: ActionToolType) {
        self.currentPenToolConfig = pen
        self.currentHighlighterToolConfig = highlighter
        self.currentShapeToolConfig = shape
        self.currentActionToolType = currentTool
        // 当前处于移动画笔状态，也就是不激活状态，一级菜单全部置灰，无二级菜单。
        if currentTool == .move {
            actionView.forEach {
                $0.setSelectedState(isSelected: false)
            }
            self.detailToolContainerView.isHidden = true
            self.brushOrColorContainerView.isHidden = true
        } else if [.pen, .highlighter, .shape].contains(currentTool) {
            if [.pen, .highlighter].contains(currentTool) {
                currentPenType = currentTool
                configBar(tool: .pen)
            } else {
                configBar(tool: .shape)
            }
        }
    }

    // 根据一级菜单具体工具项，配置整个工具栏，包括一二级菜单
    func configBar(tool: ActionToolType? = nil, detailTool: ActionToolType? = nil) {
        // 只有笔，形状和橡皮擦有常驻的选中状态，其他的为单次点击事件
        if let toolStyle = tool, [.pen, .shape, .eraser].contains(toolStyle) {
            actionView.forEach {
                $0.setSelectedState(isSelected: $0.type == tool)
            }
            switch toolStyle {
            case .pen:
                topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                for view in penStackElement {
                    view.removeFromSuperview()
                    view.setSelectedState(isSelected: view.type == currentPenType)
                    topStackView.addArrangedSubview(view)
                }
                splitLine.removeFromSuperview()
                selectBrushButton.removeFromSuperview()
                selectColorButton.removeFromSuperview()
                configSelectBrushButtonImage(tool: currentPenType)
                configSelectColorButtonImage(tool: currentPenType)
                topStackView.addArrangedSubview(splitLine)
                topStackView.addArrangedSubview(selectBrushButton)
                topStackView.addArrangedSubview(selectColorButton)
                detailToolContainerView.snp.remakeConstraints { maker in
                    maker.centerX.top.equalToSuperview()
                    maker.left.greaterThanOrEqualToSuperview()
                    maker.right.lessThanOrEqualToSuperview()
                    maker.height.equalTo(Layout.detailToolBarHeight)
                }
                detailToolContainerView.isHidden = false
            case .shape:
                topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                for view in shapeStackElement {
                    view.removeFromSuperview()
                    view.setSelectedState(isSelected: view.type == currentShapeToolConfig.shape )
                    topStackView.addArrangedSubview(view)
                }
                splitLine.removeFromSuperview()
                selectColorButton.removeFromSuperview()
                configSelectColorButtonImage(tool: .shape)
                topStackView.addArrangedSubview(splitLine)
                topStackView.addArrangedSubview(selectColorButton)
                detailToolContainerView.snp.remakeConstraints { maker in
                    maker.centerX.top.equalToSuperview()
                    maker.left.greaterThanOrEqualToSuperview()
                    maker.right.lessThanOrEqualToSuperview()
                    maker.height.equalTo(Layout.detailToolBarHeight)
                }
                detailToolContainerView.isHidden = false
            default:
                break
            }
        }
        self.currentActionToolType = tool
    }

    // 更新undo按钮的状态（置灰与否）
    func setUndoButtonState(canUndo: Bool) {
        if let view = actionView.first(where: { $0.type == .undo}) {
            view.setEnableStatus(canUndo)
        }
    }

    func setConfigToClient(action: ActionToolType) {
        switch action {
        case .pen:
            delegate?.didChangeToolType(toolType: .pen)
            delegate?.didChangeColor(color: currentPenToolConfig.color)
            delegate?.didChangeBrushType(brushType: currentPenToolConfig.brushType)
        case .highlighter:
            delegate?.didChangeToolType(toolType: .highlighter)
            delegate?.didChangeColor(color: currentHighlighterToolConfig.color)
            delegate?.didChangeBrushType(brushType: currentHighlighterToolConfig.brushType)
        case .shape:
            delegate?.didChangeToolType(toolType: currentShapeToolConfig.shape)
            // shape 固定为light
            delegate?.didChangeBrushType(brushType: .light)
            delegate?.didChangeColor(color: currentShapeToolConfig.color)
        default:
            break
        }
    }

    func resetDetailToolContainerViewBoardColor() {
        detailToolContainerView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
    }
}

extension WhiteboardPhoneToolBar: PhoneActionToolDelegate, StatusToolButtonDelegate, ColorButtonDelegate {
    func didTapAction(action: ActionToolType) {
        switch action {
        case .pen, .shape:
            detailToolContainerView.isHidden = true
            brushOrColorContainerView.isHidden = true
            configBar(tool: action)
            if action == .pen, currentPenType == .pen {
                setConfigToClient(action: .pen)
                WhiteboardTracks.trackBoardClick(.draw, whiteboardId: whiteboardId)
            } else if action == .pen, currentPenType == .highlighter {
                setConfigToClient(action: .highlighter)
                WhiteboardTracks.trackBoardClick(.draw, whiteboardId: whiteboardId)
            } else if action == .shape {
                setConfigToClient(action: .shape)
                WhiteboardTracks.trackBoardClick(.shape, whiteboardId: whiteboardId)
            }
        case .eraser:
            detailToolContainerView.isHidden = true
            brushOrColorContainerView.isHidden = true
            configBar(tool: action)
            WhiteboardTracks.trackBoardClick(.clear, whiteboardId: whiteboardId)
            delegate?.didTapEraser()
        case .undo:
            WhiteboardTracks.trackBoardClick(.undo, whiteboardId: whiteboardId)
            delegate?.didTapUndo()
        case .more:
            delegate?.didTapMore()
        case .exit:
            delegate?.didTapExit()
        default: return
        }
    }

    func didTapActionWithSelectedState(action: ActionToolType) {
        if [.pen, .shape].contains(action) {
            if detailToolContainerView.isHidden && brushOrColorContainerView.isHidden {
                detailToolContainerView.isHidden = false
            } else {
                brushOrColorContainerView.isHidden = true
                detailToolContainerView.isHidden = true
            }
            delegate?.didTapActionWithSelectedState(action: action)
        }
    }

    func didTapColor(color: ColorType) {
        for button in colorButtons {
            button.setSelectedState(isSelected: button.colorType == color)
        }
        if currentActionToolType == .pen {
            if currentPenType == .pen {
                currentPenToolConfig.color = color
                configSelectColorButtonImage(tool: .pen)
            } else if currentPenType == .highlighter {
                currentHighlighterToolConfig.color = color
                configSelectColorButtonImage(tool: .highlighter)
            }
        } else if currentActionToolType == .shape {
            currentShapeToolConfig.color = color
            configSelectColorButtonImage(tool: .shape)
        }
        WhiteboardTracks.trackBoardClick(.colorSelection(color: color), whiteboardId: whiteboardId)
        delegate?.didChangeColor(color: color)
    }

    func didTapStatusToolButton(type: ActionToolType) {
        if currentActionToolType == .pen {
            // 更改画笔种类要更改颜色和笔画粗细的配置
            if [.pen, .highlighter].contains(type) {
                for view in penStackElement {
                    view.setSelectedState(isSelected: view.type == type)
                }
                currentPenType = type
                if type == .pen {
                    setConfigToClient(action: .pen)
                } else if type == .highlighter {
                    setConfigToClient(action: .highlighter)
                }
                configSelectBrushButtonImage(tool: currentPenType)
                configSelectColorButtonImage(tool: currentPenType)
                WhiteboardTracks.trackBoardClick(.drawSelection(penOrBrush: type), whiteboardId: whiteboardId)
            } else if [.lightBrush, .middleBrush, .boldBrush].contains(type) {
                for view in brushElements {
                    view.setSelectedState(isSelected: view.type == type)
                }
                if let brushType = type.brushType {
                    if currentPenType == .pen {
                        currentPenToolConfig.brushType = brushType
                    } else if currentPenType == .highlighter {
                        currentHighlighterToolConfig.brushType = brushType
                    }
                    configSelectBrushButtonImage(tool: currentPenType)
                    delegate?.didChangeBrushType(brushType: brushType)
                }
                WhiteboardTracks.trackBoardClick(.drawSelection(penOrBrush: type), whiteboardId: whiteboardId)
            }
        } else if currentActionToolType == .shape {
            for view in shapeStackElement {
                view.setSelectedState(isSelected: view.type == type)
            }
            currentShapeToolConfig.shape = type
            delegate?.didChangeShapeType(shapeTool: type)
            WhiteboardTracks.trackBoardClick(.shapeSelection(shape: type), whiteboardId: whiteboardId)
        }
    }

    @objc func didTapSelectBrushButton() {
        var currentBrushType: BrushType = .light
        if currentActionToolType == .pen {
            currentBrushType = currentPenType == .pen ? currentPenToolConfig.brushType : currentHighlighterToolConfig.brushType
        } else {
            return
        }
        for brush in brushElements {
            brush.setSelectedState(isSelected: brush.type.brushType == currentBrushType)
        }
        brushOrColorContainerView.isHidden = true
        brushOrColorStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        brushOrColorSplitLine.removeFromSuperview()
        leftArrow.removeFromSuperview()
        brushOrColorStackView.addArrangedSubview(leftArrow)
        brushOrColorStackView.addArrangedSubview(brushOrColorSplitLine)
        for view in brushElements {
            view.removeFromSuperview()
            brushOrColorStackView.addArrangedSubview(view)
        }
        self.layoutIfNeeded()
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.detailToolContainerView.isHidden = true
            self.layoutIfNeeded()
        }) { [weak self] _ in
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, animations: {
                self?.brushOrColorContainerView.isHidden = false
            })
        }
    }

    @objc func didTapSelectColorButton() {
        var setColor: ColorType = .black
        if currentActionToolType == .pen {
            setColor = currentPenType == .pen ? currentPenToolConfig.color : currentHighlighterToolConfig.color
        } else if currentActionToolType == .shape {
            setColor = currentShapeToolConfig.color
        } else {
            return
        }
        for color in colorButtons {
            color.setSelectedState(isSelected: color.colorType == setColor)
        }
        brushOrColorContainerView.isHidden = true
        brushOrColorStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        brushOrColorSplitLine.removeFromSuperview()
        leftArrow.removeFromSuperview()
        brushOrColorStackView.addArrangedSubview(leftArrow)
        brushOrColorStackView.addArrangedSubview(brushOrColorSplitLine)
        for view in colorButtons {
            view.removeFromSuperview()
            brushOrColorStackView.addArrangedSubview(view)
        }
        self.layoutIfNeeded()
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.detailToolContainerView.isHidden = true
            self.layoutIfNeeded()
        }) { [weak self] _ in
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, animations: {
                self?.brushOrColorContainerView.isHidden = false
            })
        }
    }

    @objc func didTapLeftArrow() {
        detailToolContainerView.isHidden = true
        self.layoutIfNeeded()
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.brushOrColorContainerView.isHidden = true
            self.layoutIfNeeded()
        }) { [weak self] _ in
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, animations: {
                self?.detailToolContainerView.isHidden = false
            })
        }
    }
}
