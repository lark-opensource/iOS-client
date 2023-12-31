//
//  EMSettingViewController.swift
//  LarkMine
//
//  Created by Saafo on 2021/8/19.
//

import FigmaKit
import Foundation
import UIKit
import LarkContainer
import LarkUrgent
import UniverseDesignDialog
import UniverseDesignLoading
import UniverseDesignToast
import LarkSplitViewController

final class EMSettingViewController: UIViewController {
    private let table = InsetTableView()

    private var records: [EMRecord] = [] {
        didSet {
            records.forEach { record in
                record.handlerCompletion = { [weak self, weak record] succeeded in
                    guard let self = self else { return }
                    if succeeded {
                        record?.active = false
                        execOnMain { [weak self] in
                            self?.reloadTable()
                        }
                    } else {
                        execOnMain { [weak self] in
                            guard let self = self else { return }
                            UDToast.showFailure(with: EMManager.Cons.someError, on: self.view.window ?? self.view)
                        }
                    }
                }

            }
            execOnMain { [weak self] in
                self?.reloadTable()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = EMManager.Cons.settingTitle
        view.addSubview(table)
        table.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        setupTable()
        table.refreshControl?.beginRefreshing()
        fetchRecord()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadTable),
            name: Notification.EM.authChanged.name,
            object: nil
        )
    }

    private func setupTable() {
        table.delegate = self
        table.dataSource = self
        table.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        table.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        table.estimatedRowHeight = 50
        table.sectionHeaderHeight = UITableView.automaticDimension
        table.sectionFooterHeight = UITableView.automaticDimension
        table.rowHeight = 60
        table.estimatedRowHeight = 60
        table.showsHorizontalScrollIndicator = false
        table.contentInsetAdjustmentBehavior = .automatic
        table.backgroundColor = UIColor.ud.bgBase
        table.separatorColor = UIColor.ud.lineDividerDefault
        table.showsHorizontalScrollIndicator = false
        table.showsVerticalScrollIndicator = true
        table.lu.register(cellSelf: EMSettingAuthCell.self)
        table.lu.register(cellSelf: EMSettingRecordCell.self)

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .clear
        let spin = UDLoading.presetSpin()
        refreshControl.addSubview(spin)
        spin.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        table.refreshControl = refreshControl
        table.refreshControl?.addTarget(self, action: #selector(fetchRecord), for: .valueChanged)
    }

    @objc
    func fetchRecord() {
        EMManager.shared.getList { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                self.records = data
            case .failure(let error):
                execOnMain { [weak self] in
                    guard let self = self else { return }
                    UDToast.showFailure(with: EMManager.Cons.someError, on: self.view.window ?? self.view, error: error)
                }
            }
            execOnMain { [weak self] in
                self?.table.refreshControl?.endRefreshing()
            }
        }
    }

    @objc
    func reloadTable() {
        table.reloadData()
    }
}

extension EMSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.snp.makeConstraints {
            $0.height.equalTo(8)
        }
        return view
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return EMManager.shared.auth == .full ? 0 : 1
        } else {
            return records.count
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return EMManager.shared.auth == .full ? nil : EMManager.Cons.openAuth
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: EMSettingAuthCell.lu.reuseIdentifier, for: indexPath
            ) as? EMSettingAuthCell ?? EMSettingAuthCell()
            cell.vc = self
            return cell
        }
        guard indexPath.section == 1 && records.count > indexPath.row else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: EMSettingRecordCell.lu.reuseIdentifier, for: indexPath
        ) as? EMSettingRecordCell ?? EMSettingRecordCell()
        cell.configure(with: records[indexPath.row])
        return cell
    }
}

private func execOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

// MARK: - Cell

final class EMSettingAuthCell: UITableViewCell {

    weak var vc: EMSettingViewController?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        self.textLabel?.text = EMManager.Cons.auth
        self.detailTextLabel?.text = EMManager.Cons.detailAuth
        self.detailTextLabel?.textColor = UIColor.ud.textCaption

        /// 箭头
        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.mine_right_arrow
        self.contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        /// 右边的去开启
        let detailLabel = UILabel()
        detailLabel.text = EMManager.Cons.goToAppSetting
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-32)
        }

        /// 右边的图标
        let rightImageView = UIImageView()
        rightImageView.image = Resources.notice_alert.ud.resized(to: CGSize(width: 16, height: 16))
        contentView.addSubview(rightImageView)
        rightImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(detailLabel.snp.left).offset(-5.5)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        super.setSelected(false, animated: animated)
    }
}

final class EMSettingRecordCell: UITableViewCell {

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.ud.body2
        label.lineBreakMode = .byTruncatingMiddle
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    var active = false {
        didSet {
            refreshButton()
        }
    }

    private var buttonTapped: () -> Void = {}

    private lazy var button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.ud.caption1
        button.setTitle(EMManager.Cons.end, for: .normal)
        button.setTitle(EMManager.Cons.ended, for: .disabled)
        button.setTitleColor(UIColor.ud.colorfulRed, for: .normal)
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        return button
    }()

    private func refreshButton() {
        if active {
            button.isEnabled = true
            button.layer.borderWidth = 1
            button.ud.setLayerBorderColor(UIColor.ud.colorfulRed)
            button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        } else {
            button.isEnabled = false
            button.layer.borderWidth = 0
            button.ud.setLayerBorderColor(UIColor.clear)
            button.removeTarget(self, action: #selector(tapButton), for: .touchUpInside)
        }
    }

    @objc
    private func tapButton() {
        buttonTapped()
    }

    func configure(with record: EMRecord) {
        label.text = record.title
        active = record.active
        buttonTapped = { record.cancelHandler() }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(button)
        button.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(60)
            $0.height.equalTo(30)
        }
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(button.snp.leading).inset(8)
        }
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
