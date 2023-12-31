//
//  NameCardSelectAccountView.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/4/20.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import UniverseDesignIcon

protocol NameCardSelectAccountViewDelegate: AnyObject {
    var selectedAccount: String { get }
    func didTapClose()
    func didSelectAccount(_ account: String)
}

final class NameCardSelectAccountView: UIView,
                                       UITableViewDataSource,
                                       UITableViewDelegate {

    private let rowHeight: CGFloat = 48
    private let defaultCellIdentifier = "cell"
    private let cellIdentifier = String(describing: AccountCell.self)

    private lazy var topContainer = UIView(frame: .zero)
    private lazy var topBorder = UIView(frame: .zero)
    private lazy var closeButton = UIButton(frame: .zero)
    private lazy var titleLabel = UILabel(frame: .zero)
    private lazy var tableView = UITableView(frame: .zero, style: .plain)

    private let accounts: [String]
    private let disposeBag = DisposeBag()
    private weak var delegate: NameCardSelectAccountViewDelegate?

    lazy var maxRow = Int(UIScreen.main.bounds.height * 0.8 / rowHeight)
    lazy var estimateHeight = rowHeight * CGFloat(min(accounts.count + 1, maxRow))

    init(accounts: [String], delegate: NameCardSelectAccountViewDelegate) {
        self.accounts = accounts
        self.delegate = delegate
        super.init(frame: .zero)
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AccountCell,
              let account = accounts[safe: indexPath.row]
        else {
            return UITableViewCell()
        }
        cell.isSelected = account == delegate?.selectedAccount
        cell.textLabel?.text = account
        cell.textLabel?.textColor = .ud .textTitle
        cell.textLabel?.font = .systemFont(ofSize: 16)
        cell.backgroundColor = .ud.bgBody
        if indexPath.item == accounts.count - 1 {
            cell.needSeparator = false
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        delegate?.didSelectAccount(accounts[indexPath.row])
    }
}

private extension NameCardSelectAccountView {
    func setupViews() {
        backgroundColor = .ud.bgBody
        layer.cornerRadius = 12
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        topContainer.backgroundColor = .clear
        addSubview(topContainer)
        topContainer.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(rowHeight)
        }

        topBorder.backgroundColor = .ud.lineDividerDefault
        topContainer.addSubview(topBorder)
        topBorder.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }

        closeButton.tintColor = .ud.textTitle
        closeButton.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        topContainer.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(21)
        }
        closeButton.rx.controlEvent(.touchUpInside)
            .subscribe { [weak self] _ in
                self?.delegate?.didTapClose()
            }
            .disposed(by: disposeBag)

        titleLabel.text = BundleI18n.LarkContact.Mail_ThirdClient_AddToAccount
        titleLabel.textColor = .ud.textTitle
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        topContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = rowHeight
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.register(AccountCell.self, forCellReuseIdentifier: cellIdentifier)
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
    }
}

private final class AccountCell: UITableViewCell {

    let bottomBorder = UIView()
    let checkbox = LKCheckbox(boxType: .list)

    var needSeparator = true {
        didSet {
            bottomBorder.isHidden = !needSeparator
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        contentView.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { (maker) in
            maker.right.bottom.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.left.equalTo(16)
        }

        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            checkbox.isSelected = isSelected
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        needSeparator = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.filter({ $0 != contentView }).forEach { $0.isHidden = !needSeparator }
    }
}
