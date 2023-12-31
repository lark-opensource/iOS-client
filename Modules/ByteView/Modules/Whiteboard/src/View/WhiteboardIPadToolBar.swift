//
//  WhiteboardIPadToolBar.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/9.
//

import Foundation
import UniverseDesignColor
import ByteViewCommon
import UniverseDesignIcon

// MARK: ipad工具栏一级菜单
class WhiteboardIPadToolBar: UIView {

    weak var delegate: ToolBarActionDelegate?
    // 默认处于move状态
    var currentTool: ActionToolType = .move
    let whiteboardId: Int64
    let isSaveEnabled: Bool

    // 可选中一级菜单toolButton
    private lazy var toolBarButton: [StatusToolButton] = {
        var toolBarButton = [
            StatusToolButton(type: .move, styleIsPhone: false, customSize: CGSize(width: 36, height: 36)),
            StatusToolButton(type: .pen, styleIsPhone: false, customSize: CGSize(width: 36, height: 36)),
            StatusToolButton(type: .highlighter, styleIsPhone: false, customSize: CGSize(width: 36, height: 36)),
            StatusToolButton(type: .shape, styleIsPhone: false, customSize: CGSize(width: 36, height: 36)),
            StatusToolButton(type: .eraser, styleIsPhone: false, customSize: CGSize(width: 36, height: 36)),
            saveButton
        ]
        return toolBarButton
    }()

    // 条件控制是否响应点击事件的工具按钮，undo和redo
    private lazy var undoButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        let disabeImage = UDIcon.getIconByKey(.undoOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 20, height: 20))
        let normalImage = UDIcon.getIconByKey(.undoOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
        button.setImage(disabeImage, for: .disabled)
        button.setImage(normalImage, for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(didTapUndo), for: .touchUpInside)
        button.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 36, height: 36))
        }
        return button
    }()

    private lazy var redoButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        let disabeImage = UDIcon.getIconByKey(.redoOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 20, height: 20))
        let normalImage = UDIcon.getIconByKey(.redoOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
        button.setImage(disabeImage, for: .disabled)
        button.setImage(normalImage, for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(didTapRedo), for: .touchUpInside)
        button.snp.makeConstraints { maker in
            maker.size.equalTo(CGSize(width: 36, height: 36))
        }
        return button
    }()

    private(set) lazy var saveButton: StatusToolButton = {
        let saveButton = StatusToolButton(type: .save, styleIsPhone: false, customSize: CGSize(width: 36, height: 36))
        saveButton.isHidden = !isSaveEnabled
        return saveButton
    }()

    // 容纳一级菜单工具按钮的stackView
    private var toolBarStackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.spacing = 8
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .equalSpacing
        return view
    }()

    init(isSharer: Bool, whiteboardId: Int64, isSaveEnabled: Bool) {
        self.whiteboardId = whiteboardId
        self.isSaveEnabled = isSaveEnabled
        super.init(frame: .zero)
        currentTool = isSharer ? .pen : .move
        configDelegate()
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 10
        layer.masksToBounds = true
        layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        layer.borderWidth = 1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowColor = UIColor.ud.vcTokenVCShadowSm.cgColor

        addToolBarSubView()
        configCurrentTool()
        addSubview(toolBarStackView)
        toolBarStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(12)
        }
    }

    // 配置一级菜单的button
    private func addToolBarSubView() {
        for view in toolBarButton {
            if view === saveButton {
                toolBarStackView.addArrangedSubview(undoButton)
                toolBarStackView.addArrangedSubview(redoButton)
            }
            toolBarStackView.addArrangedSubview(view)
        }
    }

    // 设置一级菜单button的响应delegate，用于处理菜单的点击事件
    private func configDelegate() {
        for view in toolBarButton {
            view.delegate = self
        }
    }

    // 设置一级菜单的当前选中状态
    func configCurrentTool(tool: ActionToolType? = nil) {
        if let tool = tool {
            currentTool = tool
        }
        for button in toolBarButton {
            button.setSelectedState(isSelected: button.type == currentTool)
        }
    }

    // 设置菜单点击事件后菜单选中状态的变更
    private func configBarAfterTap(tapTool: ActionToolType) {
        guard currentTool != tapTool else {
            delegate?.didTapActionWithSelectedState(action: tapTool)
            return
        }
        delegate?.didChangeToolType(toolType: tapTool)
        if tapTool == .save, delegate?.hasMultiBoards != true {
            // 单页保存时不展示选中态
            return
        }
        currentTool = tapTool
        configCurrentTool()
    }

    func setUndoButtonState(canUndo: Bool) {
        undoButton.isEnabled = canUndo
    }

    func setRedoButtonState(canRedo: Bool) {
        redoButton.isEnabled = canRedo
    }
}


extension WhiteboardIPadToolBar: StatusToolButtonDelegate {

    func didTapStatusToolButton(type: ActionToolType) {
        switch type {
        case .move:
            guard currentTool != .move else { return }
            currentTool = .move
            delegate?.didTapMove()
            configCurrentTool()
        case .pen, .highlighter, .shape, .save:
            if type == .pen {
                WhiteboardTracks.trackBoardClick(.drawSelection(penOrBrush: .pen), whiteboardId: whiteboardId)
            } else if type == .highlighter {
                WhiteboardTracks.trackBoardClick(.drawSelection(penOrBrush: .highlighter), whiteboardId: whiteboardId)
            } else if type == .shape {
                WhiteboardTracks.trackBoardClick(.shape, whiteboardId: whiteboardId)
            }
            configBarAfterTap(tapTool: type)
        case .eraser:
            guard currentTool != .eraser else { return }
            WhiteboardTracks.trackBoardClick(.clear, whiteboardId: whiteboardId)
            currentTool = .eraser
            delegate?.didTapEraser()
            configCurrentTool()
        default:
            return
        }
    }

    func didTapActionWithSelectedState(action: ActionToolType) {
        delegate?.didTapActionWithSelectedState(action: action)
    }

    @objc func didTapUndo() {
        WhiteboardTracks.trackBoardClick(.undo, whiteboardId: whiteboardId)
        delegate?.didTapUndo()
    }

    @objc func didTapRedo() {
        WhiteboardTracks.trackBoardClick(.redo, whiteboardId: whiteboardId)
        delegate?.didTapRedo()
    }
}

// MARK: ipad二级菜单（包括笔画笔刷和形状，带颜色选择）
enum ToolWithColorType {
    case shape
    case brush
    // 工具类型文案（画笔笔刷或者形状）
    var text: String {
        switch self {
        case .brush:
            return BundleI18n.Whiteboard.View_G_ThicknessTool
        case .shape:
            return BundleI18n.Whiteboard.View_G_ShapeTool
        }
    }
    // 颜色类型文案
    var colorText: String {
        switch self {
        case .brush:
            return BundleI18n.Whiteboard.View_G_PenColorTool
        case .shape:
            return BundleI18n.Whiteboard.View_G_ShapeColorTool
        }
    }
}

protocol ToolAndColorDelegate: AnyObject {
    // 切换工具或者切换工具颜色
    func didTapToolOrColor(tool: ActionToolType?, color: ColorType?)
}

class ToolAndColorHeadView: UICollectionReusableView {
    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.backgroundColor = .clear
        label.numberOfLines = 1
        return label
    }()

    private lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var shouldShowLine: Bool = true {
        didSet {
            if !shouldShowLine {
                line.isHidden = true
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        if shouldShowLine {
            addSubview(line)
            line.snp.makeConstraints { maker in
                maker.left.right.top.equalToSuperview()
                maker.height.equalTo(1)
            }
        }

        addSubview(detailLabel)
        detailLabel.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(11)
            let topMargin: CGFloat = shouldShowLine ? 8 : 9
            maker.top.equalToSuperview().inset(topMargin)
        }
    }

    func configHeadView(text: String, shouldShowLine: Bool = true) {
        DispatchQueue.main.async {
            self.detailLabel.text = text
            self.detailLabel.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview().inset(11)
                let topMargin: CGFloat = shouldShowLine ? 8 : 9
                maker.top.equalToSuperview().inset(topMargin)
            }
        }
    }
}

// pen或者shape二级菜单的颜色选择盘cell
class ColorCell: UICollectionViewCell {
    private var colorView: ColorView = {
        let button = ColorView(colorType: .black)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.contentView.addSubview(colorView)
        colorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(item: ColorItem) {
        self.colorView.colorType = item.type
        self.colorView.setSelectedState(isSelected: item.isSelected)
    }
}
// pen或者shape二级菜单的工具选择盘cell
class ToolCell: UICollectionViewCell {
    private var toolButton: StatusToolButton = {
        let button = StatusToolButton(type: .pen, styleIsPhone: false, userInteractionEnabled: false)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(toolButton)
        toolButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(item: StatusToolItem) {
        toolButton.setTypeAndSelectedState(type: item.type, isSelected: item.isSelected)
    }
}

class ToolAndColorView: UIView {

    enum Layout {
        static let colorSize = CGSize(width: 32, height: 32)
    }

    // 笔画粗细
    private lazy var brushItems: [StatusToolItem] = [StatusToolItem(type: .lightBrush), StatusToolItem(type: .middleBrush), StatusToolItem(type: .boldBrush)]

    // 笔画颜色或者形状颜色
    private lazy var colorItems: [ColorItem] = [ColorItem(type: .black), ColorItem(type: .red), ColorItem(type: .blue), ColorItem(type: .yellow), ColorItem(type: .green), ColorItem(type: .purple)]

    // 形状
    private lazy var shapeItems: [StatusToolItem] = [StatusToolItem(type: .rectangle), StatusToolItem(type: .ellipse), StatusToolItem(type: .triangle), StatusToolItem(type: .line), StatusToolItem(type: .arrow)]

    // 颜色选择CollectionView
    private lazy var colorCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.description())
        collectionView.register(ToolCell.self, forCellWithReuseIdentifier: ToolCell.description())
        collectionView.register(ToolAndColorHeadView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ToolAndColorHeadView.description())
        return collectionView
    }()

    private lazy var layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.headerReferenceSize = CGSize(width: 182, height: 36)
        layout.itemSize = Layout.colorSize
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = 31
        layout.sectionInset = UIEdgeInsets(top: 9, left: 11, bottom: 12, right: 11)
        return layout
    }()

    // 当前选中的设置选项
    weak var delegate: ToolAndColorDelegate?
    // 表示当前工具和颜色的配置
    private var currentSelection: BrushAndColorMemory?
    // 表示当前是pen的二级菜单还是shape的二级菜单
    private var toolWithColorType: ToolWithColorType

    init(toolWithColorType: ToolWithColorType) {
        self.toolWithColorType = toolWithColorType
        super.init(frame: .zero)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 10
        layer.masksToBounds = true
        layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        layer.borderWidth = 1

        addSubview(colorCollectionView)
        colorCollectionView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.left.right.equalToSuperview().inset(1)
        }
    }

    // 更新当前选择（比如恢复选择记忆）
    func configSelection(selection: BrushAndColorMemory, shouldReload: Bool = false) {
        self.currentSelection = selection
        for i in brushItems.indices {
            if let type = brushItems[i].type.brushType, type == selection.brushType {
                brushItems[i].isSelected = true
            } else {
                brushItems[i].isSelected = false
            }
        }
        for i in colorItems.indices {
            colorItems[i].isSelected = colorItems[i].type == selection.color
        }
        if shouldReload { colorCollectionView.reloadData() }
    }

    func configShapeTool(shapeToolConfig: ShapeTypeAndColor) {
        for i in shapeItems.indices {
            shapeItems[i].isSelected = shapeItems[i].type == shapeToolConfig.shape
        }
        for i in colorItems.indices {
            colorItems[i].isSelected = colorItems[i].type == shapeToolConfig.color
        }
    }
}

extension ToolAndColorView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            switch toolWithColorType {
            case .shape:
                return shapeItems.count
            case .brush:
                return brushItems.count
            }
        } else {
            return colorItems.count
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ToolCell.description(), for: indexPath) as? ToolCell else {
                return UICollectionViewCell()
            }
            switch toolWithColorType {
            case .brush:
                cell.configCell(item: brushItems[indexPath.row])
            case .shape:
                cell.configCell(item: shapeItems[indexPath.row])
            }
            return cell
        } else if indexPath.section == 1 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.description(), for: indexPath) as? ColorCell else {
                return UICollectionViewCell()
            }
            cell.configCell(item: colorItems[indexPath.row])
            return cell
        } else {
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var needRefreshCell: [IndexPath] = []
        var isNeedRefresh: Bool = false
        var selectedTool: ActionToolType?
        var selectedColor: ColorType?
        if indexPath.section == 0 {
            switch toolWithColorType {
            case .brush:
                for i in brushItems.indices {
                    if brushItems[i].isSelected {
                        needRefreshCell.append(IndexPath(row: i, section: 0))
                        if i != indexPath.row {
                            isNeedRefresh = true
                            selectedTool = brushItems[indexPath.row].type
                        }
                    }
                    brushItems[i].isSelected = false
                }
                brushItems[indexPath.row].isSelected = true
            case .shape:
                for i in shapeItems.indices {
                    if shapeItems[i].isSelected {
                        needRefreshCell.append(IndexPath(row: i, section: 0))
                        if i != indexPath.row {
                            isNeedRefresh = true
                            selectedTool = shapeItems[indexPath.row].type
                        }
                    }
                    shapeItems[i].isSelected = false
                }
                shapeItems[indexPath.row].isSelected = true
            }
        } else if indexPath.section == 1 {
            for i in colorItems.indices {
                if colorItems[i].isSelected {
                    needRefreshCell.append(IndexPath(row: i, section: 1))
                    if i != indexPath.row {
                        isNeedRefresh = true
                        selectedColor = colorItems[indexPath.row].type
                    }
                }
                colorItems[i].isSelected = false
            }
            colorItems[indexPath.row].isSelected = true
        }
        if isNeedRefresh {
            delegate?.didTapToolOrColor(tool: selectedTool, color: selectedColor)
            needRefreshCell.append(indexPath)
            collectionView.reloadItems(at: needRefreshCell)
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            if let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ToolAndColorHeadView.description(), for: indexPath) as? ToolAndColorHeadView {
                if indexPath.section == 0 {
                    reusableView.configHeadView(text: self.toolWithColorType.text, shouldShowLine: false)
                } else {
                    reusableView.configHeadView(text: self.toolWithColorType.colorText, shouldShowLine: true)
                }
                return reusableView
            }
            return UICollectionReusableView()
        }
        return UICollectionReusableView()
    }
}

// MARK: ipad上橡皮擦二级菜单
protocol EraseStrokeDelegate: AnyObject {
    func eraseStroke(type: EraserType)
}

// 橡皮擦选项
class EraserView: UIView {

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    lazy var clearView: BackColorAndArrowView = BackColorAndArrowView(type: .clear)
    lazy var clearMine: BackColorAndArrowView = BackColorAndArrowView(type: .clearMine)
    lazy var clearOther: BackColorAndArrowView = BackColorAndArrowView(type: .clearOther)
    lazy var clearAll: BackColorAndArrowView = BackColorAndArrowView(type: .clearAll)

    private var isSharer: Bool = false
    private var currentEraserType: EraserType = .clear
    weak var delegate: EraseStrokeDelegate?

    convenience init(isSharer: Bool) {
        self.init(frame: .zero)
        self.isSharer = isSharer
        configLayer()
        setupViews()
        setDelegate()
        setSelectState(currentEraserType)
    }

    func setSelectState(_ type: EraserType) {
        clearView.setSelectedState(isSelected: false)
        clearMine.setSelectedState(isSelected: false)
        if isSharer {
            clearOther.setSelectedState(isSelected: false)
            clearAll.setSelectedState(isSelected: false)
        }
        switch type {
        case .clear:
            clearView.setSelectedState(isSelected: true)
        case .clearAll:
            clearAll.setSelectedState(isSelected: true)
        case .clearMine:
            clearMine.setSelectedState(isSelected: true)
        case .clearOther:
            clearOther.setSelectedState(isSelected: true)
        }
    }

    private func setDelegate() {
        clearView.delegate = self
        clearMine.delegate = self
        if isSharer {
            clearOther.delegate = self
            clearAll.delegate = self
        }
    }

    private func configLayer() {
        backgroundColor = UIColor.ud.bgFloat
        layer.masksToBounds = true
        layer.cornerRadius = 6
        layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        layer.borderWidth = 1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowColor = UIColor.ud.vcTokenVCShadowSm.cgColor
    }

    private func setupViews() {
        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(3)
            maker.left.right.equalToSuperview().inset(1)
        }
        stackView.addArrangedSubview(clearView)
        stackView.addArrangedSubview(clearMine)
        if self.isSharer {
            stackView.addArrangedSubview(clearOther)
            stackView.addArrangedSubview(clearAll)
        }
    }

    func getSelectedType() -> EraserType {
        return currentEraserType
    }
}

extension EraserView: EraserButtonDelegate {
    func didTapEraserButton(type: EraserType) {
        currentEraserType = type
        setSelectState(type)
        delegate?.eraseStroke(type: type)
    }

    func didTapEraserButtonWithSelectedState(type: EraserType) {
        delegate?.eraseStroke(type: type)
    }
}
