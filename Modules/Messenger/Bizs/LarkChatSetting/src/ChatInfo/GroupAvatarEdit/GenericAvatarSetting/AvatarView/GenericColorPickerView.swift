//
//  GenericColorPickerView.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/11/16.
//
import UIKit
import FigmaKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteWebImage
import LKCommonsLogging

class SolidColorPickItem {
    let key: String
    let startColorInt: Int32
    let endColorInt: Int32
    let fsUnit: String

    var selected: Bool = false

    lazy var startColor: UIColor = {
        return UIColor.ud.rgb(UInt32(startColorInt))
    }()

    lazy var endColor: UIColor = {
        return UIColor.ud.rgb(UInt32(endColorInt))
    }()

    init(key: String,
         fsUnit: String,
         startColorInt: Int32,
         endColorInt: Int32) {
        self.startColorInt = startColorInt
        self.endColorInt = endColorInt
        self.key = key
        self.fsUnit = fsUnit
    }
}

protocol ColorPickerViewDelegate: AnyObject {
    func didSelectItemAt(indexPath: IndexPath, item: SolidColorPickItem)
}

final class GenericColorCollectionViewCell: UICollectionViewCell {

    private let logger = Logger.log(GenericColorCollectionViewCell.self, category: "GenericColorCollectionViewCell")

    static let reuseKey = "GenericColorCollectionViewCell"
    let colorView = ByteImageView()
    let checkedWrapperView: UIView = UIView()
    let checkedView = UIImageView(image: UDIcon.getIconByKey(.checkOutlined, size: TextAvatarLayoutInfo.checkViewSize).ud.withTintColor(UIColor.ud.staticWhite))

    var item: SolidColorPickItem? {
        didSet {
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(self.colorView)
        contentView.layer.masksToBounds = true
        colorView.layer.masksToBounds = true
        checkedWrapperView.layer.masksToBounds = true
        checkedWrapperView.layer.borderWidth = TextAvatarLayoutInfo.checkViewBorderWidth
        checkedWrapperView.layer.ud.setBorderColor(UIColor.ud.bgBody)
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(checkedWrapperView)
        checkedWrapperView.snp.makeConstraints { make in
            make.bottom.equalTo(colorView.snp.bottom).offset(TextAvatarLayoutInfo.checkViewBorderWidth)
            make.trailing.equalTo(colorView.snp.trailing).offset(TextAvatarLayoutInfo.checkViewBorderWidth)
        }
        checkedWrapperView.addSubview(checkedView)
        checkedView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: TextAvatarLayoutInfo.checkViewBorderWidth))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        colorView.layer.cornerRadius = self.frame.width / 2.0
        checkedWrapperView.layer.cornerRadius = TextAvatarLayoutInfo.checkViewBorderWidth + TextAvatarLayoutInfo.checkViewSize.width / 2.0
        checkedView.backgroundColor = UIColor.ud.functionInfoContentDefault
    }

    func updateUI() {
        guard let item = self.item else {
            return
        }
        var passThrough = ImagePassThrough()
        passThrough.key = item.key
        passThrough.fsUnit = item.fsUnit
        self.colorView.bt.setLarkImage(.default(key: item.key), passThrough: passThrough, completion: { [weak self] imageResult in
            if case .failure(let error) = imageResult {
                self?.logger.error("colorView.bt.setLarkImage error item.key \(item.key)", error: error)
            }
        })
        self.checkedWrapperView.isHidden = !item.selected
    }
}

/// 提供颜色选择
class GenericColorPickerView: UIView, UICollectionViewDelegate,
                       UICollectionViewDataSource,
                       UICollectionViewDelegateFlowLayout, ClearSeletedStatusProtocol {

    private(set) var data: [SolidColorPickItem] = []

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    var itemSize: CGSize {
        return TextAvatarLayoutInfo.itemSize
    }

    weak var delegate: ColorPickerViewDelegate?
    init(delegate: ColorPickerViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        self.addSubview(collectionView)
        backgroundColor = UIColor.ud.bgBody
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.register(GenericColorCollectionViewCell.self, forCellWithReuseIdentifier: GenericColorCollectionViewCell.reuseKey)
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

    func setSelectedColor(startColorInt: Int32, endColorInt: Int32) -> (SolidColorPickItem, Int)? {
        var arr = self.resetItemSelectStatus()
        var selectedItem: (SolidColorPickItem, Int)?
        for (index, item) in data.enumerated() {
            if startColorInt == item.startColorInt,
                endColorInt == item.endColorInt {
                item.selected = true
                let indexPath = IndexPath(row: index, section: 0)
                selectedItem = (item, index)
                if !arr.contains(where: { index in
                    return index.row == indexPath.row
                }) {
                    arr.append(indexPath)
                }
            }
        }
        self.collectionView.reloadItems(at: arr)
        return selectedItem
    }

    func getSeletedItem() -> (SolidColorPickItem, Int)? {
        if let idx = self.data.firstIndex(where: { $0.selected }) {
            return (self.data[idx], idx)
        }
        return nil
    }

    func pickerFirstColorItem() -> (SolidColorPickItem, Int) {
        let idx = 0
        let item = self.data[idx]
        item.selected = true
        self.collectionView.reloadItems(at: [IndexPath(row: idx, section: 0)])
        return (item, idx)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(itemSize.height * 2 + TextAvatarLayoutInfo.itemLineSpace)
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.data[indexPath.row]
        let cell: UICollectionViewCell? = collectionView.dequeueReusableCell(withReuseIdentifier: GenericColorCollectionViewCell.reuseKey, for: indexPath)
        (cell as? GenericColorCollectionViewCell)?.item = item
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
        return TextAvatarLayoutInfo.itemLineSpace
    }
    /// |minimumInteritemSpacingForSectionAt|
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return floor((self.frame.width - itemSize.width * CGFloat(TextAvatarLayoutInfo.itemRowCount)) / CGFloat(TextAvatarLayoutInfo.itemRowCount - 1))
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
        if !indexs.contains(where: { $0.row == indexPath.row }) {
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
