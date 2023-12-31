// 
// Created by duanxiaochen.7 on 2020/7/1.
// Affiliated with SKCommon.
// 
// Description:

import Foundation
import UniverseDesignColor

class BlockSectionCell: UICollectionViewCell {

    weak var insertDelegate: InsertBlockDelegate?

    private var model: BlockSectionModel!

    private var uiConstant = InsertBlockUIConstant()

    private var header: HeaderView?

    var isPopover = false
    
    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.scrollDirection = .horizontal
        it.minimumLineSpacing = uiConstant.blockCellSpacing
        it.sectionInset = UIEdgeInsets(top: 0, left: uiConstant.sectionInsetValue, bottom: 0, right: uiConstant.sectionInsetValue)
    }

    private lazy var blockCollection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.backgroundColor = .clear
        it.clipsToBounds = false
        it.showsHorizontalScrollIndicator = false
        it.register(BlockCell.self, forCellWithReuseIdentifier: NSStringFromClass(BlockCell.self))
        it.delegate = self
        it.dataSource = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        header?.removeFromSuperview()
        blockCollection.removeFromSuperview()
    }

    func configure(with model: BlockSectionModel, uiConstant: InsertBlockUIConstant) {
        self.model = model
        self.uiConstant = uiConstant
        contentView.addSubview(blockCollection)

        if let title = model.subTitle {
            let newHeader = HeaderView(uiConstant: uiConstant, title: title)
            header = newHeader
            contentView.addSubview(newHeader)
            newHeader.snp.makeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(uiConstant.sectionHeaderHeight)
                make.bottom.equalTo(blockCollection.snp.top)
            }

            blockCollection.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(newHeader.snp.bottom)
            }
        } else {
            blockCollection.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }

        blockCollection.reloadData()
    }
}

extension BlockSectionCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.data.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: uiConstant.blockCellWidth, height: model.cellMaxHeight(uiConstant: uiConstant))
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellModel = model.data[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(BlockCell.self),
                                                            for: indexPath) as? BlockCell else { return BlockCell() }
        cell.isPopover = isPopover
        cell.configure(with: cellModel, uiConstant: uiConstant)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        insertDelegate?.didSelectBlock(id: model.data[indexPath.item].id)
    }
}

extension BlockSectionCell {
    class HeaderView: UIView {
        init(uiConstant: InsertBlockUIConstant, title: String) {
            super.init(frame: .zero)
            let label = UILabel()
            label.text = title
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 1
            label.font = UIFont.systemFont(ofSize: uiConstant.sectionHeaderTitleFontSize, weight: .regular)
            self.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().offset(uiConstant.sectionHeaderInsetValue)
                make.trailing.equalToSuperview().offset(-uiConstant.sectionHeaderInsetValue)
                make.centerY.equalToSuperview()
                make.height.equalTo(uiConstant.sectionHeaderTitleFontSize * 1.5)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
