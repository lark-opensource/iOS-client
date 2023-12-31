//
//  PostCategoriesDisplayView.swift
//  Moment
//
//  Created by liluobin on 2021/4/21.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LarkInteraction

final class PostCategoryItem {
    fileprivate static let titleFontSize: CGFloat = 14
    let id: String
    let title: String
    let iconKey: String
    fileprivate var selected: Bool = false
    fileprivate lazy var width: CGFloat = {
        return MomentsDataConverter.widthForString(title,
                                                   font: UIFont.systemFont(ofSize: Self.titleFontSize))
    }()
    init(id: String,
         title: String,
         selected: Bool,
         iconKey: String) {
        self.id = id
        self.title = title
        self.selected = selected
        self.iconKey = iconKey
    }
}

final class PostCategoryCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    static let reuseId = "PostCategoryCell"

    var item: PostCategoryItem? {
        didSet {
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor.ud.N100
        self.contentView.layer.cornerRadius = 8
        titleLabel.font = UIFont.systemFont(ofSize: PostCategoryItem.titleFontSize)
        titleLabel.textColor = UIColor.ud.N900
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.contentView.addPointer(.lift)
    }

    func updateUI() {
        guard let item = self.item else {
            return
        }
        titleLabel.text = item.title
        titleLabel.textColor = item.selected ? UIColor.ud.colorfulBlue : UIColor.ud.N900
        self.contentView.backgroundColor = item.selected ? UIColor.ud.B100 : UIColor.ud.N100
        titleLabel.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
        }

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PostCategoryPicker: UIView, UICollectionViewDelegate,
                          UICollectionViewDataSource,
                          UICollectionViewDelegateFlowLayout,
                          UIScrollViewDelegate {
    lazy var leftShadowView: UIImageView = {
        let imageView = UIImageView(image: Resources.leftShadow)
        return imageView
    }()
    lazy var rightShadowView: UIImageView = {
        let imageView = UIImageView(image: Resources.rightShadow)
        return imageView
    }()
    let selectItemCallBack: (() -> Void)?
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        view.register(PostCategoryCell.self, forCellWithReuseIdentifier: PostCategoryCell.reuseId)
        return view
    }()
    var items: [PostCategoryItem] = [] {
        didSet {
            updateUI()
        }
    }

    init(selectItemCallBack: (() -> Void)?) {
        self.selectItemCallBack = selectItemCallBack
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupUI() {
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.addSubview(leftShadowView)
        leftShadowView.snp.makeConstraints { (make) in
            make.left.centerY.equalToSuperview()
            make.width.equalTo(8)
            make.height.equalTo(48)
        }
        self.addSubview(rightShadowView)
        rightShadowView.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
            make.width.equalTo(8)
            make.height.equalTo(48)
        }
        leftShadowView.isHidden = true
        rightShadowView.isHidden = true
    }

    func updateUI() {
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        scrollViewDidScroll(self.collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCategoryCell.reuseId, for: indexPath)
        if let categoryCell = cell as? PostCategoryCell, indexPath.item < items.count {
            categoryCell.item = items[indexPath.item]
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.item < items.count else {
            return .zero
        }
        let item = self.items[indexPath.item]
        return CGSize(width: item.width + 24, height: 30)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            self.leftShadowView.isHidden = false
        } else {
            self.leftShadowView.isHidden = true
        }
        if scrollView.contentSize.width > scrollView.frame.width {
            if let cell = self.collectionView.cellForItem(at: IndexPath(item: self.items.count - 1, section: 0)) {
                let contain = self.collectionView.bounds.contains(self.collectionView.convert(cell.frame, to: self.collectionView))
                self.rightShadowView.isHidden = contain
            } else {
                self.rightShadowView.isHidden = false
            }
        } else {
            self.rightShadowView.isHidden = true
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < self.items.count,
           let cell = collectionView.cellForItem(at: indexPath) as? PostCategoryCell,
           let item = cell.item {
            let selected = item.selected
            self.items.forEach { $0.selected = false }
            if !selected {
                cell.item?.selected = true
            }
            collectionView.reloadData()
            self.selectItemCallBack?()
        }
    }
}

final class PostCategoriesDisplayView: UIView {
    let titleLabel = UILabel()
    lazy var picker: PostCategoryPicker = {
        return PostCategoryPicker(selectItemCallBack: selectItemCallBack)
    }()
    let moreCallBack: (() -> Void)?
    let selectItemCallBack: (() -> Void)?
    var selectedItem: PostCategoryItem? {
        return items.first { (value) -> Bool in
            return value.selected
        }
    }

    var items: [PostCategoryItem] = [] {
        didSet {
            updateUI()
        }
    }
    init(items: [PostCategoryItem], moreCallBack: (() -> Void)?, selectItemCallBack: (() -> Void)?) {
        self.items = items
        self.moreCallBack = moreCallBack
        self.selectItemCallBack = selectItemCallBack
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(titleLabel)
        titleLabel.text = BundleI18n.Moment.Lark_Community_CategoryIs
        titleLabel.textColor = UIColor.ud.N600
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        addSubview(picker)
        picker.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.right.equalTo(allView.snp.left).offset(-10)
            make.height.equalTo(32)
            make.centerY.equalToSuperview()
        }
    }

    lazy var allView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.height.equalTo(30)
            make.centerY.equalToSuperview()
        }
        let textLabel = UILabel()
        textLabel.text = BundleI18n.Moment.Lark_Community_All
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = UIColor.ud.N600
        view.addSubview(textLabel)
        let imageView = UIImageView(image: Resources.allArrow)
        view.addSubview(imageView)

        textLabel.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(imageView.snp.left)
        }
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(textLabel.snp.right)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        textLabel.isUserInteractionEnabled = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(showAllTap))
        view.addGestureRecognizer(tap)
        return view
    }()

    func insertItem(_ item: PostCategoryItem) {
        if item.selected {
            self.selectedItem?.selected = false
        }
        let contain = items.contains { $0.id == item.id }
        if contain {
            items.removeAll(where: { $0.id == item.id })
        }
        items.insert(item, at: 0)
        if items.count > 6 {
            items.removeLast()
        }
        updateUI()
        picker.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
    }

    func updateUI() {
        picker.items = items
    }
    @objc
    func showAllTap() {
        self.moreCallBack?()
    }
}
