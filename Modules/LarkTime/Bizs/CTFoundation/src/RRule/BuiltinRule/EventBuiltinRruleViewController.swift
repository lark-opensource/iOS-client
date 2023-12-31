//
//  EventBuiltinRruleViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/26.
//

import LarkUIKit
import RxSwift
import RxCocoa
import UIKit
import EventKit

/// 日程 - 重复性规则编辑页

public protocol EventBuiltinRruleViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventBuiltinRruleViewController)
    func didFinishEdit(from viewController: EventBuiltinRruleViewController)
    func selectCustomRrule(from viewController: EventBuiltinRruleViewController)
    func parseRruleToTitle(rrule: EKRecurrenceRule, timezone: String) -> String?
    func parseRruleToTitle(rrule: EKRecurrenceRule) -> String?
}

public extension EventBuiltinRruleViewControllerDelegate {
    func parseRruleToTitle(rrule: EKRecurrenceRule, timezone: String) -> String? {
        parseRruleToTitle(rrule: rrule)
    }
}

public final class EventBuiltinRruleViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloat)
    }

    public weak var delegate: EventBuiltinRruleViewControllerDelegate?
    public private(set) var selectedRrule: EKRecurrenceRule?

    private let disposeBag = DisposeBag()
    private var availableRules: [EKRecurrenceRule?] = []
    private var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private let rRuleId = "RruleCell"
    private let customRruleId = "CustomCell"
    private let showNoRrule: Bool
    public var eventTimezoneId: String?

    // 内置 rules
    private let builtinRules = [
        EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil),
        EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil),
        EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil),
        EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil),
        EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            daysOfTheWeek: [
                EKRecurrenceDayOfWeek(.monday),
                EKRecurrenceDayOfWeek(.tuesday),
                EKRecurrenceDayOfWeek(.wednesday),
                EKRecurrenceDayOfWeek(.thursday),
                EKRecurrenceDayOfWeek(.friday)
            ],
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
    ]

    public init(rrule: EKRecurrenceRule?) {
        selectedRrule = rrule?.copy() as? EKRecurrenceRule
        showNoRrule = true
        super.init(nibName: nil, bundle: nil)
    }

    public init(rrule: EKRecurrenceRule?, showNoRepeat: Bool) {
        selectedRrule = rrule?.copy() as? EKRecurrenceRule
        showNoRrule = showNoRepeat
        super.init(nibName: nil, bundle: nil)
    }

    // 更新规则并刷新页面
    public func updateRRuleAndReload(_ rule: EKRecurrenceRule?) {
        selectedRrule = rule
        setupAvailableRules()
        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.RRule.Calendar_Edit_ChooseRepeat
        setupAvailableRules()
        setupView()
        tableView.reloadData()
    }

    public override func viewWillAppear(_ animate: Bool) {
        super.viewWillAppear(animate)
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        }
    }

    private func setupAvailableRules() {
        var availableRules = builtinRules
        if let rule = selectedRrule {
            if !availableRules.contains(where: { self.isSame(between: $0, and: rule) }) {
                availableRules.append(rule)
            }
        }
        if showNoRrule {
            self.availableRules = [nil] + availableRules
        } else {
            self.availableRules = availableRules
        }
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgFloat

        tableView.frame = self.view.bounds
        tableView.backgroundColor = .clear
        tableView.register(RuleCell.self, forCellReuseIdentifier: rRuleId)
        tableView.register(CustomRruleCell.self, forCellReuseIdentifier: customRruleId)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // section 0: rules
    // section 1: custom rule
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 14 : 29
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let view = UIView()
            view.backgroundColor = .ud.bgFloat
            return view
        } else {
            let view = UIView()
            let divide = UILabel()
            divide.backgroundColor = UIColor.ud.lineDividerDefault
            view.addSubview(divide)
            divide.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
                make.leading.equalToSuperview().inset(16)
                make.trailing.equalToSuperview()
            }
            return view
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? availableRules.count : 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: rRuleId, for: indexPath)
            guard let ruleCell = cell as? RuleCell else {
                return cell
            }

            if let rule = availableRules[safeIndex: indexPath.row],
               let rrule = rule {
                ruleCell.title = self.titleForRrule(rrule, timezone: self.eventTimezoneId ?? "")
                if let selectedRrule = selectedRrule, self.isSame(between: rrule, and: selectedRrule) {
                    ruleCell.isChecked = true
                } else {
                    ruleCell.isChecked = false
                }
            } else {
                // 不重复
                ruleCell.title = BundleI18n.RRule.Calendar_Detail_NoRepeat
                ruleCell.isChecked = selectedRrule == nil
            }
            return ruleCell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: customRruleId, for: indexPath)
            guard let customCell = cell as? CustomRruleCell else {
                return cell
            }
            return customCell
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if indexPath.section == 0 {
            selectedRrule = availableRules[safeIndex: indexPath.row] ?? .init()
            tableView.reloadData()
            delegate?.didFinishEdit(from: self)
        } else {
            if #available(iOS 13.0, *) {
                isModalInPresentation = true
            }
            delegate?.selectCustomRrule(from: self)
        }
    }
}

extension EventBuiltinRruleViewController {
    final class RuleCell: CalendarCornerCell {
        var innerView = EventBasicCellLikeView()
        var title: String = "" {
            didSet {
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title)
                innerView.content = .title(titleContent)
            }
        }

        var isChecked: Bool = false {
            didSet {
                innerView.accessory = isChecked ? .type(.checkmark) : .none
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title,
                                                                       color: isChecked ? UIColor.ud.functionInfoContentDefault: UIColor.ud.textTitle)
                innerView.content = .title(titleContent)
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .ud.bgFloat
            selectionStyle = .none
            isChecked = false
            innerView.icon = .none
            contentView.addSubview(innerView)
            innerView.backgroundColors = (UIColor.ud.bgFloat, UIColor.ud.bgFloat)
            innerView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class CustomRruleCell: CalendarCornerCell {
        var innerView = EventBasicCellLikeView()
        var title: String = "" {
            didSet {
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title)
                innerView.content = .title(titleContent)
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            contentView.addSubview(innerView)
            innerView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            innerView.backgroundColors = (UIColor.ud.bgFloat, UIColor.ud.bgFloat)
            innerView.content = .title(.init(text: BundleI18n.RRule.Calendar_Edit_CustomRepeat))
            innerView.accessory = .type(.next)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

}

extension EventBuiltinRruleViewController {

    // 判断两个 rrule 是否相同
    private func isSame(
        between r0: EKRecurrenceRule,
        and r1: EKRecurrenceRule
    ) -> Bool {
        return titleForRrule(r0, timezone: "") == titleForRrule(r1, timezone: "")
    }

    // 返回 rule 的「重复性描述」（不包括结束时间）
    private func titleForRrule(_ rrule: EKRecurrenceRule, timezone: String) -> String {
        guard let title = delegate?.parseRruleToTitle(rrule: rrule, timezone: timezone) else {
            assertionFailure()
            return ""
        }
        return title
    }
}
