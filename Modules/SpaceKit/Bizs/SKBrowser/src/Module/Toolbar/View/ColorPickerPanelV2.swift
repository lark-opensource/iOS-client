//
//  ColorPickerPanelV2.swift
//  SpaceKit
//
//  Created by Gill on 2020/5/21.
// swiftlint:disable file_length

import SnapKit
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import EENavigator
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignButton
import UIKit

/// PRD: https://bytedance.feishu.cn/docs/doccnE4C0tKAjq52yDsKWkDAXrg
/// 技术文档: https://bytedance.feishu.cn/docs/doccnS9m3t70fqd5QWntIAprpBg#
enum ColorPaletteItemCategory: String {
    case text
    case background
    case clear
    case reset

    var title: String {
        switch self {
        case .text:       return BundleI18n.SKResource.Doc_Doc_ColorSelectText
        case .background: return BundleI18n.SKResource.Doc_Doc_ColorSelectBackground
        case .clear:      return BundleI18n.SKResource.Doc_Doc_ColorSelectClear
        case .reset:      return BundleI18n.SKResource.CreationMobile_Common_Reset
        }
    }
    
    var isButtonCategroy: Bool {
        return self == .clear || self == .reset
    }
}

public final class ColorPaletteItemV2 {
    static let clearBackgroundColorKey = "COLOR_CLEAR_BACKGROUND"
    
    struct ColorInfo {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat

        init(_ json: [String: CGFloat]) {
            self.r = json["r"] ?? 255
            self.g = json["g"] ?? 255
            self.b = json["b"] ?? 255
            self.a = json["a"] ?? 0
        }

        init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        }

        var color: UIColor? {
            return UDColor.color(r, g, b, a)
        }
    }
    let category: ColorPaletteItemCategory
    let colorInfo: ColorInfo
    // 这是前端保存的一个颜色键，透传给前端就可以。
    let key: String

    var color: UIColor? {
        return colorInfo.color
    }
    var selected: Bool = false
    var showFontIcon: Bool = true

    init(category: ColorPaletteItemCategory,
         colorInfo: ColorInfo,
         key: String,
         selected: Bool = false,
         showFontIcon: Bool = true) {
        self.category = category
        self.colorInfo = colorInfo
        self.key = key
        self.selected = selected
        self.showFontIcon = showFontIcon
    }

    static func buttonItem(category: ColorPaletteItemCategory, key: String) -> ColorPaletteItemV2 {
        return ColorPaletteItemV2(category: category,
                                  colorInfo: ColorInfo(r: 0, g: 0, b: 0, a: 0),
                                  key: key)
    }

    var asDict: [String: Any] {
        return ["type": category.rawValue,
                "key": key,
                "value": ["r": colorInfo.r,
                          "g": colorInfo.g,
                          "b": colorInfo.b,
                          "a": colorInfo.a]]
    }

    public var callbackDict: [String: Any] {
        if self.category.isButtonCategroy {
            return [category.rawValue: ["key": key]]
        }
        return [category.rawValue: ["key": key,
                                    "value": ["r": colorInfo.r,
                                              "g": colorInfo.g,
                                              "b": colorInfo.b,
                                              "a": colorInfo.a]]]
    }
    
    var cornerMask: CACornerMask = []
}

public struct ColorPaletteModel {
    public static let defaultNumberOfLine = 7
    var category: ColorPaletteItemCategory
    var items: [ColorPaletteItemV2]
    var numberOfLine: Int = ColorPaletteModel.defaultNumberOfLine
    /// 构建 Model 对的 item 列表
    /// - Parameters:
    ///   - params: 每个 Model 对应的字典。包含 Item List
    ///   - category: Model 的分类
    ///   - selected: 当前选中是那个 Item。放在这里能最少地减少遍历次数
    static func makeItems(_ params: [[String: Any]],
                          category: ColorPaletteItemCategory,
                          selected: [String]? = nil) -> [ColorPaletteItemV2] {
        return params.compactMap {
            if let key = $0["key"] as? String,
                let colorInfo = $0["value"] as? [String: CGFloat] {
                let info = ColorPaletteItemV2.ColorInfo(colorInfo)
                let isSelected = selected?.contains(key) ?? false
                let showFontIcon = $0["showFontIcon"] as? Bool ?? true
                return ColorPaletteItemV2(category: category,
                                          colorInfo: info,
                                          key: key,
                                          selected: isSelected,
                                          showFontIcon: showFontIcon)
            }
            return nil
        }
    }

    static func clearModel(key: String) -> ColorPaletteModel {
        return ColorPaletteModel(category: .clear,
                                 items: [ColorPaletteItemV2.buttonItem(category: .clear, key: key)])
    }
    
    static func resetModel(key: String) -> ColorPaletteModel {
        return ColorPaletteModel(category: .reset,
                                 items: [ColorPaletteItemV2.buttonItem(category: .reset, key: key)])
    }
}

public struct ColorPickerUIConstant {
    public weak var hostView: UIView?

    var lrMargin: CGFloat { CGFloat(12.0) }
    var itemSize: CGFloat { CGFloat(48.0) }
    var iconSize: CGFloat { CGFloat(20.0) }
}

public protocol ColorPickerPanelV2Delegate: AnyObject {
    func hasUpdate(color: ColorPaletteItemV2, in panel: ColorPickerPanelV2)
}

class StrictCollectionViewLayout: UICollectionViewFlowLayout {
    
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return super.layoutAttributesForElements(in: rect)
        }
        for (idx, attributes) in layoutAttributes.enumerated() where idx > 0 {
            let maximumSpacing: CGFloat = self.minimumInteritemSpacing
            let prevAttributes = layoutAttributes[idx - 1]
            let preMaxX = prevAttributes.frame.maxX
            if preMaxX + maximumSpacing + attributes.frame.size.width < self.collectionViewContentSize.width {
                var currentFrame = attributes.frame
                currentFrame.origin.x = preMaxX + maximumSpacing
                attributes.frame = currentFrame
            }
        }
        return layoutAttributes
    }
}

public final class ColorPickerPanelV2: UIView {
    public weak var delegate: ColorPickerPanelV2Delegate?
    private(set) var data: [ColorPaletteModel] {
        didSet {
            setupDataCorner()
        }
    }
    private(set) var collectionView: UICollectionView
    private let keyboard = Keyboard()
    // 利用 CollectionView 自身的 cellForItem 方法，
    // 可以获取 data 段里的 selected，保存下来，从而减少遍历
    private var _selected: ColorPaletteItemV2?
    private var selected: ColorPaletteItemV2? {
        if let s = _selected,
            s.selected {
            return s
        } else {
            data.forEach {
                if let s = $0.items.first(where: { return $0.selected }) {
                    _selected = s
                }
            }
            return _selected
        }
    }

    private let layout = StrictCollectionViewLayout()
    //非替换键盘的其它显示方式，需要关闭宽间距模式
    public var isNewShowingMode = false {
        didSet {
            guard isNewShowingMode else { return }
//            self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.collectionView.isScrollEnabled = false
            self.collectionView.layer.cornerRadius = 4
        }
    }

    public var collectionViewCanScroll: Bool = false {
        didSet {
            self.collectionView.isScrollEnabled = collectionViewCanScroll
        }
    }

    public var viewBackgroudColor: UIColor = UDColor.bgBody {
        didSet {
//            self.collectionView.backgroundColor = viewBackgroudColor
        }
    }

    public var uiConstant = ColorPickerUIConstant()

    private var clearCellHeight: CGFloat = 48
    private var cellWidthCache: [Int: CGFloat] = [:]

    private let reuseIdentifier: String = "com.bytedance.ee.docs.colorpicker"
    private let reuseClearIdentifier: String = "com.bytedance.ee.docs.colorpicker.clear"

    deinit {
        keyboard.stop()
    }

    public init(frame: CGRect, data: [ColorPaletteModel]) {
        // make UICollectionView
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        self.collectionView = UICollectionView(frame: .zero,
                                               collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: uiConstant.lrMargin, bottom: 0, right: uiConstant.lrMargin)
        collectionView.delaysContentTouches = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ColorPickerCellV2.self,
                                forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(ColorPickerClearCell.self,
                                forCellWithReuseIdentifier: reuseClearIdentifier)
        collectionView.register(ColorPickerHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: String(describing: ColorPickerHeaderView.self))

        self.data = data
        super.init(frame: frame)

        collectionView.delegate = self
        collectionView.dataSource = self

        _addSubviews()
        keyboard.on(events: [.didChangeFrame]) { [weak self] (options) in
            self?.onKeyboardChange(options: options)
        }
        keyboard.start()
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(_ data: [ColorPaletteModel]) {
        DocsLogger.debug("[ColorPicker] updateData boundsSize:\(self.bounds.width)")
        self.data = data
        reloadData()
    }

    //iPad转屏时刷新页面布局
    public func refreshViewLayout() {
        DocsLogger.debug("[ColorPicker] refreshViewLayout")
        reloadData()
    }
    
    private func reloadData() {
        cellWidthCache.removeAll()
        updateContentInset()
        collectionView.reloadData()
    }

    private func _addSubviews() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func onKeyboardChange(options: Keyboard.KeyboardOptions) {
    }
    
    private func setupDataCorner() {
        for d in data {
            let cols = d.numberOfLine
            let rows = d.items.count / cols
            for (idx, item) in d.items.enumerated() {
              let row = idx / cols
              let col = idx % cols
                if rows < 2 { // 只有一行
                    if col == 0 {
                        item.cornerMask = .left
                    } else if col == cols - 1 {
                        item.cornerMask = .right
                    }
                } else {
                    if row == 0 {
                        if col == 0 {
                            item.cornerMask = [.layerMinXMinYCorner]
                        } else if col == cols - 1 {
                            item.cornerMask = [.layerMaxXMinYCorner]
                        }
                    } else if row == rows - 1 {
                        if col == 0 {
                            item.cornerMask = [.layerMinXMaxYCorner]
                        } else if col == cols - 1 {
                            item.cornerMask = [.layerMaxXMaxYCorner]
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ColorPickerPanelV2: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return data[section].items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = data[indexPath.section]
        if model.category.isButtonCategroy {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseClearIdentifier, for: indexPath)
            if let clearCell = cell as? ColorPickerClearCell {
                let item = model.items[indexPath.row]
                clearCell.update(model.category.title, uiConstant: uiConstant, action: { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.hasUpdate(color: item, in: self)
                })
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            if let pickerCell = cell as? ColorPickerCellV2 {
                let item = model.items[indexPath.row]
                let size = self.collectionView(collectionView, layout: layout, sizeForItemAt: indexPath)
                pickerCell.update(item, uiConstant: uiConstant, size: size)
            }
            return cell
        }
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
}

// MARK: - UICollectionViewDelegate / UICollectionViewDelegateFlowLayout
extension ColorPickerPanelV2: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let model = data[indexPath.section]
        if model.category.isButtonCategroy { return }
        let item = model.items[indexPath.row]
        delegate?.hasUpdate(color: item, in: self)
        clearAllCellPointer()
    }
    
    func clearAllCellPointer() {
        let cells = self.collectionView.visibleCells
        for cell in cells where cell is ColorPickerCellV2 {
            if let aCell = cell as? ColorPickerCellV2 {
                aCell.removeAllPointer()
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let model = data[indexPath.section]
        if model.category.isButtonCategroy {
            let viewWidth = self.bounds.width
            return CGSize(width: viewWidth, height: clearCellHeight)
        } else {
            if let width = cellWidthCache[model.numberOfLine], width > 0 {
                return CGSize(width: width, height: 48)
            } else {
                let width = calcCellWidth(numberOfLine: CGFloat(model.numberOfLine))
                cellWidthCache[model.numberOfLine] = width
                return CGSize(width: width, height: 48)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                       withReuseIdentifier: String(describing: ColorPickerHeaderView.self),
                                                                       for: indexPath)
            if let header = view as? ColorPickerHeaderView {
                header.update(data[indexPath.section].category.title, uiConstant: uiConstant)
                let model = data[indexPath.section]
                if model.category.isButtonCategroy {
                    header.update("", uiConstant: uiConstant)
                }
            }
            return view
        } else {
             return UICollectionReusableView()
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        if data[section].category.isButtonCategroy {
            return CGSize(width: collectionView.frame.width, height: 0.01)
        }
        return CGSize(width: collectionView.frame.width, height: 36)
    }

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    }
}

private extension ColorPickerPanelV2 {
    func calcCellWidth(numberOfLine: CGFloat) -> CGFloat {
        guard self.bounds.width > 0 else { return 0 }
        let viewWidth = self.bounds.width
        var itemWidth = (viewWidth - uiConstant.lrMargin * 2 - numberOfLine - 1) / numberOfLine
        itemWidth = floor(itemWidth * 10) / 10 //保留一位小数
        DocsLogger.debug("[ColorPicker] calcCellWidth  count:\(numberOfLine), width:\(viewWidth), itemWidth:\(itemWidth)")
        return itemWidth
    }
    
    func updateContentInset() {
        guard !self.data.isEmpty, self.bounds.width > 0 else { return }
        var minNumberOfLine = 0
        for item in self.data where !item.category.isButtonCategroy && (item.numberOfLine < minNumberOfLine || minNumberOfLine == 0) {
            minNumberOfLine = item.numberOfLine
        }
        let numberOfLine = CGFloat(minNumberOfLine)
        let viewWidth = self.bounds.width
        let itemWidth = calcCellWidth(numberOfLine: numberOfLine)
        var padding = (viewWidth - (itemWidth * numberOfLine + numberOfLine + 1)) / 2
        padding = floor(padding * 10) / 10 //保留一位小数
        collectionView.contentInset = UIEdgeInsets(top: 20, left: padding, bottom: 0, right: padding)
        DocsLogger.debug("[ColorPicker] updateContentInset  count:\(minNumberOfLine), width:\(viewWidth), itemWidth:\(itemWidth), padding:\(padding), uiConstant.lrMargin:\(uiConstant.lrMargin)")
    }
}

private class ColorPickerCellV2: UICollectionViewCell {
    private let aIcon: UIImageView = UIImageView(image: BundleResources.SKResource.Common.Tool.icon_tool_highlight_nor)
    private var uiConstant = ColorPickerUIConstant()
    private lazy var content = UIView()

    private var item: ColorPaletteItemV2?
    
    var disposeBag = DisposeBag()
    
    var hoverView: UIView?
    
    var borderView: DoubleBorderView?
    var obliqueLineLayer: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(content)
        content.addSubview(aIcon)
        addHover()
        layoutViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        removeAllPointer()
        obliqueLineLayer?.removeFromSuperlayer()
        obliqueLineLayer = nil
        content.layer.borderWidth = 0
        content.layer.borderColor = nil
    }
    
    func removeAllPointer() {
        hoverView?.docs.removeAllPointer()
    }
    
    func addHover() {
        guard SKDisplay.pad else { return }
        let view = UIView()
        hoverView = view
        content.addSubview(view)
        content.clipsToBounds = true
    }
    
    func layoutViews() {
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        hoverView?.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        aIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    lazy var iconImage: UIImage = {
        return UDIcon.getIconByKey(.fontcolorOutlined, renderingMode: .alwaysOriginal, size: .init(width: 20, height: 20))
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ item: ColorPaletteItemV2, uiConstant: ColorPickerUIConstant, size: CGSize) {
        hoverView?.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        self.item = item
        self.uiConstant = uiConstant
        let cornerRadius: CGFloat = item.cornerMask.isEmpty ? 0 : 8
        
        if item.category == .text {
            aIcon.image = iconImage.ud.withTintColor(item.color ?? UDColor.iconN1)
            content.backgroundColor = UIColor.ud.bgFloatOverlay
        } else if item.category == .background {
            if item.showFontIcon {
                aIcon.image = iconImage.ud.withTintColor(UDColor.iconN1)
            } else {
                aIcon.image = nil
            }
            content.backgroundColor = item.color
            if item.key == ColorPaletteItemV2.clearBackgroundColorKey {
                //清除颜色Item特殊样式
                let borderWidth: CGFloat = 1
                let lineLayer = createObliqueLine(bounds: CGRect(origin: .zero, size: size),
                                                  cornerMask: item.cornerMask,
                                                  cornerRadius: cornerRadius,
                                                  borderWidth: borderWidth,
                                                  color: UDColor.lineBorderComponent)
                lineLayer.maskedCorners = item.cornerMask
                obliqueLineLayer = lineLayer
                content.layer.addSublayer(lineLayer)
                content.layer.borderWidth = borderWidth
                content.layer.borderColor = UDColor.lineBorderComponent.cgColor
            }
        }

        if item.selected {
            self.showBorder(bounds: CGRect(origin: .zero, size: size))
        } else {
            self.hideBorder()
        }
        
        self.layer.zPosition = item.selected ? 10 : 0
        content.layer.maskedCorners = item.cornerMask
        content.layer.cornerRadius = cornerRadius
    }
}


extension ColorPickerCellV2 {
    func showBorder(bounds: CGRect, _ outerWidth: CGFloat = 3, _ innerWidth: CGFloat = 2, _ color: UIColor = UDColor.colorfulBlue) {
        if borderView == nil {
            let view = DoubleBorderView(outerConfig: DoubleBorderView.Config(color: color, borderWidth: outerWidth, cornerRadius: 6),
                                          innerConfig: DoubleBorderView.Config(color: UIColor.ud.bgBody, borderWidth: innerWidth, cornerRadius: 4),
                                          frame: bounds.outerBorder(width: outerWidth))
            view.isUserInteractionEnabled = false
            self.addSubview(view)
            self.bringSubviewToFront(view)
            borderView = view
        } else {
            // iPad窗口大小发生改变时需要及时更新frame
            CATransaction.withDisabledActions {
                let frame = bounds.outerBorder(width: outerWidth)
                self.borderView?.frame = frame
                self.borderView?.update(frame: frame)
                borderView?.isHidden = false
            }
        }
    }

    func hideBorder() {
        borderView?.isHidden = true
    }
    
    
    private func createObliqueLine(bounds: CGRect,
                                   cornerMask: CACornerMask,
                                   cornerRadius: CGFloat,
                                   borderWidth: CGFloat,
                                   color: UIColor) -> CALayer {
        let linePath = UIBezierPath()
        let cornerOffset = cornerRadius / 2 - borderWidth
        var startPoint = CGPoint(x: borderWidth, y: borderWidth)
        if cornerMask.contains(.layerMinXMinYCorner) {
            startPoint = CGPoint(x: cornerOffset, y: cornerOffset)
        }
        var endPoint = CGPoint(x: bounds.width - borderWidth, y: bounds.height - borderWidth)
        if cornerMask.contains(.layerMaxXMaxYCorner) {
            endPoint = CGPoint(x: bounds.width - cornerOffset, y: bounds.height - cornerOffset)
        }
        linePath.move(to: startPoint)
        linePath.addLine(to: endPoint)
        let lineLayer = CAShapeLayer()
        lineLayer.lineWidth = 1
        lineLayer.strokeColor = color.cgColor
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = nil
        return lineLayer
    }
}

fileprivate extension CATransaction {
    class func withDisabledActions<T>(_ body: () throws -> T) rethrows -> T {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer {
            CATransaction.commit()
        }
        return try body()
    }
}

private class ColorPickerClearCell: UICollectionViewCell {
    private var action = {}
    private var uiConstant = ColorPickerUIConstant()
    private let disposeBag: DisposeBag = DisposeBag()


    private let button: UIButton = {
        var config = UDButton.secondaryGray.config
        config.type = .big
        config.radiusStyle = .square
        let button = UDButton(config)
//        button.setBackgroundImage(UIImage.docs.create(by: UDColor.N200), for: .highlighted)
//        button.setBackgroundImage(UIImage.docs.create(by: .clear), for: .normal)
//        button.layer.cornerRadius = 8.0
//        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
//        button.layer.masksToBounds = true
        button.setTitleColor(UDColor.textTitle, for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(button)
        button.docs.addHover(with: UDColor.N200, disposeBag: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onClick() {
        self.action()
    }

    func update(_ title: String?, uiConstant: ColorPickerUIConstant, action: @escaping () -> Void) {
        self.uiConstant = uiConstant
        let selectBorderWidth = CGFloat(1)
        button.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(uiConstant.lrMargin + selectBorderWidth)
            make.right.equalToSuperview().offset(-uiConstant.lrMargin - selectBorderWidth)
            make.top.bottom.equalToSuperview()
        }
        button.setTitle(title, withFontSize: 16, fontWeight: .regular, color: UDColor.N900, forState: .normal)
        self.action = action
        button.addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }
}

private class ColorPickerHeaderView: UICollectionReusableView {

    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ title: String?, uiConstant: ColorPickerUIConstant) {
        label.text = title
        label.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

}

// MARK: - 双边框样式UI

class DoubleBorderView: UIView {

    struct Config {
        var color: UIColor
        var borderWidth: CGFloat
        var cornerRadius: CGFloat
        
        static var zero: Config {
            return Config(color: .clear, borderWidth: 0, cornerRadius: 0)
        }
    }
    
    private var outerLayer = CALayer()
    private var innerLayer = CALayer()
    private var outerConfig: Config = .zero
    private var innerConfig: Config = .zero
    
    ///   - frame: 相当于外边框的frame
    convenience init(outerConfig: Config, innerConfig: Config, frame: CGRect) {
        self.init(frame: frame)
        self.outerConfig = outerConfig
        self.innerConfig = innerConfig
        layer.addSublayer(outerLayer)
        layer.addSublayer(innerLayer)
        
        outerLayer.ud.setBackgroundColor(outerConfig.color)
        outerLayer.cornerRadius = outerConfig.cornerRadius
    
        innerLayer.ud.setBackgroundColor(innerConfig.color)
        innerLayer.cornerRadius = innerConfig.cornerRadius
        
        update(frame: frame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard outerLayer.frame != frame else {
            return
        }
        update(frame: frame)
    }
    
    func update(frame: CGRect) {
        let bounds = CGRect(origin: .zero, size: frame.size)
        outerLayer.frame = bounds
        innerLayer.frame = bounds.innerBorder(width: outerConfig.borderWidth)
        let path = UIBezierPath(roundedRect: bounds.innerBorder(width: outerConfig.borderWidth + innerConfig.borderWidth), cornerRadius: 2)
        let bigPath = UIBezierPath(rect: bounds)
        bigPath.append(path.reversing())
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bigPath.cgPath
        layer.mask = shapeLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CGRect {
    
    func outerBorder(width: CGFloat) -> CGRect {
        return CGRect(x: -width, y: -width, width: self.width + width * 2, height: self.height + width * 2)
    }
    
    func innerBorder(width: CGFloat) -> CGRect {
        return CGRect(x: width, y: width, width: self.width - width * 2, height: self.height - width * 2)
    }
}
