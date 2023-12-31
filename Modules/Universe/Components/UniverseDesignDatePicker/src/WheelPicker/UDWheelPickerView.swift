//
//  UDWheelPickerView.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/11/17.
//

import Foundation
import UIKit
import SnapKit
import AudioToolbox
import UniverseDesignColor

/// 滚轮类型
public enum UDWheelCircelMode {
    /// 循环滚动
    case circular
    /// 有限区域
    case limited
}

public protocol UDWheelPickerViewDataSource: AnyObject {
    /// 滚轮的列数，有几列
    func numberOfCloumn(in wheelPicker: UDWheelPickerView) -> Int
    /// 单个滚轮的展示行数
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, numberOfRowsInColumn column: Int) -> Int
    /// 单个滚轮的宽度
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, widthForColumn column: Int) -> CGFloat

    /// 滚轮 cell 配置
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, viewForRow row: Int,
                         atColumn column: Int) -> UDWheelPickerCell

    /// 配置滚轮滚动模式（无限/有限）
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, modeOfColumn column: Int) -> UDWheelCircelMode
    /// 配置滚轮收缩系数
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, flexShrinkOfColumn column: Int) -> CGFloat
}

extension UDWheelPickerViewDataSource {
    /// pickerView收缩系数，为0时特化为不收缩
    /// 参考 CSS - Shrink:
    /// https://cssreference.io/property/flex-shrink/
    /// - Parameters:
    ///   - wheelPicker: pickerView
    ///   - column: columnIndex
    /// - Returns: 收缩系数
    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, flexShrinkOfColumn column: Int) -> CGFloat {
        return 1
    }
}

public protocol UDWheelPickerViewDelegate: AnyObject {
    // Responding to Row Actions
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, atColumn column: Int)
}

extension UDWheelPickerViewDelegate {
    /// PickerView 滚轮选中回调
    public func wheelPickerView(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, atColumn colunm: Int) {}
}

public final class UDWheelPickerView: UIView {

    typealias ColumnInfo = (width: CGFloat, flexShrink: CGFloat, rowNum: Int, mode: UDWheelCircelMode)
    typealias ColumnIndex = Int
    typealias Scale = CGFloat

    public weak var delegate: UDWheelPickerViewDelegate?
    public weak var dataSource: UDWheelPickerViewDataSource? {
        didSet {
            setupColumns()
        }
    }

    private let maxDisplayRows: Int
    private let pickerHeight: CGFloat
    private let wheelAnimation: Bool
    private let hasMask: Bool
    private var showMask: Bool {
        let isOddAndGreaterOne = (maxDisplayRows - 2) % 2 == 1 && hasMask
        return isOddAndGreaterOne
    }
    private let showSepLine: Bool
    private let gradientColor: UIColor

    private var columnsInfos = [ColumnInfo]()
    private var wrapper = UIView()
    private var columns = [PageView]()
    private var topLayer: CAGradientLayer = CAGradientLayer()
    private var bottomLayer: CAGradientLayer = CAGradientLayer()
    private let generator = UIImpactFeedbackGenerator(style: .light)

    /// 创建PickerView，支持多个滚轮、自定义高度、滚轮动画、聚焦蒙层
    /// - Parameters:
    ///   - pickerHeight: 自定义滚轮高度，默认 3 * 48
    ///   - wheelAnimation: 是否应用滚轮动画，默认 true
    ///   - hasMask: 是否应用聚焦蒙层，仅maxDisplayRows为奇数且>1时，hasMask可以为true 默认 true
    ///   - showSepLine: 是否展示聚焦分割线，默认 true
    ///   - impactOccurred: 是否添加滚轮震动反馈，默认 false
    ///   - grandientColor: 渐变 Mask color，默认 bgBase
    public init(pickerHeight: CGFloat = 48 * 3,
                wheelAnimation: Bool = true,
                hasMask: Bool = true,
                showSepLine: Bool = true,
                impactOccurred: Bool = false,
                gradientColor: UIColor = UDColor.bgBase) {
        let rows = Int(ceil((pickerHeight - 48) / (2.0 * 48)) * 2 + 1)
        self.maxDisplayRows = rows
        self.pickerHeight = pickerHeight
        self.wheelAnimation = wheelAnimation
        self.hasMask = hasMask
        self.gradientColor = gradientColor
        self.showSepLine = showSepLine
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 实际高度
    var intrinsicHeight: CGFloat {
        pickerHeight + 8 * 2
    }

    /// 全局数据刷新
    public func reload() {
        for index in 0..<columnsInfos.count {
            reload(columnIndex: index)
        }
    }

    /// 通过 dataSource reload 单个滚轮
    /// - Parameter columnIndex: 列下标
    public func reload(columnIndex: Int) {
        guard let dataSource = dataSource else { return }
        guard (0..<columnsInfos.count).contains(columnIndex) else {
            assertionFailure("没有对应列的数据，请检查 columnIndex 是否正确")
            return
        }
        let width = dataSource.wheelPickerView(self, widthForColumn: columnIndex)
        let rowNum = dataSource.wheelPickerView(self, numberOfRowsInColumn: columnIndex)
        let flexShrink = dataSource.wheelPickerView(self, flexShrinkOfColumn: columnIndex)
        let mode = dataSource.wheelPickerView(self, modeOfColumn: columnIndex)
        let newInfo = ColumnInfo(width, flexShrink, rowNum, mode)
        columnsInfos[columnIndex] = newInfo
        columns.remove(at: columnIndex).removeFromSuperview()

        let isCircular = newInfo.mode == UDWheelCircelMode.circular
        // 本来考虑可以只刷数据，不用重新 new 对象，但需要修改的 totalPageCount 不支持change，可以考虑添加
        // 然后只需要刷数据即可
        let newColumn = PageView(totalPageCount: isCircular ? 600 * newInfo.rowNum : newInfo.rowNum,
                                 direction: .vertical)
        newColumn.delegate = self
        newColumn.dataSource = self
        newColumn.scrollView.bounces = true
        newColumn.scrollView.clipsToBounds = true
        newColumn.pageCountPerScene = min(newInfo.rowNum, maxDisplayRows)
        wrapper.insertSubview(newColumn, at: 0)
        columns.insert(newColumn, at: columnIndex)
        // 375 不是实际宽度，实际通过 autoLayout 约束，这里只是有用作被除数计算比例
        let scales = caculateScale(containerWidth: 375, columnsInfos: columnsInfos)
        setupColumnsConstraints(scales)
    }

    // 选中目标位置，调用select时，需要frame已经设置，否则滚动位置不正确，返回选中下标
    public func select(in column: Int, at row: Int, animated: Bool) -> Int {
        guard column < columnsInfos.count && column > -1 else {
            assertionFailure("column 数组越界")
            return -1
        }
        // row --> index
        let index: Int
        if columnsInfos[column].mode == .limited {
            index = row - maxDisplayRows / 2
        } else {
            // 认为只有 initState 过程会调用
            index = 300 * columnsInfos[column].rowNum + row - maxDisplayRows / 2
        }
        columns[column].scroll(to: index, animated: animated)
        if wheelAnimation {
            let pickerView = self.columns[column]
            DispatchQueue.main.async {
                let cellScaleRect = pickerView.scrollView.frame.insetBy(dx: 0, dy: 40)
                for pageIndex in pickerView.visiblePageRange {
                    guard let cell = pickerView.itemView(at: pageIndex) as? UDWheelPickerCell else { continue }
                    let cellFrame = cell.convert(cell.bounds, to: pickerView)
                    cell.animate(frameInContainer: cellFrame,
                                 supperView: pickerView.scrollView,
                                 rowNum: self.maxDisplayRows)
                }
            }
        }
        return index
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if showMask { layoutGradientLayer() }
        columns.forEach({ $0.freezeStateIfNeeded() })
        columns.forEach({ $0.layoutIfNeeded() })
        columns.forEach({ $0.unfreezeStateIfNeeded() })
    }

    func getWheelPickerCell(ofColumn columnIndex: Int, atRow rowIndex: PageIndex) -> UDWheelPickerCell {
        let column = columns[columnIndex]
        guard let cell = column.itemView(at: rowIndex), let wheelCell = cell as? UDWheelPickerCell else {
            assertionFailure("未取到对应 cell")
            return UDDefaultWheelPickerCell()
        }
        return wheelCell
    }

    private func setupColumns() {
        columns.removeAll()
        wrapper.subviews.forEach { $0.removeFromSuperview() }
        wrapper.removeFromSuperview()
        // refresh info
        guard let dataSource = dataSource else { return }
        columnsInfos = (0..<dataSource.numberOfCloumn(in: self)).map { (columnIndex) in
            let width = dataSource.wheelPickerView(self, widthForColumn: columnIndex)
            let rowNum = dataSource.wheelPickerView(self, numberOfRowsInColumn: columnIndex)
            let flexShrink = dataSource.wheelPickerView(self, flexShrinkOfColumn: columnIndex)
            let mode = dataSource.wheelPickerView(self, modeOfColumn: columnIndex)
            return ColumnInfo(width, flexShrink, rowNum, mode)
        }
        for info in columnsInfos {
            let isCircular = info.mode == UDWheelCircelMode.circular
            let column = PageView(totalPageCount: isCircular ? 600 * info.rowNum :info.rowNum,
                                  direction: .vertical)
            column.delegate = self
            column.dataSource = self
            column.scrollView.bounces = true
            column.pageCountPerScene = maxDisplayRows
            wrapper.addSubview(column)
            columns.append(column)
        }
        wrapper.clipsToBounds = true
        addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.height.equalTo(pickerHeight)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        // 1 不是实际宽度，实际通过 autoLayout 约束，这里只是有用作被除数计算比例
        let columnsScale = caculateScale(containerWidth: 1, columnsInfos: columnsInfos)
        setupColumnsConstraints(columnsScale)
        if showSepLine { showSeperatLine() }
        if showMask { setupGradientLayer() }
    }

    private func caculateScale(containerWidth pickerWidth: CGFloat, columnsInfos: [ColumnInfo]) -> [Scale] {
        guard pickerWidth > 0 else {
            assertionFailure("PickerView宽度为零，初始化时不能传零，计算约束依赖width")
            return []
        }
        var remainWidth = pickerWidth
        var widthSum: CGFloat = 0
        let tempScales = columnsInfos.map {(width, flexShrink, _, _) -> Scale in
            if flexShrink == 0 {
                remainWidth -= width
                if remainWidth > 0 {
                    return CGFloat(width / pickerWidth)
                } else { // 指定宽度超限,暂定为-1,不为其分配
                    assertionFailure()
                    return CGFloat(-1)
                }
            } else {
                widthSum += flexShrink * width
                return CGFloat(0)
            }
        }
        var scales = [Scale]()
        columnsInfos.enumerated().forEach {(index, info) in
            if tempScales[index] == 0 {
                let columnFactWidth = (info.width * info.flexShrink) / widthSum * remainWidth
                scales.append(columnFactWidth / pickerWidth)
            } else {
                scales.append(tempScales[index])
            }
        }
        return scales
    }

    private func setupColumnsConstraints(_ columnsScale: [Scale]) {
        columns.enumerated().forEach { (index, column) in
            column.snp.remakeConstraints { (make) in
                make.height.equalTo(48 * maxDisplayRows)
                make.centerY.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(columnsScale[index])
                if index == 0 {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalTo(columns[index - 1].snp.right)
                }
            }
        }
    }

    private func showSeperatLine() {
        let offset = 48 / 2.0
        let topBorder = UIView()
        topBorder.backgroundColor = UDDatePickerTheme.wheelPickerLinePrimaryBgNormalColor
        wrapper.addSubview(topBorder)
        topBorder.snp.makeConstraints { (make) in
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-offset)
        }
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UDDatePickerTheme.wheelPickerLinePrimaryBgNormalColor
        wrapper.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { (make) in
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(offset)
        }
    }

    // GradientLayer
    private func setupGradientLayer() {
        topLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topLayer.endPoint = CGPoint(x: 0.5, y: 1)

        wrapper.layer.addSublayer(topLayer)

        bottomLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomLayer.endPoint = CGPoint(x: 0.5, y: 1)

        wrapper.layer.addSublayer(bottomLayer)
    }

    // refresh Layer's frame
    private func layoutGradientLayer() {
        let layerHeight = (wrapper.bounds.height - 48) / CGFloat(2)
        topLayer.frame = CGRect(x: 0, y: 0, width: wrapper.bounds.width, height: layerHeight)
        bottomLayer.frame = CGRect(x: 0, y: layerHeight + 48,
                                   width: bounds.width, height: layerHeight)
        topLayer.colors = [gradientColor.withAlphaComponent(1.0).cgColor,
                           gradientColor.withAlphaComponent(0.0).cgColor]
        bottomLayer.colors = [gradientColor.withAlphaComponent(0.0).cgColor,
                              gradientColor.withAlphaComponent(1.0).cgColor]
    }
}
// MARK: PageViewDataSource
extension UDWheelPickerView: PageViewDataSource {
    func itemView(at index: PageIndex, in pageView: PageView) -> UIView {
        guard let columnIndex = columns.firstIndex(of: pageView),
              let dataSource = dataSource,
              columnIndex < columnsInfos.count,
              columnIndex > -1 else {
            return UIView()
        }
        // index --> row
        let columnInfo = columnsInfos[columnIndex]
        let row: Int
        if columnInfo.mode == UDWheelCircelMode.circular {
            row = index % columnInfo.rowNum
        } else {
            row = index
        }
        let itemView = dataSource.wheelPickerView(self, viewForRow: row, atColumn: columnIndex)
        return itemView
    }
}
// MARK: PageViewDelegate
extension UDWheelPickerView: PageViewDelegate {
    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset) {
        if wheelAnimation {
            for pageIndex in pageView.visiblePageRange {
                guard let cell = pageView.itemView(at: pageIndex) as? UDWheelPickerCell else { continue }
                let cellFrame = cell.convert(cell.bounds, to: pageView)
                cell.animate(frameInContainer: cellFrame, supperView: pageView.scrollView, rowNum: maxDisplayRows)
            }
        }
    }

    func pageViewWillBeginFixingIndex(_ pageView: BasePageView, targetIndex: PageIndex, animated: Bool) {
        let baseColumns: [BasePageView] = columns
        guard let column = baseColumns.firstIndex(of: pageView) else { return }
        delegate?.wheelPickerView(self, didSelectIndex: targetIndex, atColumn: column)
    }
}
