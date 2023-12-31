//
//  MonthEventContainer.swift
//  Calendar
//
//  Created by zhouyuan on 2018/10/25.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import LarkUIKit
import LarkInteraction
import LarkContainer

private final class Style {
    static let maxColum = 7
    static let rowHeight: CGFloat = Display.pad ? 20 : 16.0
    static let rowGap: CGFloat = 2.5
    static let rightPadding: CGFloat = 4.5
    static let moreLabelHeight: CGFloat = 22
}

protocol MonthEventContainerDelegate: AnyObject {
    func dateSelected(container: MonthEventContainer, index: Int, date: Date, isRepeat: Bool)
}

// 时间块cell模型
class MonthTimeBlockViewCellModel: MonthBlockViewCellProtocol {
    var id: String
    var icon: UIImage?
    var range: AllDayEventRange
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var titleText: String
    var strikethroughColor: UIColor
    var indicatorInfo: (color: UIColor, isStripe: Bool)? = nil
    var hasStrikethrough: Bool
    var stripBackgroundColor: UIColor? = nil
    var stripLineColor: UIColor? = nil
    var dashedBorderColor: UIColor?
    var startDate: Date
    var endDate: Date
    var startTime: Int64
    var endTime: Int64
    var startDay: Int32
    var endDay: Int32
    var userInfo: [String : Any] = [:]
    var isCoverPassEvent: Bool
    var maskOpacity: Float
    var isAllDay: Bool

    init(eventViewSetting: EventViewSetting,
         timeBlock: TimeBlockModel,
         fromJulianDay: Int32,
         toJulianDay: Int32) {
        self.id = timeBlock.id
        self.hasStrikethrough = timeBlock.taskBlockModel?.isCompleted == true
        self.titleText = InstanceBaseFunc.getTitleFromModel(model: timeBlock)
        let startDate = timeBlock.startDate
        let endDate = timeBlock.endDate
        self.startDate = startDate
        self.endDate = endDate
        self.startTime = timeBlock.startTime
        self.endTime = timeBlock.endTime
        self.startDay = timeBlock.startDay
        self.endDay = timeBlock.endDay
        self.isAllDay = timeBlock.isAllDay
        let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: timeBlock))
        let iconColor = skinColorHelper.indicatorInfo?.color ?? skinColorHelper.eventTextColor
        let isLightScene = skinColorHelper.skinType == .light
        let normalColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
        let selectedColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
        let image = TimeBlockUtils.getIcon(model: timeBlock, isLight: isLightScene, color: normalColor, selectedColor: selectedColor)
        self.icon = image
        self.backgroundColor = skinColorHelper.backgroundColor
        self.foregroundColor = TimeBlockUtils.getTitleColor(helper: skinColorHelper, model: timeBlock)
        self.strikethroughColor = skinColorHelper.eventTextColor.withAlphaComponent(0.7)
        self.dashedBorderColor = skinColorHelper.dashedBorderColor
        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        self.maskOpacity = TimeBlockUtils.getMaskOpacity(helper: skinColorHelper, model: timeBlock)
        self.range = MonthInstanceViewCellModel.getBlockShowRange(fromJulianDay: fromJulianDay,
                                                                  toJulianDay: toJulianDay,
                                                                  model: timeBlock)
    }
}

class MonthInstanceViewCellModel: MonthBlockViewCellProtocol {
    var id: String
    var icon: UIImage? { nil }
    var isCoverPassEvent: Bool = false
    var maskOpacity: Float
    var instanceId: String
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var strikethroughColor: UIColor = .ud.textPlaceholder
    var titleText: String
    var indicatorColor: UIColor?
    var indicatorInfo: (color: UIColor, isStripe: Bool)?
    var hasStrikethrough: Bool = false
    var stripBackgroundColor: UIColor?
    var stripLineColor: UIColor?
    var dashedBorderColor: UIColor?
    var startDate: Date
    var endDate: Date
    var startTime: Int64
    var endTime: Int64
    var startDay: Int32
    var endDay: Int32
    var range: AllDayEventRange
    var userInfo: [String: Any]
    var isAllDay: Bool

    init(eventViewSetting: EventViewSetting,
         instance: CalendarEventInstanceEntity,
         calendar: CalendarModel?,
         fromJulianDay: Int32,
         toJulianDay: Int32) {
        self.id = instance.uniqueId
        self.instanceId = instance.id
        self.userInfo = ["instance": instance, "calendar": calendar as Any]
        self.titleText = InstanceBaseFunc.getTitleFromModel(model: instance,
                                                            calendar: calendar)
        self.startDate = instance.startDate
        self.startDay = instance.startDay
        self.endDate = instance.endDate
        self.endDay = instance.endDay
        self.startTime = instance.startTime
        self.endTime = instance.endTime
        self.isAllDay = instance.isAllDay
        let skinColorHelper = SkinColorHelper(skinType: eventViewSetting.skinTypeIos, insInfo: .init(from: instance))
        let selfStatus = instance.selfAttendeeStatus

        if instance.displayType == .undecryptable {
            // 加密秘钥失效日程，特别设置
            self.backgroundColor = UIColor.ud.N200
            self.foregroundColor = UIColor.ud.textCaption
        } else if instance.isCreatedByMeetingRoom.strategy || instance.isCreatedByMeetingRoom.requisition {
            // 会议室自己创建的日程需要特别设置颜色
            self.backgroundColor = UIColor.ud.bgBodyOverlay
            self.foregroundColor = UIColor.ud.textCaption
        } else {
            self.backgroundColor = skinColorHelper.backgroundColor
            self.foregroundColor = skinColorHelper.eventTextColor
        }

        if instance.displayType != .undecryptable {
            // 配置底色条纹
            if let stripeColors = skinColorHelper.stripeColor {
                self.stripLineColor = stripeColors.foreground
                self.stripBackgroundColor = stripeColors.background
            }
            self.hasStrikethrough = selfStatus == .decline
        }

        self.indicatorInfo = skinColorHelper.indicatorInfo
        self.dashedBorderColor = skinColorHelper.dashedBorderColor

        self.isCoverPassEvent = eventViewSetting.showCoverPassEvent
        self.maskOpacity = skinColorHelper.maskOpacity
        self.range = MonthInstanceViewCellModel.getBlockShowRange(fromJulianDay: fromJulianDay,
                                                                  toJulianDay: toJulianDay,
                                                                  model: instance)
    }

    static func getBlockShowRange(fromJulianDay: Int32,
                                  toJulianDay: Int32,
                                  model: BlockDataProtocol) -> (Int, Int) {
        if model.startDay <= fromJulianDay {
            if model.endDay >= toJulianDay {
                return (start: 0, long: 7) // 目前最长显示7天的
            }
            if model.endDay < toJulianDay {
                return (start: 0, long: Int(model.endDay - fromJulianDay + 1))
            }
        } else {
            if model.endDay >= toJulianDay {
                return (start: Int(model.startDay - fromJulianDay),
                        long: Int(toJulianDay - model.startDay + 1))
            }
            if model.endDay < toJulianDay {
                return (start: Int(model.startDay - fromJulianDay),
                        long: Int(model.endDay - model.startDay + 1))
            }
        }
        return (0, 0)
    }
}

final class MonthEventContainer: UIControl {

    private let rectangleControls: [RectangleControl] = {
        var arr = [RectangleControl]()
        (0..<Style.maxColum).forEach({ (_) in
            arr.append(RectangleControl())
        })
        return arr
    }()

    weak var delegate: MonthEventContainerDelegate?
    private let instanceWrapper = UIView()

    let calendarSelectTracer: CalendarSelectTracer?
    private let cellPool = Pool<MonthBlockViewCell>()
    private var models: [MonthBlockViewCellProtocol]?
    private var startDate: Date?

    override var frame: CGRect {
        didSet {
            if frame != oldValue && frame != .zero {
                instanceWrapper.subviews.forEach { (view) in
                    // cannot get correct height when preload view. need to reset isHidden while frame changed
                    view.isHidden = view.frame.maxY > frame.size.height
                }
            }
        }
    }

    init(calendarSelectTracer: CalendarSelectTracer?) {
        self.calendarSelectTracer = calendarSelectTracer
        super.init(frame: .zero)
        self.addSubview(instanceWrapper)
        self.rectangleControls.forEach { (control) in
            self.addSubview(control)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(models: [MonthBlockViewCellProtocol], startDate: Date) -> [Int] {
        let sortedModels = models.sorted { (l, r) -> Bool in
            TimeBlockUtils.sortBlock(lhs: l.transfromToSortModel(), rhs: r.transfromToSortModel())
        }
        self.models = sortedModels
        self.startDate = startDate
        let moreNumbers = layoutCells(models: sortedModels, startDate: startDate)
        layoutRectangleControls()
        self.rectangleControls.enumerated().forEach { (index, control) in
            control.didTap = { [weak self, weak control] (isRepeat) in
                guard let `self` = self, let control = control else { return }
                self.delegate?.dateSelected(container: self, index: index,
                                            date: (startDate + index.day)!,
                                            isRepeat: isRepeat)
                self.rectangleControls.forEach({ (itemControl) in
                    if itemControl !== control {
                        itemControl.showArrowView(show: false)
                    }
                })
            }
        }
        return moreNumbers
    }

    func unselected() {
        self.rectangleControls.forEach { (control) in
            control.showArrowView(show: false)
        }
    }

    func setSelected(index: Int) {
        self.rectangleControls.enumerated().forEach { (controlIndex, control) in
            control.showArrowView(show: index == controlIndex)
        }
    }

    private static func cleanlyLayoutCheckerboard(maxRow: Int) -> [[Bool]] {
        return Array(repeating: Array(repeating: false, count: Style.maxColum),
                     count: maxRow)
    }

    func clear() {
        self.models = nil
        self.clearEventCell()
    }

    private func clearEventCell() {
        instanceWrapper.subviews.forEach { (view) in
            if let MonthBlockViewCell = view as? MonthBlockViewCell {
                MonthBlockViewCell.removeFromSuperview()
                cellPool.returnObject(MonthBlockViewCell)
            }
        }
    }

    private func layoutCells(models: [MonthBlockViewCellProtocol], startDate: Date) -> [Int] {
        self.instanceWrapper.frame = self.bounds
        self.clearEventCell()
        let maxRow = Int((self.bounds.height + Style.rowGap) / (Style.rowHeight + Style.rowGap))
        var layoutCheckerboard = MonthEventContainer.cleanlyLayoutCheckerboard(maxRow: maxRow)

        models.forEach { (model) in
            let (frame, layout) = cellFrame(layoutCheckerboard: layoutCheckerboard, model: model)
            layoutCheckerboard = layout
            if let frame = frame {
                let cell = cellView(model: model)
                cell.frame = frame
                instanceWrapper.addSubview(cell)
            }
        }

        // 所有cell更新后作为埋点end更准确
        calendarSelectTracer?.end()
        CalendarMonitorUtil.endTrackHomePageLoad()

        return getMoreCount(startDate: startDate,
                            layoutCheckerboard: layoutCheckerboard,
                            models: models,
                            maxRow: maxRow)
    }

    func layoutRectangleControls() {
        self.rectangleControls.enumerated().forEach { (index, control) in
            let width = self.bounds.width / CGFloat(Style.maxColum)
            control.frame = CGRect(x: CGFloat(index) * width, y: 0,
                                   width: width, height: self.bounds.height)
        }
    }

    private func getMoreCount(startDate: Date,
                              layoutCheckerboard: [[Bool]],
                              models: [MonthBlockViewCellProtocol],
                              maxRow: Int) -> [Int] {
        let startDay = getJulianDay(date: startDate)
        var result = [Int]()
        (0..<Style.maxColum).forEach { (colum) in
            var showedCount = 0
            (0..<maxRow).forEach({ (row) in
                if layoutCheckerboard[row][colum] {
                    showedCount += 1
                }
            })
            let dayCount = getMonthBlockCount(by: startDay + Int32(colum), models: models)
            if dayCount > showedCount {
                result.append(dayCount - showedCount)
            } else {
                result.append(0)
            }
        }
        return result
    }

    private func getMonthBlockCount(by day: Int32, models: [MonthBlockViewCellProtocol]) -> Int {
        var count = 0
        models.forEach { (model) in
            if !(model.startDay > day || model.endDay < day) {
                count += 1
            }
        }
        return count
    }

    private func cellFrame(layoutCheckerboard: [[Bool]],
                           model: MonthBlockViewCellProtocol) -> (CGRect?, [[Bool]]) {

        var layoutBoard = layoutCheckerboard
        if let index = layoutBoard.firstIndex(where: { (array) -> Bool in
            guard let result = array[safeIndex: model.range.start] else { return false }
            return !result
        }) {
            (0..<model.range.long).forEach { (offset) in
                layoutBoard[index][model.range.start + offset] = true
            }
            let y = CGFloat(index) * (Style.rowHeight + Style.rowGap)
            let rowWidth = self.bounds.width / CGFloat(Style.maxColum)
            return (CGRect(x: rowWidth * CGFloat(model.range.start),
            y: y,
            width: rowWidth * CGFloat(model.range.long) - Style.rightPadding,
            height: Style.rowHeight), layoutBoard)
        }
        return (nil, layoutBoard)
    }

    private func cellView(model: MonthBlockViewCellProtocol) -> MonthBlockViewCell {
        let cell = cellPool.borrowObject()
        cell.updateContent(model: model)
        cell.isHidden = false
        return cell
    }
}

private final class RectangleControl: UIView {

    private static let image = UDIcon.getIconByKeyNoLimitSize(.upOutlined).renderColor(with: .n1).withRenderingMode(.alwaysOriginal)
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = RectangleControl.image
        return imageView
    }()

    private let grayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay.withAlphaComponent(0.92)
        return view
    }()

    var isSelected: Bool {
        return !self.grayView.isHidden
    }

    var didTap: ((_ isRepeat: Bool) -> Void)?

    init() {
        super.init(frame: .zero)
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(clicked))
        self.addGestureRecognizer(tapGesture)
        self.addSubview(grayView)
        grayView.addSubview(imageView)
        grayView.isHidden = true
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        grayView.frame = self.bounds
        imageView.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        imageView.center = grayView.center
    }

    @objc
    private func clicked() {
        showArrowView(show: self.grayView.isHidden)
        self.didTap?(!isSelected)
    }

    func showArrowView(show: Bool) {
        self.grayView.isHidden = !show
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
