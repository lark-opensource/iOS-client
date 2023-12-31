//
//  EventCalendarViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/24.
//

import UniverseDesignIcon
import LarkUIKit
import RxSwift
import RxCocoa
import LarkContainer
import UIKit
import CTFoundation

/// 日程 - 日历编辑页

protocol EventCalendarViewControllerDelegate: AnyObject {
    func didCancelEdit(from fromVC: EventCalendarViewController)
    func didFinishEdit(from fromVC: EventCalendarViewController)
    /// 日历是否不可用
    func isDisable(_ calendar: EventEditCalendar) -> Bool
    /// 点击回调，true 表示被外部拦截，false 表示继续执行内部逻辑
    func didClick(from fromVC: EventCalendarViewController, _ calendar: EventEditCalendar) -> Bool

    func alertTextsForSelectingCalendar(
        _ calendar: EventEditCalendar,
        from fromVC: EventCalendarViewController
    ) -> EventEditConfirmAlertTexts?
}

final class EventCalendarViewController: BaseUIViewController,
                                         EventEditConfirmAlertSupport,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UserResolverWrapper {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    weak var delegate: EventCalendarViewControllerDelegate?
    internal private(set) var selectedCalendar: EventEditCalendar

    private let disposeBag = DisposeBag()
    private var calendarItems: [EventEditCalendar]
    private var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private let cellReuseId = "Cell"

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    let userResolver: UserResolver
    let externalTag = TagViewProvider.externalNormal

    init(calendar: EventEditCalendar, calendars: [EventEditCalendar], userResolver: UserResolver) {
        selectedCalendar = calendar
        self.userResolver = userResolver
        let nonExchangeCalendars = calendars.filter { $0.source != .exchange }
        // 对 exchange 日程进行归类展示
        let exchangeCalendars = calendars.filter { $0.source == .exchange }
            .sorted { (cal1, cal2) -> Bool in
                if cal1.emailAddress == cal2.emailAddress {
                    return cal1.isPrimary || !cal2.isPrimary
                } else {
                    return cal1.emailAddress <= cal2.emailAddress
                }
            }
        calendarItems = nonExchangeCalendars + exchangeCalendars
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Edit_ChooseCalendar
        setupView()
        bindViewAction()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        tableView.frame = self.view.bounds
        tableView.register(CalendarCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(14)
            $0.left.right.bottom.equalToSuperview()
        }

        let backItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined)
                .scaleNaviSize()
                .renderColor(with: .n1)
                .withRenderingMode(.alwaysOriginal)
        )
        navigationItem.leftBarButtonItem = backItem
    }

    private func bindViewAction() {
        let closeItem = navigationItem.leftBarButtonItem as? LKBarButtonItem
        closeItem?.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }
            .disposed(by: disposeBag)
    }

    // MARK: Tableview deleage
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calendarItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        guard let calendarCell = cell as? CalendarCell else {
            return cell
        }
        let calendar = calendarItems[indexPath.row]
        calendarCell.title = calendar.name
        if case .exchange = calendar.source {
            calendarCell.subtitle = calendar.emailAddress
        } else {
            calendarCell.subtitle = nil
        }
        calendarCell.color = SkinColorHelper.pickerColor(of: calendar.color.rawValue)
        calendarCell.isChecked = calendar == selectedCalendar

        let successorChatterID = calendar.getPBModel().successorChatterID
        let isResigned = !(successorChatterID.isEmpty || successorChatterID == "0") && calendar.getPBModel().type == .other
        calendarCell.isResigned = isResigned

        let flag: UIImage?
        switch calendar.source {
        case .google: flag = UDIcon.getIconByKeyNoLimitSize(.googleColorful)
        case .exchange: flag = UDIcon.getIconByKeyNoLimitSize(.exchangeColorful)
        case .lark:
            flag = nil
            let userTenantId = calendarDependency?.currentUser.tenantId  ?? ""
            let isExternal = calendar.getPBModel().cd.isExternalCalendar(userTenantId: userTenantId)
            calendarCell.isExternal = isExternal
        default: flag = nil
        }
        calendarCell.flag = flag
        if delegate?.isDisable(calendar) ?? false {
            calendarCell.setDisable(true)
        }
        return calendarCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let calendar = calendarItems[indexPath.row]
        if case .exchange = calendar.source {
            return 68
        } else {
            return 52
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let calendar = calendarItems[indexPath.row]
        if delegate?.didClick(from: self, calendar) ?? false {
            return
        }
        let doSelect = { [weak self] in
            guard let self = self else { return }
            self.selectedCalendar = calendar
            self.tableView.reloadData()
            self.delegate?.didFinishEdit(from: self)
        }

        // show alert if needed
        if let alertTexts = delegate?.alertTextsForSelectingCalendar(calendar, from: self) {
            showConfirmAlertController(
                texts: alertTexts,
                confirmHandler: {
                    doSelect()
                }
            )
        } else {
            doSelect()
        }
    }
}

extension EventCalendarViewController {

    final class CalendarCell: UITableViewCell {

        private let innerView = EventEditCellLikeView()
        private let calendarIcon = UDIcon.getIconByKeyNoLimitSize(.calendarLineOutlined)
        private let titleWrapperView = UIView()
        private let titleLabel = UILabel()
        private let flagView = UIImageView()
        private let externalView = TagViewProvider.externalNormal
        private let subtitleLabel = UILabel()
        private let resignedView = TagViewProvider.resignedTagView

        var title: String = "" {
            didSet {
                titleLabel.text = title
            }
        }

        var subtitle: String? {
            didSet {
                let isSubtitleVisible = !(subtitle ?? "").isEmpty
                subtitleLabel.isHidden = !isSubtitleVisible
                subtitleLabel.text = subtitle
                titleLabel.snp.updateConstraints {
                    $0.top.equalToSuperview().offset(isSubtitleVisible ? 13 : 15)
                }
            }
        }

        var flag: UIImage? {
            didSet {
                flagView.image = flag?.withRenderingMode(.alwaysOriginal)
                flagView.isHidden = flag == nil
                if !flagView.isHidden {
                    externalView.isHidden = true
                    resignedView.isHidden = true
                }
                titleLabel.snp.updateConstraints {
                    $0.width.lessThanOrEqualToSuperview().offset(flagView.isHidden ? 0 : -18)
                }
            }
        }

        var isExternal: Bool = false {
            didSet {
                flagView.isHidden = true
                externalView.isHidden = !isExternal
            }
        }

        var isResigned: Bool = false {
            didSet {
                flagView.isHidden = true
                resignedView.isHidden = !isResigned
            }
        }

        var color: UIColor = .clear {
            didSet {
                innerView.icon = .customImageWithoutN3(calendarIcon.ud.withTintColor(color))
                innerView.iconSize = CGSize(width: 18, height: 18)
            }
        }

        var isChecked: Bool = false {
            didSet {
                innerView.accessory = isChecked ? .type(.checkmark) : .none
                titleLabel.textColor = isChecked ? UIColor.ud.functionInfoContentDefault: UIColor.ud.textTitle
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            isChecked = false
            innerView.icon = .none
            innerView.content = .customView(titleWrapperView)
            contentView.addSubview(innerView)
            innerView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            innerView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
            titleLabel.isUserInteractionEnabled = false
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            titleWrapperView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.height.equalTo(22)
                $0.top.equalToSuperview().offset(15)
                $0.width.lessThanOrEqualToSuperview()
            }

            let tagStackView = UIStackView(arrangedSubviews: [externalView, resignedView])
            tagStackView.spacing = 6
            tagStackView.axis = .horizontal
            titleWrapperView.addSubview(tagStackView)
            tagStackView.snp.makeConstraints {
                $0.centerY.equalTo(titleLabel)
                $0.left.equalTo(titleLabel.snp.right).offset(6)
                $0.right.lessThanOrEqualToSuperview().offset(-6)
            }
            resignedView.isHidden = true
            externalView.isHidden = true

            flagView.isUserInteractionEnabled = false
            flagView.isHidden = true
            titleWrapperView.addSubview(flagView)
            flagView.snp.makeConstraints {
                $0.centerY.equalTo(titleLabel)
                $0.left.equalTo(titleLabel.snp.right).offset(4)
                $0.width.height.equalTo(12)
            }

            subtitleLabel.isUserInteractionEnabled = false
            subtitleLabel.isHidden = true
            subtitleLabel.textColor = UIColor.ud.textPlaceholder
            subtitleLabel.font = UIFont.systemFont(ofSize: 14)
            titleWrapperView.addSubview(subtitleLabel)
            subtitleLabel.snp.makeConstraints {
                $0.left.equalTo(titleLabel)
                $0.height.equalTo(20)
                $0.bottom.equalToSuperview().offset(-13)
                $0.width.lessThanOrEqualToSuperview()
            }

            innerView.iconAlignment = .centerYEqualTo(refView: titleLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            isExternal = false
            isResigned = false
            setDisable(false)
        }

        func setDisable(_ disable: Bool) {
            let alpha: CGFloat = disable ? 0.5 : 1
            color = color.withAlphaComponent(alpha)
            titleLabel.textColor = titleLabel.textColor.withAlphaComponent(alpha)
            subtitleLabel.textColor = subtitleLabel.textColor.withAlphaComponent(alpha)
        }
    }

}
