//
//  MonthInnerListView.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import RxSwift
import LarkInteraction
import LarkContainer
private let bgColor = UIColor.ud.N200

protocol MonthInnerListViewDelegate: AnyObject {
    func innerListView(_ view: MonthInnerListView, didScrollTo index: Int)
    func innerListView(_ view: MonthInnerListView, didDidSelectAt item: MonthEventItem)
    func innerListViewCreateActionTaped(_ view: MonthInnerListView)
}

final class MonthInnerListView: UIView {
    weak var delegate: MonthInnerListViewDelegate?
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: self.bounds,
                                    collectionViewLayout: layout)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutCollectionView(collectionView)
    }

    private var events: [[MonthEventItem]] = []
    private var dates: [Date] = []
    var localRefreshService: LocalRefreshService?

    func updateBlocks(_ events: [MonthItem],
                      index: Int,
                      dates: [Date],
                      is12HourStyle: Bool) {
        var reusltEvents = [[MonthEventItem]]()
        self.dates = dates
        for date in dates {
            let items = events
                .filter({ $0.isBelongsTo(startTime: date.dayStart(), endTime: date.dayEnd()) })
                .sorted(by: { (item1, item2) -> Bool in
                    TimeBlockUtils.sortBlock(lhs: item1.transfromToSortModel(), rhs: item2.transfromToSortModel())
                })
                .compactMap { (item) -> MonthEventItem? in
                    item.process { type in
                        switch type {
                        case .event(let monthEvent):
                            return MonthEventItemModel(eventViewSetting: monthEvent.eventViewSetting,
                                                       instance: monthEvent.instance,
                                                       calendar: monthEvent.calendar,
                                                       date: date,
                                                       is12HourStyle: is12HourStyle)
                        case .timeBlock(let timeBlcokModel):
                            return MonthTimeBlockItemModel(eventViewSetting: timeBlcokModel.eventViewSetting,
                                                           timeBlock: timeBlcokModel.timeBlock,
                                                           date: date,
                                                           is12HourStyle: is12HourStyle)
                        case .none:
                            return nil
                        }
                    }
                }
            reusltEvents.append(items)
        }
        self.events = reusltEvents
        self.collectionView.reloadData()
        self.scroll(to: index)
    }

    func scroll(to index: Int, animated: Bool = false) {
        let indexPath = IndexPath(row: index, section: 0)
        self.collectionView.scrollToItem(at: indexPath,
                                         at: .left,
                                         animated: animated)
    }

    private func layoutCollectionView(_ view: UICollectionView) {
        view.frame = self.bounds
        self.addSubview(view)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isPagingEnabled = true
        let bgView = UIView()
        bgView.backgroundColor = bgColor
        view.backgroundView = bgView
        view.showsHorizontalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = UIColor.ud.bgBody
        view.register(MonthInnerListViewPage.self,
                      forCellWithReuseIdentifier: "Cell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MonthInnerListView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.events.count
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let navigationType: CalendarTracer.CalNavigationParam.NavigationType = velocity.x > 0 ? .next : .prev
        CalendarTracer.shareInstance.calNavigation(actionSource: .defaultView,
                                                   navigationType: navigationType,
                                                   viewType: .month)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexOfPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        self.delegate?.innerListView(self, didScrollTo: indexOfPage)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.frame.size
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                      for: indexPath)

        let events = self.events[indexPath.row]
        if let page = cell as? MonthInnerListViewPage {
            page.date = self.dates[indexPath.row]
            page.events = events
            page.localRefreshService = self.localRefreshService
            page.selectCallBack = { [unowned self] item in
                self.delegate?.innerListView(self, didDidSelectAt: item)
            }
            page.createCallBack = { [unowned self] in
                self.delegate?.innerListViewCreateActionTaped(self)
            }
        }
        return cell
    }
}

private final class MonthInnerListViewPage: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    var localRefreshService: LocalRefreshService?
    private let tableView = UITableView()
    private let disposeBag = DisposeBag()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutTableView(tableView)
        self.backgroundColor = bgColor

        localRefreshService?.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.updateRedline()
            })
            .disposed(by: disposeBag)
    }

    private let redLine = EventListRedLine(leading: 38, tailing: 16)

    var createCallBack: (() -> Void)? {
        didSet {
            emptyView.createCallBack = createCallBack
        }
    }

    private lazy var emptyView: MonthEmptyView = {
        let emptyView = MonthEmptyView(frame: self.bounds)
        self.contentView.addSubview(emptyView)
        emptyView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return emptyView
    }()

    var date: Date = Date()
    var events: [MonthEventItem] = [] {
        didSet {
            self.emptyView.isHidden = !events.isEmpty
            self.tableView.isHidden = events.isEmpty
            self.tableView.reloadData()
            self.updateRedline()
            DispatchQueue.main.async {
                if self.date.isInSameDay(Date()), let position = self.redLinePosition(cellItems: self.events) {
                    self.tableView.scrollToRow(at: position.indexPathToScrollsTop(), at: .top, animated: false)
                }
            }
        }
    }

    var selectCallBack: ((MonthEventItem) -> Void)?

    private var contentSizeKVOHandel: NSKeyValueObservation?
    private func layoutTableView(_ view: UITableView) {
        view.frame = self.bounds
        self.contentView.addSubview(view)
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.delegate = self
        view.dataSource = self
        view.showsVerticalScrollIndicator = false
        view.separatorStyle = .none
        view.backgroundColor = bgColor
        view.scrollsToTop = false
        view.rowHeight = MonthBlockCell.Config.cellHeight
        view.register(MonthBlockCell.self, forCellReuseIdentifier: "Cell")
        contentSizeKVOHandel = tableView.observe(\.contentSize, options: [.old, .new]) { [weak self] (_, values) in
            guard let oldSize = values.oldValue, let newSize = values.newValue else { return }
            guard newSize != oldSize else { return }
            self?.tableViewContentSizeChanged()
        }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 3))
        view.tableHeaderView = header
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 3))
        view.tableFooterView = footer
    }

    deinit {
        contentSizeKVOHandel?.invalidate()
    }

    private func tableViewContentSizeChanged() {
        guard tableView.numberOfSections > 0 else {
            return
        }
        self.updateRedline()
    }

    private func clearRedLine() {
        self.redLine.removeFromSuperview()
    }

    private func updateRedline() {
        guard self.date.isInSameDay(Date()) else {
            self.clearRedLine()
            return
        }
        // 加入判断拦截条件
        guard let position = self.redLinePosition(cellItems: self.events) else {
            self.clearRedLine()
            return
        }
        let cellRect = tableView.rectForRow(at: position.indexPath)
        if position.isUpSide {
            self.redLine.updateOriginY(cellRect.origin.y - self.redLine.bounds.height / 2.0, tableView: tableView)
        } else {
            self.redLine.updateOriginY(cellRect.origin.y + cellRect.size.height - self.redLine.bounds.height - self.redLine.bounds.height / 2.0,
                                       tableView: tableView)
        }

    }

    private func redLinePosition(cellItems: [MonthEventItem]) -> RedlinePositionInfo? {
        let currentTime = Date()
        var result: RedlinePositionInfo?
        var redPostionStartDate: Date?
        for i in 0..<cellItems.count {
            let item = cellItems[i]
            if item.isAllDay {
                result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                             isUpSide: false,
                                             isFirst: i == 0,
                                             isEvent: true)
            } else if currentTime >= item.endTime {
                result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                             isUpSide: false,
                                             isFirst: i == 0,
                                             isEvent: true)
                redPostionStartDate = nil
            } else if currentTime >= item.startTime {
                if redPostionStartDate != item.startTime {
                    result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                                 isUpSide: true,
                                                 isFirst: i == 0,
                                                 isEvent: true)
                    redPostionStartDate = item.startTime
                }
            } else if result == nil {
                result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                             isUpSide: true,
                                             isFirst: i == 0,
                                             isEvent: true)
            }
        }
        return result
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }

    let throttler = Throttler(delay: 1)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let event = self.events[safeIndex: indexPath.row] {
            throttler.call { [weak self] in
                operationLog(optType: CalendarOperationType.monthDetail.rawValue)
                self?.selectCallBack?(event)
            }
        } else {
            normalErrorLog("Index out of range")
        }

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? MonthBlockCell else {
            assertionFailureLog()
            return UITableViewCell()
        }
        let event = events[indexPath.row]
        cell.item = event
        return cell
    }
}

final class MonthBlockCell: UITableViewCell {
    struct Config {
        static let cellHeight: CGFloat = 52.0
        static let leftIconSize: CGFloat = 14
        static let leftIconTopPadding: CGFloat = 10.5
        static let labelLeftTopRightPadding: CGFloat = 6
        static let leftIconLeftPadding: CGFloat = 41
        static let subLabelLeftPadding: CGFloat = 41
        static let colorBlockSize = CGSize(width: 7, height: 7)
        static let iconSize: CGFloat = 14
    }

    private let colorBlock = UIView(frame: CGRect(origin: .init(x: 19, y: 14), size: Config.colorBlockSize))

    private let titleLabel = UILabel()
    private let leftIconView = UIImageView()
    private let subLabel = UILabel()
    private let icon = UIImageView()
    private let coverView = InstanceCoverView()

    var item: MonthEventItem? {
        didSet {
            guard let item else { return }
            self.updateLayerTask {
                self.update(with: item)
            }
        }
    }

    private func update(with item: MonthEventItem) {
        self.titleLabel.attributedText = item.title
        self.subLabel.attributedText = item.subTitle
        self.colorBlock.layer.ud.setBorderColor(item.color)
        self.colorBlock.layer.cornerRadius = item.colorBlockCornerRadius
        if item.isSolid {
            self.colorBlock.layer.borderWidth = self.colorBlock.frame.width / 2.0
        } else {
            self.colorBlock.layer.borderWidth = 2.0
        }
        self.coverView.update(with: item.endTime, isCoverPassEvent: item.isCoverPassEvent, maskOpacity: CGFloat(item.maskOpacity))
        self.leftIconView.image = item.leftIcon
        leftIconView.snp.updateConstraints { make in
            make.width.equalTo(item.leftIcon == nil ? 0 : Config.leftIconSize)
        }
        titleLabel.snp.updateConstraints { (make) in
            make.left.equalTo(leftIconView.snp.right).offset(item.leftIcon == nil ? 0 : Config.labelLeftTopRightPadding)
        }
        self.icon.image = item.icon?.withRenderingMode(.alwaysTemplate)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layoutIcon(icon)
        self.layoutLeftIconView(leftIconView)
        self.layoutBlockView(colorBlock)
        self.layoutTitleLabel(titleLabel, icon: icon, leftIconView: leftIconView)
        self.layoutSubLabel(subLabel, titleLabel: titleLabel)
        self.addSubview(coverView)
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        let view = UIView()
        view.backgroundColor = UIColor.ud.fillPressed
        self.selectedBackgroundView = view
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
//        coverView.frame = self.contentView.bounds
    }

    private func layoutBlockView(_ view: UIView) {
        self.contentView.addSubview(view)
        view.layer.cornerRadius = 1.0
    }

    private func layoutIcon(_ icon: UIImageView) {
        self.contentView.addSubview(icon)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        icon.tintColor = UIColor.ud.textDisabled
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.top.equalToSuperview().offset(10.5)
            make.right.equalToSuperview().offset(-15)
        }
    }
    
    private func layoutLeftIconView(_ icon: UIImageView) {
        self.contentView.addSubview(icon)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        icon.snp.makeConstraints { (make) in
            make.width.equalTo(0)
            make.height.equalTo(Config.leftIconSize)
            make.top.equalTo(Config.leftIconTopPadding)
            make.left.equalTo(Config.leftIconLeftPadding)
        }
    }

    private func layoutSubLabel(_ label: UILabel, titleLabel: UILabel) {
        self.contentView.addSubview(label)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.N600
        label.font = UIFont.cd.regularFont(ofSize: 12)
        let height = label.font.lineHeight
        label.snp.makeConstraints { (make) in
            make.left.equalTo(Config.subLabelLeftPadding)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(height)
        }
    }

    private func layoutTitleLabel(_ label: UILabel, icon: UIView, leftIconView: UIView) {
        self.contentView.addSubview(label)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = UIColor.ud.N800
        label.font = UIFont.cd.mediumFont(ofSize: 14)
        let height = label.font.lineHeight
        label.snp.makeConstraints { (make) in
            make.left.equalTo(leftIconView.snp.right).offset(Config.labelLeftTopRightPadding)
            make.centerY.equalTo(leftIconView.snp.centerY)
            make.height.equalTo(height)
            make.right.lessThanOrEqualTo(icon.snp.left).offset(-5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MonthEventItem {
    var color: UIColor { get set }
    var isSolid: Bool { get set }
    var title: NSAttributedString { get set }
    var subTitle: NSAttributedString { get set }
    var originalModel: BlockDataProtocol { get set }
    var colorBlockCornerRadius: CGFloat { get }
    var startTime: Date { get set }
    var endTime: Date { get set }
    var leftIcon: UIImage? { get set }
    var icon: UIImage? { get set }
    var isCoverPassEvent: Bool { get set }
    var isAllDay: Bool { get }
    var maskOpacity: Float { get set }
}
