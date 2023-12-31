//
//  SearchDateYearMonthPickerView.swift
//  LarkSearchFilter
//
//  Created by ByteDance on 2023/11/20.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import LKCommonsLogging

struct SearchDateYearMonthPickerConfig {
    let minDate: Date
    let maxDate: Date
    let defaultSelectedYear: Int
    let defaultSelectedMonth: Int

    var isLegal: Bool {
        let yearCheck: Bool = defaultSelectedYear >= minDate.year && defaultSelectedYear <= maxDate.year
        var monthCheck: Bool = true
        if defaultSelectedYear == minDate.year, defaultSelectedMonth < minDate.month {
            monthCheck = false
        }
        if defaultSelectedYear == maxDate.year, defaultSelectedMonth > maxDate.month {
            monthCheck = false
        }
        if defaultSelectedMonth < 1 || defaultSelectedMonth > 12 {
            monthCheck = false
        }
        return minDate <= maxDate && yearCheck && monthCheck
    }
}

final class SearchDateYearMonthPickerCell: UITableViewCell {
    static let cellHeight: CGFloat = 48.0
    private let pickerTextLabel: UILabel = {
        let pickerTextLabel = UILabel()
        pickerTextLabel.font = UIFont.systemFont(ofSize: 17)
        pickerTextLabel.textColor = UIColor.ud.textTitle
        pickerTextLabel.textAlignment = .center
        return pickerTextLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(pickerTextLabel)
        pickerTextLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pickerTextLabel.text = nil
    }

    func updateTextLabel(text: String?, disable: Bool) {
        pickerTextLabel.text = text
        pickerTextLabel.textColor = disable ? UIColor.ud.textDisabled : UIColor.ud.textTitle
    }

    func updateTextLabelTransform(transform: CGAffineTransform) {
        pickerTextLabel.transform = transform
    }
}

final class SearchDateYearMonthPickerView: UIView, UITableViewDelegate, UITableViewDataSource {
    static let logger = Logger.log(SearchDateYearMonthPickerView.self, category: "SearchDateYearMonthPickerView")
    static let defaultMinDate: Date = Date(year: 1900, month: 1, day: 1)
    static let defaultMaxDate: Date = Date(year: 2099, month: 12, day: 31)
    private static let minCellScale: CGFloat = 0.8235
    private var minDate: Date
    private var maxDate: Date
    private var shouldStopScrollImmediately: Bool = false
    public private(set) var selectedYear: Int
    public private(set) var selectedMonth: Int
    public var selectedChanged: ((Int, Int) -> Void)?
    private let yearTableView: UITableView = {
        let yearTableView = UITableView()
        yearTableView.separatorStyle = .none
        yearTableView.showsVerticalScrollIndicator = false
        yearTableView.showsHorizontalScrollIndicator = false
        yearTableView.backgroundColor = UIColor.ud.bgFloat
        yearTableView.register(SearchDateYearMonthPickerCell.self, forCellReuseIdentifier: "SearchDateYearMonthPickerCell")
        yearTableView.allowsSelection = false
        return yearTableView
    }()
    private let monthTableView: UITableView = {
        let monthTableView = UITableView()
        monthTableView.separatorStyle = .none
        monthTableView.showsVerticalScrollIndicator = false
        monthTableView.showsHorizontalScrollIndicator = false
        monthTableView.backgroundColor = UIColor.ud.bgFloat
        monthTableView.register(SearchDateYearMonthPickerCell.self, forCellReuseIdentifier: "SearchDateYearMonthPickerCell")
        monthTableView.allowsSelection = false
        return monthTableView
    }()
    private var topLayer: CAGradientLayer = CAGradientLayer()
    private var bottomLayer: CAGradientLayer = CAGradientLayer()

    init(config: SearchDateYearMonthPickerConfig?) {
        if let _config = config, _config.isLegal {
            self.minDate = _config.minDate
            self.maxDate = _config.maxDate
            self.selectedYear = _config.defaultSelectedYear
            self.selectedMonth = _config.defaultSelectedMonth
        } else {
            self.minDate = Self.defaultMinDate
            self.maxDate = Self.defaultMaxDate
            self.selectedYear = Date().year
            self.selectedMonth = Date().month
        }
        super.init(frame: .zero)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.ud.bgFloat
        // tableView
        yearTableView.delegate = self
        yearTableView.dataSource = self
        addSubview(yearTableView)
        yearTableView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.trailing.equalTo(self.snp.centerX)
        }
        monthTableView.delegate = self
        monthTableView.dataSource = self
        addSubview(monthTableView)
        monthTableView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalTo(self.snp.centerX)
        }

        // mask layer
        topLayer.startPoint = CGPoint(x: 0.5, y: 0)
        topLayer.endPoint = CGPoint(x: 0.5, y: 1)
        bottomLayer.startPoint = CGPoint(x: 0.5, y: 0)
        bottomLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(topLayer)
        layer.addSublayer(bottomLayer)

        // separator line
        let offset = SearchDateYearMonthPickerCell.cellHeight / 2.0
        let topBorder = UIView()
        topBorder.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(topBorder)
        topBorder.snp.makeConstraints { (make) in
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-offset)
        }
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { (make) in
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(offset)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutGradientLayer()
    }

    private func layoutGradientLayer() {
        let layerHeight = (bounds.height - SearchDateYearMonthPickerCell.cellHeight) / CGFloat(2)
        topLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: layerHeight)
        bottomLayer.frame = CGRect(x: 0, y: layerHeight + SearchDateYearMonthPickerCell.cellHeight,
                                   width: bounds.width, height: layerHeight)
        topLayer.colors = [UIColor.ud.bgFloat.withAlphaComponent(1.0).cgColor,
                           UIColor.ud.bgFloat.withAlphaComponent(0.0).cgColor]
        bottomLayer.colors = [UIColor.ud.bgFloat.withAlphaComponent(0.0).cgColor,
                              UIColor.ud.bgFloat.withAlphaComponent(1.0).cgColor]
    }

    private func updateCellScale(_ scrollView: UIScrollView) {
        let tableView: UITableView
        if scrollView.isEqual(yearTableView) {
            tableView = yearTableView
        } else if scrollView.isEqual(monthTableView) {
            tableView = monthTableView
        } else {
            tableView = UITableView()
        }
        for cell in tableView.visibleCells {
            if let pickerCell = cell as? SearchDateYearMonthPickerCell {
                let cellHeight = SearchDateYearMonthPickerCell.cellHeight
                let cellY = pickerCell.center.y - tableView.contentOffset.y
                let distance = abs(tableView.center.y - cellY)
                if distance > cellHeight {
                    pickerCell.updateTextLabelTransform(transform: CGAffineTransformMakeScale(Self.minCellScale, Self.minCellScale))
                } else {
                    let scale = Self.minCellScale + (1.0 - Self.minCellScale) * ((cellHeight - distance) / cellHeight)
                    pickerCell.updateTextLabelTransform(transform: CGAffineTransformMakeScale(scale, scale))
                }
            }
        }
    }

    public func stopScrollImmediately() {
        guard yearTableView.isDragging || yearTableView.isDecelerating || monthTableView.isDragging || monthTableView.isDecelerating else { return }
        shouldStopScrollImmediately = true
        yearTableView.setContentOffset(yearTableView.contentOffset, animated: false)
        monthTableView.setContentOffset(monthTableView.contentOffset, animated: false)
        scrollToMiddleCell(yearTableView)
        scrollToMiddleCell(monthTableView)
        shouldStopScrollImmediately = false
    }

    public func updateDefaultSelected(minLimitDate: Date? = nil, maxLimitDate: Date? = nil, year: Int, month: Int) {
        let _minLimitDate = minLimitDate ?? self.minDate
        let _maxLimitDate = maxLimitDate ?? self.maxDate
        if SearchDateYearMonthPickerConfig(minDate: _minLimitDate, maxDate: _maxLimitDate, defaultSelectedYear: year, defaultSelectedMonth: month).isLegal {
            minDate = _minLimitDate
            maxDate = _maxLimitDate
            selectedYear = year
            selectedMonth = month
            yearTableView.reloadData()
            monthTableView.reloadData()
            locateToDefaultSelected()
        } else {
            // 报错
            Self.logger.error("【LarkSearch】updateDefaultSelected is illegal minDate:\(self.minDate) maxDate:\(self.maxDate) year:\(year) month:\(month)")
        }
    }

    private func locateToDefaultSelected() {
        let yearIndexPath = IndexPath(row: self.selectedYear - self.minDate.year + 2, section: 0)
        if yearIndexPath.row >= 0, yearIndexPath.row < yearTableView.numberOfRows(inSection: 0) {
            scrollCellToMiddle(tableView: yearTableView, at: yearIndexPath, animated: false)
            updateCellScale(yearTableView)
        } else {
            Self.logger.error("【LarkSearch】locateToDefaultSelected yearTableView out of bounds minDate:\(self.minDate) maxDate:\(self.maxDate) selectedYear:\(self.selectedYear)")
        }

        let monthIndexPath = IndexPath(row: self.selectedMonth + 1, section: 0)
        if monthIndexPath.row >= 0, monthIndexPath.row < monthTableView.numberOfRows(inSection: 0) {
            scrollCellToMiddle(tableView: monthTableView, at: monthIndexPath, animated: false)
            updateCellScale(monthTableView)
        } else {
            Self.logger.error("【LarkSearch】locateToDefaultSelected monthTableView out of bounds minDate:\(self.minDate) maxDate:\(self.maxDate) selectedYear:\(self.selectedMonth)")
        }
    }

    private func didSelectedDidChange() {
        guard !(yearTableView.isDragging || yearTableView.isDecelerating || monthTableView.isDragging || monthTableView.isDecelerating) else { return }
        var year: Int?
        var month: Int?
        let yearCenter = CGPoint(x: yearTableView.bounds.width / 2, y: yearTableView.contentOffset.y + yearTableView.bounds.height / 2)
        if let indexPath = yearTableView.indexPathForRow(at: yearCenter) {
            year = indexPath.row - 2 + minDate.year
        }

        let monthCenter = CGPoint(x: monthTableView.bounds.width / 2, y: monthTableView.contentOffset.y + monthTableView.bounds.height / 2)
        if let indexPath = monthTableView.indexPathForRow(at: monthCenter) {
            month = indexPath.row - 2 + 1
        }

        if let _year = year, let _month = month {
            selectedYear = _year
            selectedMonth = _month
            yearTableView.reloadData()
            yearTableView.layoutIfNeeded()
            monthTableView.reloadData()
            monthTableView.layoutIfNeeded()
            updateCellScale(yearTableView)
            updateCellScale(monthTableView)
            if _year == minDate.year, _month < minDate.month {
                if minDate.month + 1 >= monthTableView.numberOfRows(inSection: 0) {
                    Self.logger.error("【LarkSearch】didSelectedDidChange monthTableView out of bounds minDate:\(self.minDate) maxDate:\(self.maxDate)")
                } else {
                    scrollCellToMiddle(tableView: monthTableView, at: IndexPath(row: minDate.month + 1, section: 0), animated: true)
                    return
                }
            }
            if _year == maxDate.year, _month > maxDate.month {
                if maxDate.month + 1 >= monthTableView.numberOfRows(inSection: 0) {
                    Self.logger.error("【LarkSearch】didSelectedDidChange monthTableView out of bounds minDate:\(self.minDate) maxDate:\(self.maxDate)")
                } else {
                    scrollCellToMiddle(tableView: monthTableView, at: IndexPath(row: maxDate.month + 1, section: 0), animated: true)
                    return
                }
            }
            selectedChanged?(_year, _month)
        }
    }

    // MARK: UITableViewDelegate & UITableViewDataSource

    // 前后各2个空白cell占位
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEqual(yearTableView) {
            return maxDate.year - minDate.year + 1 + 2 * 2
        } else if tableView.isEqual(monthTableView) {
            return 12 + 2 * 2
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SearchDateYearMonthPickerCell.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchDateYearMonthPickerCell", for: indexPath)
        if let _cell = cell as? SearchDateYearMonthPickerCell {
            if indexPath.row >= 2, indexPath.row < tableView.numberOfRows(inSection: 0) - 2 {
                if tableView.isEqual(yearTableView) {
                    _cell.updateTextLabel(text: "\(minDate.year + indexPath.row - 2)", disable: false)
                } else if tableView.isEqual(monthTableView) {
                    var disable: Bool = false
                    if selectedYear <= minDate.year, indexPath.row - 1 < minDate.month {
                        disable = true
                    }
                    if selectedYear >= maxDate.year, indexPath.row - 1 > maxDate.month {
                        disable = true
                    }
                    _cell.updateTextLabel(text: "\(indexPath.row - 1)", disable: disable)
                }
            } else {
                _cell.updateTextLabel(text: nil, disable: false)
            }
        }
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollToMiddleCell(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollToMiddleCell(scrollView)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didSelectedDidChange()
    }

    func scrollToMiddleCell(_ scrollView: UIScrollView) {
        let tableView: UITableView
        if scrollView.isEqual(yearTableView) {
            tableView = yearTableView
        } else if scrollView.isEqual(monthTableView) {
            tableView = monthTableView
        } else {
            tableView = UITableView()
        }
        let center = CGPoint(x: tableView.bounds.width / 2, y: tableView.contentOffset.y + tableView.bounds.height / 2)
        if let indexPath = tableView.indexPathForRow(at: center) {
            scrollCellToMiddle(tableView: tableView, at: indexPath, animated: true)
        }
        didSelectedDidChange()
    }

    // 将指定位置的cell滚到最中间, 带动画的时候，不延迟100，某些机型上会有偏差
    func scrollCellToMiddle(tableView: UITableView, at indexPath: IndexPath, animated: Bool) {
        tableView.reloadData()
        tableView.layoutIfNeeded()
        let delay = shouldStopScrollImmediately ? 0 : 100
        let realAnimated = shouldStopScrollImmediately ? false : animated
        if shouldStopScrollImmediately {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: realAnimated)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                guard indexPath.row < tableView.numberOfRows(inSection: 0), indexPath.section == 0, !self.shouldStopScrollImmediately else { return }
                tableView.scrollToRow(at: indexPath, at: .middle, animated: realAnimated)
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCellScale(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
