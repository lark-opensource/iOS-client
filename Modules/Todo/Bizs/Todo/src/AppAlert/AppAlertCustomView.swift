//
//  AppAlertCustomView.swift
//  Todo
//
//  Created by 白言韬 on 2020/12/3.
//

import LarkUIKit
import LarkContainer
import UniverseDesignFont

final class AppAlertCustomView: UIView, UserResolverWrapper {

    var height: CGFloat {
        return systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var timeService: TimeService?

    init(resolver: UserResolver, pb: Rust.PushReminder) {
        self.userResolver = resolver
        super.init(frame: .zero)
        let stackView = getStackView()

        if !pb.isAllDay, pb.reminder.type == .relative, pb.reminder.time > 0 {
            let summaryText = Self.getRelativeAlertTitle(minutes: pb.reminder.time, summary: pb.summary)
            stackView.addArrangedSubview(getLabel(text: summaryText))
        } else {
            let title = pb.summary.isEmpty ? I18N.Todo_Task_NoTitlePlaceholder : pb.summary
            let summaryText = I18N.Todo_Task_TaskIs(title)
            stackView.addArrangedSubview(getLabel(text: summaryText))

            let dueTimeText = Utils.DueTime.formatedString(
                from: pb.dueTime,
                in: timeService?.rxTimeZone.value ?? .current,
                isAllDay: pb.isAllDay,
                is12HourStyle: timeService?.rx12HourStyle.value ?? false
            )
            stackView.addArrangedSubview(getLabel(text: I18N.Todo_Task_DueAt2(dueTimeText)))
        }
    }

    private static func getRelativeAlertTitle(minutes: Int64, summary: String) -> String {
        let oneDayMinutes = Int64(24 * 60)

        let days = minutes / oneDayMinutes
        let remainderOfDay = minutes % oneDayMinutes
        let hours = minutes / 60
        let remainderOfHour = minutes % 60
        let title = summary.isEmpty ? I18N.Todo_Task_NoTitlePlaceholder : summary
        if days > 0 && remainderOfDay == 0 {
            return I18N.Todo_Notify_AlertTaskDueInDays(days, title)
        } else if hours > 0 && remainderOfHour == 0 {
            return I18N.Todo_Notify_AlertTaskDueInHours(hours, title)
        } else {
            return I18N.Todo_Notify_AlertTaskDueInMinutes(minutes, title)
        }
    }

    private func getStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return stackView
    }

    private func getLabel(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.text = text
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
