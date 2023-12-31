//
//  ArrangementPanel.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/19.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import ThreadSafeDataStructure
import LarkUIKit

protocol ArrangementPanelDelegate: AnyObject {
    func timeChanged(_ arrangementPanel: ArrangementPanel, startTime: Date, endTime: Date)

    /// 点击cell 改变frame
    /// - Parameters:
    ///   - newFrame: 新的frame
    ///   - superView: interval 的父view 用于外面转换坐标
    func intervalFrameChangedByClick(newFrame: CGRect, superView: UIView)

    func intervalStateChanged(_ arrangementPanel: ArrangementPanel,
                              isHidden: Bool,
                              instanceMap: InstanceMap)
    func jumpToEventDetailVC(_ detailVC: UIViewController)
}

enum LoadingState {
    case notStarted
    case loading
    case success
    case failed
}

private let uselessScreenWidthPlaceholder: CGFloat = 1000

final class ArrangementPanel: UIView {

    final class Style {
        static let viewSize = CGSize(width: uselessScreenWidthPlaceholder,
                                     height: Style.wholeDayHeight)
        static let wholeDayHeight = CalendarViewStyle.Background.wholeDayHeight
        static let topGridMargin = CalendarViewStyle.Background.topGridMargin
        static let hourGridHeight = CalendarViewStyle.Background.hourGridHeight
    }

    weak var delegate: ArrangementPanelDelegate?
    
    var arrangementCellClickCallBack: ((_ instance: RoomViewInstance) -> Void)?
   
    private let containerView = UIView()
    private let reactionView = ReactionInteractView()
    private var calendarIds: [String] = ["0"]
    private var calendarInstanceMap: InstanceMap = [:]
    private var workingHoursTimeRangeMap: [String: [WorkingHoursTimeRange]] = [:]
    private var privateCalMap: [String: Bool] = [:]

    private let timeLineView = CalendarTimeLineView()

    private lazy var collectionView: UICollectionView = {
        let frame = CGRect(origin: CGPoint(x: timeIndicator.bounds.width, y: 0),
                           size: CGSize(width: containerWidth,
                                        height: Style.wholeDayHeight))

        let collectionView = UICollectionView(frame: frame, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(ArrangementPanelCell.self,
                                forCellWithReuseIdentifier: ArrangementPanelCell.reuseKey)
        collectionView.bounces = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        cellWidth = calculateCellWidth()
        flowLayout.itemSize = CGSize(width: cellWidth, height: Style.wholeDayHeight)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = flowLayout.itemSize
        return flowLayout
    }()

    private var cellWidth: CGFloat = 0

    private var intervalCoodinator: IntervalCoodinator
    private var timeIndicator: TimeIndicator {
        return intervalCoodinator.timeIndicator
    }
    private var intervalIndicator: IntervalIndicator {
        return intervalCoodinator.intervalIndicator
    }
    private var startTime: Date {
        return intervalCoodinator.startTime
    }

    private var containerWidth: CGFloat = uselessScreenWidthPlaceholder

    var loadingState: SafeAtomic<LoadingState> = .notStarted + .readWriteLock

    private var uiCurrentDate = Date()

    init(intervalCoodinator: IntervalCoodinator) {

        self.intervalCoodinator = intervalCoodinator
        super.init(frame: CGRect(origin: .zero, size: Style.viewSize))
        collectionView.delegate = self
        collectionView.dataSource = self

        addSubview(timeIndicator)
        layoutContainerView(containerView, superView: self)
        addSubview(collectionView)
        layoutReactionView(reactionView, superView: self)
        setupTimeLine(timeLineView, superView: reactionView, date: startTime)
        layoutIntervalIndicator(intervalIndicator, superView: reactionView)
        self.intervalCoodinator.timeChanged = { [weak self] (startTime, endTime) in
            guard let `self` = self else { return }
            self.delegate?.timeChanged(self, startTime: startTime, endTime: endTime)
        }
        self.intervalCoodinator.intervalStateChanged = { [weak self] (isHidden) in
            guard let `self` = self else { return }
            self.delegate?.intervalStateChanged(self,
                                                isHidden: isHidden,
                                                instanceMap: self.calendarInstanceMap)
        }
    }

    func relayout(newWidth: CGFloat) {
        let newWidth = newWidth - timeIndicator.bounds.width
        containerWidth = newWidth
        intervalCoodinator.containerWidth = newWidth
        intervalIndicator.frame.size.width = newWidth
        let newCellWidth = calculateCellWidth(width: newWidth)
        if cellWidth != newCellWidth {
            setUpLayout(cellWidth: newCellWidth, collectionView: collectionView)
        }
        calendarInstanceMap = reCalc(calendarInstanceMap, panelWidth: newCellWidth)

        collectionView.frame = CGRect(origin: CGPoint(x: timeIndicator.bounds.width, y: 0),
                                      size: CGSize(width: containerWidth,
                                                   height: Style.wholeDayHeight))
        collectionView.reloadData()

    }

    func setCollectinPanGesturePriorityLower(than ges: UIGestureRecognizer) {
        collectionView.panGestureRecognizer.require(toFail: ges)
    }

    private func setupTimeLine(_ timeLine: CalendarTimeLineView, superView: UIView, date: Date) {
        superView.addSubview(timeLine)
        updateTimerLineFrame()
    }

    func updateTimerLineFrame() {
        timeLineView.isHidden = !startTime.isInSameDay(uiCurrentDate)
        timeLineView.frame = CGRect(
            x: 0,
            y: yOffsetWithDate(uiCurrentDate,
                               inTheDay: uiCurrentDate,
                               totalHeight: Style.hourGridHeight * 24,
                               topIgnoreHeight: 0,
                               bottomIgnoreHeight: 0) - 2.5,
            width: containerWidth,
            height: 5)
    }

    func updateCurrentUiDate(uiDate: Date) {
        uiCurrentDate = uiDate
        updateTimerLineFrame()
    }

    func intervalIndicatorFrame() -> CGRect {
        return intervalIndicator.frame
    }

    func horizontalScrollView() -> UIScrollView {
        return self.collectionView
    }

    func reloadView(calendarIds: [String],
                    calendarInstanceMap: InstanceMap,
                    workingHoursTimeRangeMap: [String: [WorkingHoursTimeRange]],
                    privateCalMap: [String: Bool]) {
        self.calendarIds = calendarIds
        if self.calendarIds.isEmpty {
            self.calendarIds = [""]
        }

        self.calendarInstanceMap = calendarInstanceMap
        self.workingHoursTimeRangeMap = workingHoursTimeRangeMap
        self.privateCalMap = privateCalMap

        collectionView.reloadData()

        let width = calculateCellWidth()
        if cellWidth != width {
            setUpLayout(cellWidth: width, collectionView: collectionView)
        }
    }

    func cleanInstance(calendarIds: [String], startTime: Date, endTime: Date) {
        self.calendarIds = calendarIds
        self.calendarInstanceMap = [:]
        intervalCoodinator.changeTime(startTime: startTime, endTime: endTime)
        updateTimerLineFrame()
        collectionView.reloadData()
    }

    private func layoutContainerView(_ containerView: UIView, superView: UIView) {
        let frame = CGRect(x: timeIndicator.bounds.width,
                           y: 0,
                           width: containerWidth,
                           height: Style.wholeDayHeight)
        containerView.frame = frame
        superView.addSubview(containerView)
    }

    private func layoutReactionView(_ reactionView: ReactionInteractView, superView: UIView) {
        reactionView.frame = CGRect(x: timeIndicator.bounds.width,
                                    y: Style.topGridMargin,
                                    width: containerWidth,
                                    height: Style.hourGridHeight * 24)
        superView.addSubview(reactionView)
    }

    private func layoutIntervalIndicator(_ intervalIndicator: IntervalIndicator,
                                         superView: UIView) {
        intervalIndicator.delegate = self
        superView.addSubview(intervalIndicator)
    }

    func moveCellToLeft(indexPath: IndexPath) {
        guard calendarIds.indices.contains(indexPath.row) else {
            assertionFailureLog()
            return
        }
        let calendarId = calendarIds.remove(at: indexPath.row)
        calendarIds.insert(calendarId, at: 0)
        // 规避iOS14的bug
        collectionViewLayout.estimatedItemSize = .zero
        collectionView.collectionViewLayout = collectionViewLayout
        collectionView.moveItem(at: indexPath, to: IndexPath(row: 0, section: 0))
        collectionViewLayout.estimatedItemSize = collectionViewLayout.itemSize
        collectionView.collectionViewLayout = collectionViewLayout
    }

    private func setUpLayout(cellWidth: CGFloat,
                             collectionView: UICollectionView) {
        self.cellWidth = cellWidth
        collectionViewLayout.itemSize = CGSize(width: cellWidth, height: Style.wholeDayHeight)
        collectionViewLayout.estimatedItemSize = collectionViewLayout.itemSize
        collectionView.collectionViewLayout = collectionViewLayout
    }

    private func calculateCellWidth(width: CGFloat? = nil) -> CGFloat {
        let is12HourStyle = timeIndicator.is12HourStyle
        let count = calendarIds.count
        var maxCellCntPerScreen = count >= 5 ? 5 : count
        if maxCellCntPerScreen <= 0 {
            maxCellCntPerScreen = 1
        }
        let cellWidth: CGFloat
        if let width = width {
            cellWidth = width / CGFloat(maxCellCntPerScreen)
        } else {
            cellWidth = containerWidth / CGFloat(maxCellCntPerScreen)
        }

        if is12HourStyle {
            return max(80, cellWidth)
        } else {
            return cellWidth
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reCalc(_ contentMap: InstanceMap?, panelWidth: CGFloat) -> InstanceMap {
        var newMap: InstanceMap = [:]
        guard let map = contentMap else {
            return newMap
        }

        let size = CGSize(width: panelWidth,
                           height: Style.hourGridHeight * 24)
        let layoutConvert = InstanceLayoutConvert()
        map.forEach({ (key: String, value: [DaysInstanceViewContent]) in
            var newValue: [DaysInstanceViewContent] = []
            value.forEach { (content) in
                var newContent = content
                if let layout = content.instancelayout {
                    newContent.frame = layoutConvert.layoutToFrame(layout: layout, panelSize: size, index: content.index)
                    newValue.append(newContent)
                } else {
                    newValue.append(newContent)
                }
            }
            newMap[key] = newValue
        })
        return newMap
    }

}

extension ArrangementPanel: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return calendarIds.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let view =
            collectionView.dequeueReusableCell(withReuseIdentifier: ArrangementPanelCell.reuseKey,
                                               for: indexPath)
        guard let arrangementViewCell = view as? ArrangementPanelCell,
            indexPath.row < calendarIds.count else {
            return view
        }
        
        arrangementViewCell.instanceViewClickCallBack = { [weak self] instance in
            guard let self = self else { return }
            self.arrangementCellClickCallBack?(instance)
        }
        
        let calendarId = calendarIds[indexPath.row]
        let eventViewModels = calendarInstanceMap[calendarId]
        let workingHoursTimeRanges = workingHoursTimeRangeMap[calendarId]
        let isCalPrivate = privateCalMap[calendarId]
        arrangementViewCell.updateContent(eventViewModels: eventViewModels ?? [],
                                          workingHoursTimeRanges: workingHoursTimeRanges,
                                          hasNoPermission: isCalPrivate ?? false)
        arrangementViewCell.didClick = { [weak self] (sender) in
            guard let `self` = self else {
                return
            }
            if let gestureView = sender.view {
                let location = sender.location(in: gestureView)
                self.intervalCoodinator.changeFrameBy(point: location,
                                                      maxY: self.reactionView.frame.height,
                                                      animated: true,
                                                      completion: { (frame) in
                    self.delegate?.intervalFrameChangedByClick(newFrame: frame,
                                                               superView: self.reactionView)
                })
            }
        }
        return arrangementViewCell
    }
}

extension ArrangementPanel: IntervalIndicatorDelegate {

    func inticatorLimitedRect(_ inticator: IntervalIndicator) -> CGRect {
        return reactionView.bounds
    }

    func inticator(_ inticator: IntervalIndicator, moveEnded newFrame: CGRect) {
        intervalCoodinator.setStartEndTimeBy(newFrame, isMoveEnd: true, containerWidth: containerWidth)
    }

    func inticator(_ inticator: IntervalIndicator,
                   originFrame: CGRect,
                   didMoveTo newFrame: CGRect,
                   frameChangeKind: FrameChangeKind) {
        intervalCoodinator.setStartEndTimeBy(newFrame, isMoveEnd: false, containerWidth: containerWidth)
    }
}
