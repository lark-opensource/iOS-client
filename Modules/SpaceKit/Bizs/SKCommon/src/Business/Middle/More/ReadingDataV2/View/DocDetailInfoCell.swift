//
//  DocDetailInfoCell.swift
//  SKCommon
//
//  Created by CJ on 2021/9/27.
//

import Foundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import SKUIKit

// 普通cell，icon+title，阅读记录/隐私设置
class DocDetailInfoNormalCell: UITableViewCell {
    static let reuseIdentifier = "DocDetailInfoNormalCell"
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    public var image: UIImage? {
        didSet {
            iconImageView.image = image
        }
    }

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.N900
        return label
    }()

    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.image = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconN3)
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectedBackgroundView = UIView()
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(lineView)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.height.width.equalTo(16)
        }
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
        }
    }
    
    func updateSeperator(isShow: Bool) {
        self.lineView.isHidden = !isShow
    }
}

// 互动统计
class DocDetailReadInfoCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    struct Layout {
        static let padding: CGFloat = 16
        static let margin: CGFloat = 6
    }

    static let reuseIdentifier = "DocDetailReadInfoCell"

    lazy var layout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = Layout.margin
        flowLayout.minimumLineSpacing = Layout.margin
        return flowLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.register(DocDetaiInfoCountCell.self, forCellWithReuseIdentifier: DocDetaiInfoCountCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    var titleLabel = UILabel()
    
    var itemSize = CGSize.zero
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private var data: [DocsDetailInfoCountModel] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        titleLabel.construct { ct in
            ct.textColor = UDColor.textTitle
            ct.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            ct.text = BundleI18n.SKResource.CreationMobile_Stats_Basic_reactions
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)
        contentView.addSubview(lineView)
    }
    
    func update(data: [DocsDetailInfoCountModel], contentWidth: CGFloat) {
        self.data = data
        caculateItemSize(contentWidth)
        self.collectionView.reloadData()
    }
    
    func caculateItemSize( _ contentWidth: CGFloat) {
        let left = contentWidth - Layout.padding * 2 - CGFloat(data.count - 1) * Layout.margin
        var width: CGFloat
        width = floor(left / CGFloat(data.count))
        let filters = data.filter { $0.newsCountText != nil }
        itemSize = CGSize(width: width, height: filters.isEmpty ? 78 : 104)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Layout.padding)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: DocDetaiInfoCountCell.reuseIdentifier, for: indexPath)
        if let cell = collectionViewCell as? DocDetaiInfoCountCell {
            cell.update(model: data[indexPath.row])
            return cell
        } else {
            return collectionViewCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
}


class DocDetaiInfoCountCell: UICollectionViewCell {
    
    static let reuseIdentifier = "DocDetailReadInfoCell"
    
    var titleLabel = UILabel()
    var countLabel = UILabel()
    var increasedLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(model: DocsDetailInfoCountModel) {
        titleLabel.text = model.title
        countLabel.text = model.countText
        increasedLabel.attributedText = model.newsCountText
    }
    
    private func setupView() {
        titleLabel.construct { ct in
            ct.textColor = UDColor.textCaption
            ct.font = UIFont.systemFont(ofSize: 12)
            ct.textAlignment = .center
            ct.numberOfLines = 2
            ct.adjustsFontSizeToFitWidth = true
        }
        
        countLabel.construct { ct in
            ct.textColor = UDColor.textTitle
            ct.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            ct.textAlignment = .center
            ct.adjustsFontSizeToFitWidth = true
            ct.numberOfLines = 1
        }
        
        increasedLabel.construct { ct in
            ct.textColor = UDColor.functionSuccess600
            ct.font = UIFont.systemFont(ofSize: 10)
            ct.textAlignment = .center
            ct.numberOfLines = 0
        }
        
        contentView.backgroundColor = UDColor.bgBodyOverlay
        contentView.layer.cornerRadius = 6
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(increasedLabel)
    }

    private func setupConstraints() {
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(countLabel.snp.top).offset(-4)
            make.left.right.equalToSuperview().inset(4)
        }
        
        countLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.greaterThanOrEqualTo(24)
            make.left.right.equalToSuperview().inset(8)
        }
        
        increasedLabel.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(2)
            make.left.right.equalToSuperview().inset(4)
        }
    }

}
