//
//  UpdateShareExpireTimeController.swift
//  LarkChatSetting
//
//  Created by 袁平 on 2020/12/15.
//

import UIKit
import Foundation
import LarkUIKit
import LarkExtensions
import LarkSDKInterface
import FigmaKit

enum ExpireTime: Int {
    case sevenDays = 0 // 7天: default
    case oneYear = 1 // 1年
    case forever = 2 // 永久

    func transform() -> ExpiredDay {
        switch self {
        case .sevenDays: return .fixed(time: 7)
        case .oneYear: return .fixed(time: 365)
        case .forever: return .forever
        }
    }

    func timeString() -> String {
        switch self {
        case .sevenDays:
            var date = Date()
            date.addTimeInterval(7 * 24 * 60 * 60)
            return BundleI18n.LarkChatSetting.Lark_Group_QRcodeValidity_7Day(date.lf.formatedStr_v4())
        case .oneYear:
            var date = Date()
            date.addTimeInterval(365 * 24 * 60 * 60)
            return BundleI18n.LarkChatSetting.Lark_Group_QRcodeValidity_1Year(date.lf.formatedStr_v4())
        case .forever:
            return BundleI18n.LarkChatSetting.Lark_Group_QRcodeValidity_Permanent
        }
    }
}

// https://bytedance.feishu.cn/docs/doccn9hrpiNZeVnKNsYkBOsf8jb
final class UpdateShareExpireTimeController: BaseSettingController, UITableViewDataSource, UITableViewDelegate {
    typealias SelectedCallback = (_ time: ExpireTime) -> Void

    struct ExpireModel {
        let timeString: String
        let time: ExpireTime
        var selected: Bool
    }

    private var models: [ExpireModel] = []
    private var selectedCallback: SelectedCallback?

    private lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 10)))
        tableView.register(ShareExpireTimeCell.self, forCellReuseIdentifier: ShareExpireTimeCell.identifier)
        tableView.register(ShareExpireTimeFooter.self, forHeaderFooterViewReuseIdentifier: ShareExpireTimeFooter.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 48
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = UIColor.ud.commonTableSeparatorColor
        tableView.backgroundColor = UIColor.ud.bgBase
        return tableView
    }()

    init(defaultSelected: ExpireTime, supported: [ExpireTime], selectedCallback: SelectedCallback? = nil) {
        self.selectedCallback = selectedCallback
        super.init(nibName: nil, bundle: nil)
        models = supported.map { ExpireModel(timeString: $0.timeString(), time: $0, selected: defaultSelected == $0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = BundleI18n.LarkChatSetting.Lark_Group_ChangeQRcodeValidity
        addBackItem()
        backCallback = { [weak self] in
            guard let self = self else { return }
            if let selected = self.models.first(where: { $0.selected })?.time {
                self.selectedCallback?(selected)
            }
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        DispatchQueue.main.async {
            self.tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
            self.tableView.setContentOffset(CGPoint(x: 0, y: -8), animated: false)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let selected = self.models.first(where: { $0.selected })?.time {
            self.selectedCallback?(selected)
        }
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil, indexPath.row < models.count else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        for index in 0..<models.count {
            models[index].selected = (index == indexPath.row) ? true : false
        }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ShareExpireTimeCell.identifier) as? ShareExpireTimeCell,
              indexPath.row < models.count else {
            return UITableViewCell(frame: .zero)
        }
        cell.update(model: models[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: ShareExpireTimeFooter.identifier)
    }
}

final class ShareExpireTimeCell: UITableViewCell {
    static let identifier = "ShareExpireTimeCell"

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    lazy var selectedView: UIImageView = UIImageView(image: Resources.selected)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(selectedView)
        selectedView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
        }
        selectedView.isHidden = true

        selectedBackgroundView = BaseCellSelectView()
    }

    func update(model: UpdateShareExpireTimeController.ExpireModel) {
        titleLabel.text = model.timeString
        selectedView.isHidden = !model.selected
    }
}

final class ShareExpireTimeFooter: UITableViewHeaderFooterView {
    static let identifier = "ShareExpireTimeFooter"

    private lazy var recommend: UILabel = {
        let recommend = UILabel(frame: .zero)
        recommend.textColor = UIColor.ud.textPlaceholder
        recommend.font = .systemFont(ofSize: 14)
        recommend.numberOfLines = 0
        recommend.text = BundleI18n.LarkChatSetting.Lark_Group_ChangeValidityOnlyEffectiveOnYours
        return recommend
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(recommend)
        recommend.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        tintColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
