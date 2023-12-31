//
//  EventDetailTableConflictViewComponent.swift
//  Calendar
//
//  Created by huoyunjie on 2023/10/18.
//

import Foundation
import CalendarFoundation
import LarkContainer
import RxSwift
import LarkTimeFormatUtils
import UniverseDesignColor
import UniverseDesignTheme
import RustPB
import LarkTab
import CTFoundation

class EventDetailTableConflictViewComponent: UserContainerComponent {

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var api: CalendarRustAPI?

    var primaryCalendarID: String {
        calendarManager?.primaryCalendarID ?? ""
    }

    private lazy var conflictView = EventDetailTableConflictView()

    private let disposeBag = DisposeBag()

    private let viewModel: EventDetailTableConflictViewModel

    init(viewModel: EventDetailTableConflictViewModel,
                  userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
        conflictView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(conflictView)
        conflictView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        self.bindViewModel()
    }

    private func bindViewModel() {
        viewModel.rxConflictModel
            .observeOn(MainScheduler.asyncInstance)
            .map({ [weak self] model -> EventDetailTableConflictViewData? in
                guard let self = self else { return nil }
                return self.makeViewData(with: model)
            })
            .subscribe(onNext: { [weak self] viewData in
                guard let self = self else { return }
                self.conflictView.viewData = viewData
            }).disposed(by: disposeBag)
    }
}

// MARK: - Make ConflictView ViewData
extension EventDetailTableConflictViewComponent {

    var currentInstance: Rust.Instance? {
        viewModel.currentInstance
    }

    /// 将 model 转换为 viewData
    private func makeViewData(with model: EventConflictModel?) -> EventDetailTableConflictViewData? {
        guard let model = model else { return nil }
        /// 冲突视图应该展示的时间
        let time = model.shouldShowTimeStamp
        let layoutDay = JulianDay(getJulianDay(date: Date(timeIntervalSince1970: TimeInterval(time))))
        /// 构造 viewData
        let getCalendar: (String) -> CalendarModel? = { [weak self] calId in
            self?.calendarManager?.calendar(with: calId)
        }
        let panelRect = conflictView.panelRect
        let viewSetting = SettingService.shared().getSetting()
        let instanceItems = model.layoutedDayInstancesMap[layoutDay]?.compactMap { layoutedInstance -> DayNonAllDayViewModel.InstanceViewData? in
            guard let instance = layoutedInstance.instance as? Instance else { return nil }
            let layout = layoutedInstance.layout
            var textFontsAndLayout: TextFontsAndLayout = defaultFontsAndLayout
            textFontsAndLayout.textFonts = (
                title: UIFont.cd.mediumFont(ofSize: 12),
                subtitle: UIFont.cd.regularFont(ofSize: 10)
            )
            textFontsAndLayout.textLayout.padding.top = 2.5
            
            var semiViewData = DayNonAllDayViewModel.SemiInstanceViewData(
                instance: instance,
                calendar: getCalendar(instance.transformToCalendarEventInstanceEntity().calendarId),
                layout: layout,
                pageDrawRect: panelRect,
                viewSetting: viewSetting,
                textFontsAndLayout: textFontsAndLayout
            )
            
            if model.isConflictInstance(uniqueId: instance.id) {
                /// 冲突日程块适配
                semiViewData.fitConflictInstanceFrame()
                /// frame 缩小影响 padding
                if semiViewData.frame.height < 20 {
                    /// 小于30分钟，尽量让 text 居中
                    textFontsAndLayout.textLayout.padding.top = 1
                } else {
                    textFontsAndLayout.textLayout.padding.top = 2
                }
                
                semiViewData.textFontsAndLayout = textFontsAndLayout
            }
            /// 日程块borderColor替换
            semiViewData.borderColor = self.conflictView.style.bgColor
            return DayNonAllDayViewModel.InstanceViewData(semiViewData: semiViewData)
        }

        let pageViewData = DayNonAllDayViewModel.PageViewData(
            julianDay: layoutDay,
            backgroundColor: UDColor.bgBodyOverlay,
            instanceItems: instanceItems ?? []
        )
        EventDetail.logInfo("conflictViewData instanceItems count: \(instanceItems?.count ?? -1), layoutDay: \(layoutDay)")

        var viewData = EventDetailTableConflictViewData()
        viewData.conflictTimeStr = model.getConflictTimeStr(timezone: viewModel.timezone, eventStartTime: viewModel.model.startTime)
        viewData.conflictTag = model.getConflictText(is12HourStyle: true, startTime: viewModel.model.startTime)
        viewData.showJumpBtn = self.viewModel.isJoined // 未加入日程不展示btn
        viewData.instancesViewData = pageViewData

        return viewData
    }
}

// MARK: - ConflictView Render
extension EventDetailTableConflictViewComponent: EventDetailTableConflictViewDelegate {
    
    func boundsWidthChanged(_ view: EventDetailTableConflictView) {
        /// 重新触发布局计算
        self.viewModel.rxConflictModel.accept(viewModel.rxConflictModel.value)
    }
    
    func getRootView() -> UIView {
        return viewController.view
    }
    
    /// 构造 instance 块view
    func dayView(_ dayView: DayNonAllDayView, instanceViewFor uniqueId: String) -> DayNonAllDayInstanceView {
        let view = DayNonAllDayInstanceView(frame: .zero)
        view.isUserInteractionEnabled = false
        if self.isConflictInstance(uniqueId),
           let instanceData = self.viewModel.getDayInstance(with: uniqueId),
           let viewData = dayView.viewData?.items.first(where: { $0.viewData.uniqueId == uniqueId }) {
            let borderView = UIView()
            view.addSubview(borderView)

            let borderColor: UIColor
            let borderInset: CGFloat
            switch instanceData.selfAttendeeStatus {
            case .accept, .tentative:
                borderColor = viewData.viewData.indicatorInfo?.color ?? .clear
                borderInset = -1.5
            case .decline:
                borderColor = UDColor.N500
                borderInset = -1.5
            case .needsAction:
                borderColor = viewData.viewData.dashedBorderColor ?? .clear
                borderInset = 1
            default:
                borderColor = .clear
                borderInset = 0
            }

            borderView.layer.borderWidth = 1.5
            borderView.layer.cornerRadius = 5
            borderView.layer.ud.setBorderColor(borderColor)
            /// needsAction 不添加阴影
            if instanceData.selfAttendeeStatus != .needsAction {
                view.clipsToBounds = false
                view.sendSubviewToBack(borderView)
                borderView.backgroundColor = UDColor.bgFloat
                borderView.layer.ud.setShadowColor(borderColor.withAlphaComponent(0.5))
                borderView.layer.shadowOpacity = 1
                borderView.layer.shadowOffset = .zero
            }
            
//            if let opacity = viewData.viewData.maskOpacity {
//                borderView.layer.opacity = opacity
//            }
            borderView.snp.makeConstraints { make in
                make.top.bottom.leading.trailing.equalToSuperview().inset(borderInset)
            }
            return view
        }
        return view
    }

    /// 判断是否为冲突日程块
    func isConflictInstance(_ uniqueId: String) -> Bool {
        viewModel.rxConflictModel.value.isConflictInstance(uniqueId: uniqueId)
    }

    /// 是否展示时间线
    func isShowTimeLine(_ view: EventDetailTableConflictView) -> Bool {
        let julianDay = view.viewData?.instancesViewData?.julianDay ?? 0
        let date = getDate(julianDay: Int32(julianDay))
        return date.isInSameDay(Date())
    }

    func is12HourStyle() -> Bool {
        return viewModel.is12HourStyle
    }

    /// 跳转至日历视图
    func onJumpAction(_ view: EventDetailTableConflictView) {
        guard view.viewData?.showJumpBtn == .some(true) else {
            assertionFailure("no show jump btn, but click btn")
            return
        }
        userResolver.navigator.switchTab(Tab.calendar.url, from: self.viewController, animated: false) { [weak self] _ in
            guard let self = self,
                  let calendarHome = try? self.userResolver.resolve(assert: CalendarHome.self) else {
                assertionFailure("UserResolver resolve CalendarHome failed")
                return
            }
            var time = self.viewModel.model.startTime
            let conflictModel = self.viewModel.rxConflictModel.value
            if conflictModel.conflictType != .none,
               let conflictTime = conflictModel.conflictTime {
                time = conflictTime
            }
            let date = Date(timeIntervalSince1970: TimeInterval(time))
            calendarHome.jumpToCalendarWithDateAndType(date: date, type: nil, toTargetTime: true)
        }
    }
    
    func dayView(_ dayView: DayNonAllDayView, tapIconDidTap instanceView: DayNonAllDayInstanceView, with uniqueId: String, isSelected: Bool) {}

    func dayView(_ dayView: DayNonAllDayView, didTap instanceView: DayNonAllDayInstanceView, with uniqueId: String) {}

    func dayView(_ dayView: DayNonAllDayView, didUnload instanceView: DayNonAllDayInstanceView) {}

}

fileprivate extension DayNonAllDayViewModel.SemiInstanceViewData {
    /// 适配冲突日程块的样式，frame 缩小
    mutating func fitConflictInstanceFrame() {
        switch instance.selfAttendeeStatus {
        case .accept, .decline, .tentative:
            frame = frame.insetBy(dx: 2, dy: 2)
        default: return
        }
    }
}
