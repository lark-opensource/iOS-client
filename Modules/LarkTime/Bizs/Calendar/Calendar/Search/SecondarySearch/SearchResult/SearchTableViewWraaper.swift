//
//  SearchTableViewWraaper.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/11.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import UniverseDesignTheme
import LarkContainer
import UniverseDesignEmpty

final class SearchTableViewWraaper: UIView {
    private let localRefreshService: LocalRefreshService?
    private let loader: SearchDataLoader
    private let tableView = UITableView(frame: UIScreen.main.bounds)
    private let redLine = EventListRedLine()
    private let disposeBag = DisposeBag()
    private var noResultView = EmptyStatusView()
    var onItemSelected: ((SearchCellData) -> Void)?

    private var dateViewDic: [Date: UIView] = [:]

    init(loader: SearchDataLoader, localRefreshService: LocalRefreshService?) {
        self.loader = loader
        self.localRefreshService = localRefreshService
        super.init(frame: .zero)
        registerCells()
        self.clipsToBounds = true
        setUpTableview()

        addSubview(noResultView)
        noResultView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(115)
        }

        self.localRefreshService?.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.updateRedline()
            })
            .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerCells() {
        tableView.register(SearchTableViewCell.self, forCellReuseIdentifier: SearchTableViewCell.identifier)
        tableView.register(WeekCell.self, forCellReuseIdentifier: WeekCell.identifier)
        tableView.register(MonthCell.self, forCellReuseIdentifier: MonthCell.identifier)
    }

    private func setUpTableview() {
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.scrollsToTop = false
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
    }

    @objc
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            self.viewController()?.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }

    func reloadTable(isEmptyQuery: Bool) {
        if loader.getData().isEmpty {
            tableView.isHidden = true
            noResultView.isHidden = false
            noResultView.showStatus(with: .noSearchResult)
        } else {
            tableView.isHidden = false
            noResultView.isHidden = true
        }
        tableView.reloadData()
        DispatchQueue.main.async {
            self.updateHeadersLocations(isReload: true)
            self.updateRedline()
            if isEmptyQuery {
                self.scrollToToday()
            } else {
                self.scrollToLastFinishInstance()
            }
        }
    }

    private func scrollToToday(animated: Bool = false) {
        guard let position = self.redlinePosition() else {
            return
        }
        tableView.scrollToRow(at: position.indexPathToScrollsTop(), at: .top, animated: animated)
    }
    // 搜索结果滚动到上一个已结束的日程
    private func scrollToLastFinishInstance() {
        let data = loader.getData()
        var scrollToIndex: Int
        if let index = data.firstIndex(where: { $0.endDate > Date() }) {
            scrollToIndex = index - 1

        } else {
            scrollToIndex = data.count - 1
        }
        if scrollToIndex > 0 {
            tableView.scrollToRow(at: IndexPath(row: scrollToIndex, section: 0), at: .top, animated: false)
        }
    }
}

extension SearchTableViewWraaper {
    private func clearRedLine() {
        self.redLine.removeFromSuperview()
    }

    private func updateRedline() {
        guard let position = self.redlinePosition() else {
            self.redLine.redlinePosition = nil
            self.clearRedLine()
            return
        }
        self.redLine.redlinePosition = position
        self.updateRedlinePosition(redline: self.redLine,
                                   position: position,
                                   tableView: self.tableView)
    }

    private func redlinePosition() -> RedlinePositionInfo? {
        let cellItems = loader.getData()
        let currentTime = Date()
        let dayEnd = currentTime.dayEnd()
        var result: RedlinePositionInfo?
        // 上一个item的content & index
        var lastEventData: (content: SearchCellProtocol & SearchInstanceViewContent, index: Int)?
        var firstIndexOfToday: Int?
        for i in 0..<cellItems.count {
            let item = cellItems[i]
            guard item.cellType == .event else { continue }
            guard item.belongingDate.isInSameDay(currentTime) else { continue }
            if item.belongingDate > dayEnd { break }
            if firstIndexOfToday == nil {
                firstIndexOfToday = i
            }

            // startTime & endTime的日程，红线在上一个日程上方，略过
            if lastEventData?.content.startDate == item.startDate &&
                lastEventData?.content.endDate == item.endDate &&
                result?.indexPath.row == lastEventData?.index &&
                result?.isUpSide == true {
                continue
            }

            // 这个实现的产品逻是：多个日程叠加的时候，当下一个日程开始时间=当前时间的时候，红线从跳转到下一个日程的前面
            // PRD: https://docs.bytedance.net/doc/3ZHvanyrafk3tmcSw5RJHd
            // EventA 10:00 - 11:30
            // EventB 10:20 - 10:40
            // 10：00 之前在 A上方；10: 00 - 10: 20在B上方；10：20 - 10：40在B上方；大于10：40在B下方
            // 因为红线不能往回跳，所以只需要判断上一个event而不用判断上一个未结束的event
            if let last = lastEventData, currentTime < last.content.endDate, currentTime < item.startDate {
                return RedlinePositionInfo(indexPath: IndexPath(row: last.index, section: 0),
                                           isUpSide: true,
                                           isFirst: last.index == firstIndexOfToday,
                                           isEvent: true)
            }

            // 开始时间大于当前时间的event，红线在event上方
            if item.startDate > currentTime {
                return RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                           isUpSide: true,
                                           isFirst: i == firstIndexOfToday,
                                           isEvent: true)
            }

            // 没找到继续向下遍历,当前event没结束红线就在上面，结束了红线就在下面
            result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                         isUpSide: item.endDate > currentTime,
                                         isFirst: i == firstIndexOfToday,
                                         isEvent: true)
            lastEventData = (item, i)
        }

        return result
    }

    private func updateRedlinePosition(redline: EventListRedLine,
                                       position: RedlinePositionInfo,
                                       tableView: UITableView) {
        let cellItems = loader.getData()
        let item = cellItems[position.indexPath.row]
        let cellRect = tableView.rectForRow(at: position.indexPath)
        var eventRect: CGRect = .zero

        eventRect = CGRect(x: 57,
                           y: 0,
                           width: 0,
                           height: item.height)
        if eventRect != .zero {
            var y: CGFloat = 0.0
            if position.isUpSide {
                y = cellRect.minY
            } else {
                y = cellRect.maxY
            }
            redline.updateOriginY(y - redline.bounds.size.height / 2.0, tableView: tableView)
        } else {
            redline.removeFromSuperview()
        }
    }
}

extension SearchTableViewWraaper: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return loader.getData()[indexPath.row].height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return loader.getData()[indexPath.row].height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loader.getData().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = loader.getData()[indexPath.row]
        switch item.cellType {
        case .event:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchTableViewCell.identifier) as? SearchTableViewCell else {
                return UITableViewCell()
            }
            cell.update(with: item)
            cell.backgroundColor = .ud.bgBody
            return cell
        case .weekTitle:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: WeekCell.identifier) as? WeekCell else {
                return UITableViewCell()
            }
            cell.updateText(item.titleText)
            cell.backgroundColor = .ud.bgBody
            return cell
        case .monthTitle:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MonthCell.identifier) as? MonthCell else {
                return UITableViewCell()
            }
            cell.updateText(item.titleText)
            cell.backgroundColor = .ud.bgBody
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = loader.getData()[safeIndex: indexPath.row],
            item.cellType == .event {
            onItemSelected?(item)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateRedline()
        updateHeadersLocations()
    }
}

extension SearchTableViewWraaper {
    func updateHeadersLocations(isReload: Bool = false) {
        if isReload {
            for (date, view) in dateViewDic {
                view.removeFromSuperview()
                dateViewDic[date] = nil
            }
        }
        let headerSize = CGSize(width: 57, height: 17 + 31)
        let rectDic = generateRectDic()

        var needRemovedViewList = dateViewDic

//        第二步: 针对各个“section“作出处理
        for (date, value) in rectDic {
            let height = value.maxY - value.minY
            let fakeSectionRect = CGRect(x: 0, y: value.minY, width: tableView.bounds.width, height: height)
            let rect = tableView.convert(fakeSectionRect, to: tableView.superview)
            var viewFrame = CGRect.zero
            viewFrame.size = headerSize
            viewFrame.origin.x = 0

            let tableViewTop = tableView.frame.minY + 1

            if rect.minY >= tableViewTop {
                viewFrame.origin.y = rect.origin.y
            } else if rect.maxY >= tableViewTop {
                viewFrame.origin.y = tableViewTop
            } else if rect.maxY < tableViewTop {
                viewFrame.origin.y = rect.maxY
            }

            var view = dateViewDic[date]
            needRemovedViewList[date] = nil
            if viewFrame.maxY <= tableView.frame.minY || viewFrame.minY >= tableView.frame.maxY {
                if view != nil {
                    view?.removeFromSuperview()
                    dateViewDic[date] = nil
                }
            } else if view == nil {
                let newView = SquareDateView(item: value)
                tableView.superview?.addSubview(newView)
                dateViewDic[date] = newView
                view = newView
            }
            view?.frame = viewFrame
        }

        // 第三步: 清理没用的view
        for (date, view) in needRemovedViewList {
            view.removeFromSuperview()
            dateViewDic[date] = nil
        }
    }

    func generateRectDic() -> [Date: SquareDateViewLocationInfo] {
        var rectDic: [Date: SquareDateViewLocationInfo] = [:]
        let cellItems = loader.getData()
        // 第一步：得到各个“section”的区间范围以及日期。
        let indexs = tableView.indexPathsForVisibleRows
        var minIndex = indexs?.first?.row ?? 10
        var maxIndex = indexs?.last?.row ?? cellItems.count - 11
        minIndex -= 10
        maxIndex += 10
        minIndex = max(minIndex, 0)
        maxIndex = min(maxIndex, cellItems.count)
        minIndex = min(minIndex, maxIndex) // 防止滑动过快导致outofrange
        for i in minIndex..<maxIndex {
            let content = cellItems[i]
            if content.cellType != .event {
                continue
            }
            let date = content.belongingDate
            let cellRectTop = tableView.rectForRow(at: IndexPath(row: i, section: 0)).minY
            if var rect = rectDic[date] {
                if rect.minY > cellRectTop {
                    rect.minY = cellRectTop
                }
                if rect.maxY < cellRectTop {
                    rect.maxY = cellRectTop
                }
                rectDic[date] = rect
            } else {
                rectDic[date] = SquareDateViewLocationInfo(minY: cellRectTop,
                                                           maxY: cellRectTop,
                                                           eventDate: date)
            }
        }
        return rectDic
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.viewController()?.view.endEditing(true)
    }
}
