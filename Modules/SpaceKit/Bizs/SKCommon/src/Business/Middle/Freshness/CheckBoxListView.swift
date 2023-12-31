//
//  CheckBoxListView.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/12.
//  


import SKFoundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignCheckBox
import RxSwift

struct CheckBoxListItem {
    var selected: Bool
    var title: String
    var subTitle: String
    var subTitleColor: UIColor
    var subTitleFontSize: CGFloat
    var buttonTitle: String

    init(selected: Bool, title: String,
         subTitle: String = "",
         subTitleColor: UIColor = UDColor.textCaption,
         subTitleFontSize: CGFloat = 14,
         buttonTitle: String = "") {
        self.selected = selected
        self.title = title
        self.subTitle = subTitle
        self.subTitleColor = subTitleColor
        self.subTitleFontSize = subTitleFontSize
        self.buttonTitle = buttonTitle
    }
}

protocol CheckBoxListDelegate: AnyObject {
    func checkBoxList(didSelectRowAt index: Int)
    func checkBoxListSubButtonDidClick()
}

extension CheckBoxListDelegate {
    func checkBoxListSubButtonDidClick() {}
}

class CheckBoxListView: UIView, UITableViewDelegate, UITableViewDataSource {

    weak var delegate: CheckBoxListDelegate?

    private var items: [CheckBoxListItem]

    private lazy var tableView: UITableView = {
        let tableView = ContentSizedTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 46
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionFooterHeight = 0
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.separatorColor = UDColor.lineBorderCard
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.register(CheckBoxListCell.self, forCellReuseIdentifier: CheckBoxListCell.reuseIdentifier)
        return tableView
    }()

    init(items: [CheckBoxListItem] = []) {
        self.items = items
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: tableView.contentSize.height)
    }

    func reloadItems(_ items: [CheckBoxListItem]) {
        self.items = items
        self.tableView.reloadData()
    }

    private func setupUI() {
        addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rawCell = tableView.dequeueReusableCell(withIdentifier: CheckBoxListCell.reuseIdentifier, for: indexPath)
        guard let cell = rawCell as? CheckBoxListCell else {
            assertionFailure("Not CheckBoxListCell")
            return rawCell
        }
        let rows = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
        cell.rightButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        let item = items[indexPath.row]
        cell.setupCell(item: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.checkBoxList(didSelectRowAt: indexPath.item)
    }

    @objc
    func buttonClicked(sender: UIButton) {
        delegate?.checkBoxListSubButtonDidClick()
    }

}

// MARK: - CheckBoxListCell
class CheckBoxListCell: SKGroupTableViewCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        label.backgroundColor = .clear
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        return label
    }()

    lazy var rightButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UDColor.textLinkHover, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 4
        return view
    }()

    private(set) var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    private let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        containerView.backgroundColor = UIColor.ud.bgFloat

        containerView.addSubview(checkBox)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subTitleLabel)
        containerView.addSubview(rightButton)

        containerView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)

        checkBox.snp.makeConstraints { (make) in
            make.height.width.equalTo(20)
            make.left.top.equalToSuperview().inset(12)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(checkBox.snp.trailing).offset(12)
            make.centerY.equalTo(checkBox.snp.centerY)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.equalToSuperview()
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalToSuperview().offset(-12)
        }
        rightButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupCell(item: CheckBoxListItem) {
        titleLabel.text = item.title
        checkBox.isSelected = item.selected
        let subTitleText = item.selected ? item.subTitle : ""
        subTitleLabel.text = subTitleText
        subTitleLabel.textColor = item.subTitleColor
        subTitleLabel.font = UIFont.systemFont(ofSize: item.subTitleFontSize)
        subTitleLabel.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(subTitleText.isEmpty ? 0 : 4)
        }
        rightButton.setTitle(item.buttonTitle, for: .normal)
        rightButton.isHidden = item.buttonTitle.isEmpty
    }
}

final class ContentSizedTableView: UITableView {
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
