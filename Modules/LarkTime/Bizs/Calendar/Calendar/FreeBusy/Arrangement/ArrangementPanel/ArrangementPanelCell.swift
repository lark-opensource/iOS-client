//
//  ArrangementPanelCell.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/19.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import LarkContainer
import EENavigator
import UniverseDesignColor

struct WorkingHoursTimeRange {
    var startMinute: Int32
    var endMinute: Int32
}
final class ArrangementPanelCell: UICollectionViewCell {
    static let reuseKey = "ArrangementPanelCell"
    typealias Style = CalendarViewStyle.Background
    private let daysInstanceViewPool = Pool<DaysInstanceView>()
    
    var didClick: ((UITapGestureRecognizer) -> Void)?
    var instanceViewClickCallBack: ((_ instance: RoomViewInstance) -> Void)?

    private var workingHoursTimeRanges: [WorkingHoursTimeRange]? {
        didSet {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0,
                            y: Style.topGridMargin,
                            width: self.bounds.width,
                            height: Style.hourGridHeight * 24)
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(onTouchView(sender:)))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
        return view
    }()

    private lazy var privateCover: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgFiller
        return view
    }()
    
    private let workingHoursView = UIView()
    private let timeScaleView = TimeScaleView(frame: .zero, daysCount: 1, pandingTop: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        
        configSubViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        workingHoursView.subviews.forEach { $0.removeFromSuperview() }
        guard let workingHoursTimeRanges = self.workingHoursTimeRanges else {
            workingHoursView.backgroundColor = UIColor.ud.bgBody
            return
        }
        workingHoursView.backgroundColor = UIColor.ud.N100
        workingHoursTimeRanges.forEach { (timeRange) in
            let view = UIView()
            view.backgroundColor = UIColor.ud.bgBody
            let hourMinuteHeight = Style.hourGridHeight / 60
            view.frame = CGRect(
                x: 0,
                y: CGFloat(timeRange.startMinute) * hourMinuteHeight,
                width: bounds.width,
                height: CGFloat(timeRange.endMinute - timeRange.startMinute) * hourMinuteHeight
            )
            workingHoursView.addSubview(view)
        }
    }

    private func configSubViews() {
        addSubview(workingHoursView)
        addSubview(containerView)
        containerView.addSubview(timeScaleView)

        workingHoursView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(Style.topGridMargin)
            make.bottom.equalToSuperview().offset(-Style.bottomGridMargin)
        }
        
        containerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Style.topGridMargin)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Style.bottomGridMargin)
        }
        
        timeScaleView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    @objc
    func onTouchView(sender: UITapGestureRecognizer) {
        didClick?(sender)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.subviews.forEach { (view) in
            if let instanceView = view as? DaysInstanceView {
                instanceView.removeFromSuperview()
                daysInstanceViewPool.returnObject(instanceView)
            }
        }
    }

    func updateContent(eventViewModels: [DaysInstanceViewContent],
                       workingHoursTimeRanges: [WorkingHoursTimeRange]?,
                       hasNoPermission: Bool) {
        if hasNoPermission {
            addSubview(privateCover)
            privateCover.snp.makeConstraints { make in
                make.edges.equalTo(containerView.snp.edges).inset(-1)
            }
        } else {
            privateCover.removeFromSuperview()
            eventViewModels.forEach { (content) in
                let instanceView = daysInstanceViewPool.borrowObject()
                instanceView.updateContent(content: content)
                instanceView.isUserInteractionEnabled = (content.userInfo["instance"] as? RoomViewInstance)?.canEdit() ?? false
                instanceView.didClicked = { [weak self] _ in
                    guard let self = self else { return }
                    if let content = content as? ArrangementInstanceModel,
                       let instance = content.userInfo["instance"] as? RoomViewInstance {
                        self.instanceViewClickCallBack?(instance)
                        CalendarTracer.shared.meetingRoomFreeBusyActions(meetingRoomCalendarID: instance.calendarId, action: .goDetailView)
                    }
                }
                containerView.addSubview(instanceView)
            }
            self.workingHoursTimeRanges = workingHoursTimeRanges
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
