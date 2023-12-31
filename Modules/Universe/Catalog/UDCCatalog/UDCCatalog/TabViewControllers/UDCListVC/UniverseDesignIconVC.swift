//
//  UniverseDesignIconVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/13.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import UIKit
import SnapKit
import UniverseDesignIcon

class UDIconListCell: UICollectionViewCell {

    static var id: String = "UDIconListCell"

    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        contentView.addSubview(iconView)
        contentView.addSubview(stack)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subTitleLabel)

        iconView.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    func config(key: UDIconType) {
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

class UDIconGridCell: UICollectionViewCell {

    static var id: String = "UDIconGridCell"

    lazy var iconView: UIImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        self.contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalToSuperview().offset(-6)
            make.center.equalToSuperview()
        }
    }

    func config(key: UDIconType) {
        self.iconView.image = UDIcon.getIconByKey(key)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconView.image = nil
    }
}

class UniverseDesignIconVC: UIViewController {
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "输入关键字搜索图标"
        searchBar.delegate = self
        return searchBar
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .clear
        collection.insetsLayoutMarginsFromSafeArea = true
        collection.register(UDIconListCell.self, forCellWithReuseIdentifier: UDIconListCell.id)
        collection.register(UDIconGridCell.self, forCellWithReuseIdentifier: UDIconGridCell.id)
        return collection
    }()

    var dataSource: [UDIconType] { searchResult ?? allKeys }

    let allKeys = UDIconType.allCases

    var searchResult: [UDIconType]?

    let idenContentString = "idenContentString"

    override func viewDidLoad() {
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
        self.view.addSubview(collectionView)
    }
    private func setupConstraints() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    private func setupAppearance() {
        self.title = "UniverseDesignIcon"
        self.view.backgroundColor = UIColor.ud.N00

        let switchButton = UIBarButtonItem(title: "Layout", style: .plain, target: self, action: #selector(switchLayout))
        navigationItem.rightBarButtonItem = switchButton
    }

    private var useListLayout: Bool = true

    @objc
    private func switchLayout() {
        useListLayout.toggle()
        collectionView.reloadData()
    }
}

extension UniverseDesignIconVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if useListLayout {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UDIconListCell.id, for: indexPath) as? UDIconListCell else {
                return UICollectionViewCell()
            }
            let key = dataSource[indexPath.row]
            cell.config(key: key)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UDIconGridCell.id, for: indexPath) as? UDIconGridCell else {
                return UICollectionViewCell()
            }
            let key = dataSource[indexPath.row]
            cell.config(key: key)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if useListLayout {
            return CGSize(width: collectionView.frame.width, height: 60)
        } else {
            return CGSize.square(collectionView.frame.width / 10)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let key = dataSource[indexPath.row]
        let vc = UniverseDesignIconDetailVC(iconType: key)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UniverseDesignIconVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        searchBar.resignFirstResponder()
        searchResult = allKeys.filter {
            $0.rawValue.range(of: searchText, options: .caseInsensitive) != nil
        }
        collectionView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResult = nil
            collectionView.reloadData()
        }
    }
}

// MARK: Preview VC

class UniverseDesignIconDetailVC: UIViewController {

    let iconType: UDIconType

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.ud.bgBody
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 1
        imageView.layer.cornerRadius = 12
        imageView.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title2
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var resourceNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title4
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title4
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    init(iconType: UDIconType) {
        self.iconType = iconType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Preview"
        view.backgroundColor = UIColor.ud.bgBase

        view.addSubview(stack)
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(resourceNameLabel)
        stack.addArrangedSubview(sizeLabel)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-16)
        }
        imageView.snp.makeConstraints { make in
            make.width.equalTo(stack)
            make.height.equalTo(imageView.snp.width)
        }
        stack.setCustomSpacing(20, after: imageView)

        let icon = UDIcon.getIconByKeyNoLimitSize(iconType)
        imageView.image = icon
        nameLabel.text = iconType.rawValue
        resourceNameLabel.text = iconType.figmaName
        sizeLabel.text = "\(icon.size.width) x \(icon.size.height)"
    }
}
