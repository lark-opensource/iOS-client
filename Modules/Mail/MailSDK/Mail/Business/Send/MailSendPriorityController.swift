//
//  MailSendPriorityController.swift
//  MailSDK
//
//  Created by Ender on 2023/8/28.
//

import Foundation
import LarkUIKit
import FigmaKit
import UniverseDesignCheckBox
import UniverseDesignIcon

protocol MailSendPriorityDelegate: AnyObject {
    func updatePriority(_ priority: MailPriorityType)
}

class MailSendPriorityController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    private weak var delegate: MailSendPriorityDelegate?
    private var priority: MailPriorityType

    init(delegate: MailSendPriorityDelegate, priority: MailPriorityType) {
        self.delegate = delegate
        self.priority = priority
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        delegate?.updatePriority(priority)
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase, tintColor: UIColor.ud.textTitle)
    }

    private lazy var tableView: InsetTableView = {
        let table = InsetTableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.ud.bgFloatBase
        table.rowHeight = 48
        table.contentInsetAdjustmentBehavior = .never
        table.separatorColor = UIColor.ud.lineDividerDefault
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.lu.register(cellSelf: MailBaseSettingOptionCell.self)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.MailSDK.Mail_EmailPriority_AdvancedSettings_EmailPriority
        view.backgroundColor = UIColor.ud.bgFloatBase
        isNavigationBarHidden = false
        addCloseItem()
        updateNavAppearanceIfNeeded()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.reloadData()
    }

    // MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MailBaseSettingOptionCell.reuseIdentifier) as? MailBaseSettingOptionCell else {
            return UITableViewCell()
        }
        if indexPath.row == 0 {
            cell.titleLabel.text = MailPriorityType.high.toStatusText()
            cell.isSelected = (priority == .high)
        } else if indexPath.row == 1 {
            cell.titleLabel.text = MailPriorityType.normal.toStatusText()
            cell.isSelected = (priority == .normal || priority == .unknownPriority)
        } else {
            cell.titleLabel.text = MailPriorityType.low.toStatusText()
            cell.isSelected = (priority == .low)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            priority = .high
        } else if indexPath.row == 1 {
            priority = .normal
        } else {
            priority = .low
        }
        tableView.reloadData()
        dismiss(animated: true)
    }
}

extension MailPriorityType {
    func toStatusText() -> String {
        switch self {
        case .normal, .unknownPriority:
            return BundleI18n.MailSDK.Mail_EmailPriority_AdvancedSettings_EmailPriority_Standard
        case .high:
            return BundleI18n.MailSDK.Mail_EmailPriority_AdvancedSettings_EmailPriority_High
        case .low:
            return BundleI18n.MailSDK.Mail_EmailPriority_AdvancedSettings_EmailPriority_Low
        @unknown default:
            fatalError()
        }
    }

    func toBannerText() -> String {
        switch self {
        case .normal, .unknownPriority:
            return ""
        case .high:
            return BundleI18n.MailSDK.Mail_EmailPriority_HighPriority_Tag
        case .low:
            return BundleI18n.MailSDK.Mail_EmailPriority_LowPriority_Tag
        @unknown default:
            fatalError()
        }
    }

    func toIcon() -> UIImage {
        switch self {
        case .normal, .unknownPriority:
            return UIImage()
        case .high:
            return UDIcon.importantOutlined.withRenderingMode(.alwaysTemplate)
        case .low:
            return UDIcon.spaceDownOutlined.withRenderingMode(.alwaysTemplate)
        @unknown default:
            fatalError()
        }
    }

    func toTracker() -> String {
        switch self {
        case .normal, .unknownPriority:
            return "middle"
        case .high:
            return "high"
        case .low:
            return "low"
        @unknown default:
            fatalError()
        }
    }
}
