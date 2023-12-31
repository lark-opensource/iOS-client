//
//  UniverseDesignIconVC.swift
//  UDDebug
//
//  Created by 白镜吾 on 2023/7/24.
//

#if !LARK_NO_DEBUG

import FigmaKit
import UIKit
import UniverseDesignIcon
import SnapKit


private final class UDIconCell: UITableViewCell {

    static var id: String = "UDIconCell"

    lazy var iconView: UIImageView = UIImageView()

    lazy var titleLabel: UILabel = UILabel()

    lazy var subTitleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(iconView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(subTitleLabel)

        iconView.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }

        subTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 17)
        subTitleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textAlignment = .left
        subTitleLabel.textAlignment = .left
        titleLabel.textColor = UIColor.ud.textTitle
        subTitleLabel.textColor = UIColor.ud.textPlaceholder
    }

    func confi(key: UDIconType) {
        self.iconView.image = UDIcon.getIconByKey(key)
        self.titleLabel.text = key.rawValue
        self.subTitleLabel.text = key.figmaName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
        self.subTitleLabel.text = nil
        self.iconView.image = nil
    }
}

public final class UniverseDesignIconVC: UIViewController {
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "输入关键字搜索图标"
        searchBar.delegate = self
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UDIconCell.self, forCellReuseIdentifier: UDIconCell.id)
        return tableView
    }()

    var dataSource: [UDIconType] { searchResult ?? allKeys }

    let allKeys = UDIconType.allCases

    var searchResult: [UDIconType]?

    let idenContentString = "idenContentString"

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        setupComponents()
        setupConstraints()
        setupAppearance()
    }

    private func setupComponents() {
        self.view.addSubview(searchBar)
        self.view.addSubview(tableView)
    }
    private func setupConstraints() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    private func setupAppearance() {
        self.title = "UniverseDesignIcon"
        self.view.backgroundColor = UIColor.ud.N00
    }
}

extension UniverseDesignIconVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UDIconCell.id, for: indexPath) as? UDIconCell else {
            return UITableViewCell()
        }
        let key = dataSource[indexPath.row]
        cell.confi(key: key)
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension UniverseDesignIconVC: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        searchBar.resignFirstResponder()
        searchResult = allKeys.filter {
            $0.rawValue.range(of: searchText, options: .caseInsensitive) != nil
        }
        tableView.reloadData()
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResult = nil
            tableView.reloadData()
        }
    }
}

#endif
