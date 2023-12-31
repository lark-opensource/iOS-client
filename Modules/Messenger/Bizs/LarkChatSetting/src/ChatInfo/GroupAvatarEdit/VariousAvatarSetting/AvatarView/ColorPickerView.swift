//
//  ColorPickerView.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/9.
//

import UIKit
import FigmaKit
import SnapKit
import UniverseDesignColor
import ByteWebImage
import LKCommonsLogging

final class SolidColorCollectionViewCell: UICollectionViewCell {

    private static let logger = Logger.log(SolidColorCollectionViewCell.self, category: "SolidColorCollectionViewCell")

    static let reuseKey = "SolidColorCollectionViewCell"
    let colorView = ByteImageView()

    var item: SolidColorPickItem? {
        didSet {
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.colorView)
        self.contentView.layer.borderWidth = 2
        self.contentView.layer.masksToBounds = true
        self.colorView.layer.masksToBounds = true
        self.colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: 6))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.frame.width > 0 else {
            return
        }
        let width = (self.frame.width - 12) / 2.0
        self.colorView.layer.cornerRadius = width
        self.contentView.layer.cornerRadius = self.frame.width / 2.0
    }

    func updateUI() {
        guard let item = self.item else {
            return
        }
        var passThrough = ImagePassThrough()
        passThrough.key = item.key
        passThrough.fsUnit = item.fsUnit
        self.colorView.bt.setLarkImage(.default(key: item.key), passThrough: passThrough) { imageResult in
            if case .failure(let error) = imageResult {
                Self.logger.error("colorView.bt.setLarkImage error item.key \(item.key)", error: error)
            }
        }
        let startColor = UIColor.ud.rgb(UInt32(item.startColorInt))
        let endColor = UIColor.ud.rgb(UInt32(item.endColorInt))
        self.contentView.layer.borderColor = item.selected ? ColorCalculator.middleColorForm(startColor,
                                                                                                to: endColor).cgColor : UIColor.clear.cgColor
    }
}

/// 提供颜色选择
class ColorPickerView: UIView, UICollectionViewDelegate,
                       UICollectionViewDataSource,
                       UICollectionViewDelegateFlowLayout, ClearSeletedStatusProtocol {
    var itemLineSpace: CGFloat = 9
    var itemRowSpace: CGFloat = 8
    var itemRowCount: Int = 5

    private(set) var data: [SolidColorPickItem] = []

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    weak var delegate: ColorPickerViewDelegate?

    var itemSize: CGSize {
        let sizeWidth = (self.frame.width - itemLineSpace * CGFloat((self.itemRowCount - 1))) / CGFloat(self.itemRowCount)
        return CGSize(width: floor(sizeWidth), height: floor(sizeWidth))
    }

    init(delegate: ColorPickerViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        self.addSubview(collectionView)
        backgroundColor = UIColor.ud.bgBody
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.register(SolidColorCollectionViewCell.self,
                                forCellWithReuseIdentifier: SolidColorCollectionViewCell.reuseKey)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(items: [SolidColorPickItem]) {
        self.data = items
        self.collectionView.reloadData()
    }

    func setSelectedColor(startColorInt: Int32, endColorInt: Int32) -> IndexPath? {
        var arr = self.resetItemSelectStatus()
        var selectedIndex: IndexPath?
        for (index, item) in data.enumerated() {
            if startColorInt == item.startColorInt,
                endColorInt == item.endColorInt {
                item.selected = true
                let indexPath = IndexPath(row: index, section: 0)
                selectedIndex = indexPath
                if !arr.contains(where: { index in
                    return index.row == indexPath.row
                }) {
                    arr.append(indexPath)
                }
            }
        }
        self.collectionView.reloadItems(at: arr)
        return selectedIndex
    }

    func getSeletedItem() -> (SolidColorPickItem, Int)? {
        if let idx = self.data.firstIndex(where: { $0.selected }) {
            return (self.data[idx], idx)
        }
        return nil
    }

    func pickerRandomColorItem() -> (SolidColorPickItem, Int) {
        let idx = Int.random(in: 0..<data.count)
        let item = self.data[idx]
        item.selected = true
        self.collectionView.reloadItems(at: [IndexPath(row: idx, section: 0)])
        return (item, idx)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(itemSize.height * 2 + self.itemRowSpace)
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.data[indexPath.row]
        let cell: UICollectionViewCell? = collectionView.dequeueReusableCell(withReuseIdentifier: SolidColorCollectionViewCell.reuseKey, for: indexPath)
        (cell as? SolidColorCollectionViewCell)?.item = item
        return cell ?? UICollectionViewCell()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    /// -------
    /// minimumLineSpacingForSectionAt
    /// ------
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemRowSpace
    }
    /// |minimumInteritemSpacingForSectionAt|
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemLineSpace
    }

    func clearSeletedStatus() {
        self.collectionView.reloadItems(at: self.resetItemSelectStatus())
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.data[indexPath.row]
        let selected = item.selected
        /// 选中不可以取消了
        if selected { return }
        var indexs = self.resetItemSelectStatus()
        if !indexs.contains { $0.row == indexPath.row } {
            indexs.append(indexPath)
        }
        item.selected = !selected
        self.delegate?.didSelectItemAt(indexPath: indexPath, item: item)
        collectionView.reloadItems(at: indexs)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    private func resetItemSelectStatus() -> [IndexPath] {
        var index: [IndexPath] = []
        for (idx, item) in data.enumerated() {
            if item.selected {
                item.selected = false
                index.append(IndexPath(row: idx, section: 0))
            }
        }
        return index
    }
}
