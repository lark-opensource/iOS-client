//
//  CalendarMeetingRoomSwitchView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/4/28.
//

import UniverseDesignIcon
import UIKit
import RxCocoa
import RxSwift
import LarkGuide
import LarkContainer

final class CalendarMeetingRoomSwitchView: UIControl, UserResolverWrapper {

    let userResolver: UserResolver
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    enum Entry: Equatable {
        static func == (lhs: CalendarMeetingRoomSwitchView.Entry, rhs: CalendarMeetingRoomSwitchView.Entry) -> Bool {
            switch (lhs, rhs) {
            case (.calendar, .calendar):
                return true
            case (.meetingRoom, .meetingRoom):
                return true
            default:
                return false
            }
        }

        struct Context {
            let title: String
        }

        var title: String {
            switch self {
            case let .calendar(context), let .meetingRoom(context):
                return context.title
            }
        }

        case calendar(Context)
        case meetingRoom(Context)
    }

    private(set) var entries: [Entry]
    var currentSelected: Entry {
        didSet {
            buttons.forEach { $0.isSelected = false }
            switch currentSelected {
            case let .calendar(context), let .meetingRoom(context):
                guard let selectedButton = buttons.first(where: { $0.attributedTitle(for: .normal)?.string == context.title }) else {
                    return
                }
                selectedButton.isSelected = true
                selectedIndicatorView.snp.remakeConstraints { make in
                    make.leading.trailing.equalTo(selectedButton)
                    make.bottom.equalToSuperview()
                    make.height.equalTo(2)
                }
                UIView.animate(withDuration: 0.2) {
                    self.layoutIfNeeded()
                }
            }
            slideViewButton.isHidden = (currentSelected != .calendar(.init(title: "")))
        }
    }

    fileprivate(set) var slideViewButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.calendarViewOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n2), for: .normal)
        return button
    }()

    private var buttons = [UIButton]()
    private var selectedIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryContentDefault
        return view
    }()

    private var sepline: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private var stackview = UIStackView()

    // 暴露出去定位引导气泡
    var meetingRoomEntryButton: UIView? {
        if let index = entries.firstIndex(of: .meetingRoom(.init(title: ""))),
           index < stackview.arrangedSubviews.count {
            return stackview.arrangedSubviews[index]
        }
        return nil
    }

    init(userResolver: UserResolver, entries: [Entry], defaultEntry: Entry) {
        self.entries = entries
        currentSelected = defaultEntry
        self.userResolver = userResolver
        assert(!entries.isEmpty)
        assert(entries.contains(defaultEntry))

        super.init(frame: .zero)

        let entryButtons = entries.map { entry -> UIButton in
            switch entry {
            case let .calendar(context), let .meetingRoom(context):
                let button = UIButton(type: .custom)
                button.setAttributedTitle(NSAttributedString(string: context.title, attributes: [
                    .font: UIFont.ud.body2(.fixed),
                    .foregroundColor: UIColor.ud.textCaption
                ]), for: .normal)
                button.setAttributedTitle(NSAttributedString(string: context.title, attributes: [
                    .font: UIFont.ud.body1(.fixed),
                    .foregroundColor: UIColor.ud.primaryContentDefault
                ]), for: .selected)
                _ = button.rx.tap
                    .subscribe(onNext: { [weak self] in
                        if self?.currentSelected != entry {
                            switch entry {
                            case .calendar:
                                CalendarTracer.shared.calendarMeetingRoomSwitcherActions(action: .calendarView)
                            case .meetingRoom:
                                CalendarTracer.shared.calendarMeetingRoomSwitcherActions(action: .meetingRoomView)
                            }
                        }
                        self?.currentSelected = entry
                        self?.sendActions(for: .valueChanged)
                    })
                if entry == defaultEntry { button.isSelected = true }
                return button
            }
        }

        let stackview = UIStackView(arrangedSubviews: entryButtons)
        addSubview(stackview)
        stackview.axis = .horizontal
        stackview.distribution = .equalSpacing
        stackview.spacing = 24
        stackview.alignment = .trailing
        stackview.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(6)
        }
        self.stackview = stackview

        addSubview(sepline)
        sepline.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        addSubview(selectedIndicatorView)
        if let selectedButton = entryButtons.first(where: \.isSelected) {
            selectedIndicatorView.snp.remakeConstraints { make in
                make.leading.trailing.equalTo(selectedButton)
                make.bottom.equalToSuperview()
                make.height.equalTo(2)
            }
        }

        addSubview(slideViewButton)
        slideViewButton.snp.makeConstraints { make in
            make.centerY.equalTo(stackview)
            make.trailing.equalToSuperview().inset(20)
        }
        slideViewButton.hitTestEdgeInsets = .init(edges: -8)
        slideViewButton.isHidden = (defaultEntry != .calendar(.init(title: "")))
        slideViewButton.badgeInit()
        slideViewButton.setBadgeStyle(.redDot)
        slideViewButton.setBadgeSize(CGSize(width: 6, height: 6))
        slideViewButton.setRedDotColor(UIColor.ud.colorfulRed)

        self.buttons = entryButtons
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectedIndicatorView.cd.roundCorners(corners: [.topLeft, .topRight], radius: 2)
        if let newGuideManager = newGuideManager {
            slideViewButton.changeStatus(GuideService.isGuideNeedShow(newGuideManager: newGuideManager,
                                                                      key: .calendarOptimizeRedDotKey) ? .show : .hidden)
        }
    }

}

extension Reactive where Base: CalendarMeetingRoomSwitchView {
    var selectedEntry: ControlProperty<CalendarMeetingRoomSwitchView.Entry> {
        base.rx.controlProperty(editingEvents: .valueChanged,
                                getter: { base in
                                    base.currentSelected
                                }, setter: { base, new in
                                    base.currentSelected = new
                                })
    }

    var slideViewButtonSelected: ControlEvent<Void> {
        base.slideViewButton.rx.tap
    }
}
