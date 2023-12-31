//
//  IconPickerView.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/10.
//

import UIKit
import RxSwift
import RxCocoa
import SKUIKit
import SKFoundation
/*
protocol IconPickerViewDelegate: AnyObject {

    func iconPickerView(_ pickerView: IconPickerView,
                        didSelect icon: IconSelectionInfo,
                        byRandom: Bool,
                        completion: @escaping ((Bool) -> Void))

    func iconPickerViewShouldRemoveIcon(_ pickerView: IconPickerView,
                                        completion: @escaping ((Bool) -> Void))

    func iconPickerViewDidUpdateIcon(_ pickerView: IconPickerView)

}

class IconPickerView: UIView {

    weak var delegate: IconPickerViewDelegate?
    
    var iconViewModel: IconPickerViewModel

    var selectedIconData: IconData?

    private var selectedIndexPath: IndexPath?

    private var categories: [DocsIconCategory] = []

    private let removeIconItem: DocsIconInfo = DocsIconInfo.removeItem
    
    private lazy var layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

    private var isReloading: Bool = false
    
    private let disposeBag = DisposeBag()
    
    init(_ frame: CGRect = .zero, viewModel: IconPickerViewModel, iconData: IconData? = nil) {
        self.selectedIconData = iconData
        self.iconViewModel = viewModel
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        setupUI()
        iconViewModel.modifyCallback = { [weak self] _ in
            guard let self = self else { return }
            self.modifyViewModel()
            self.collectionView.reloadData()
            self.layout.invalidateLayout()
        }
        iconViewModel.updateIcons()
    }

    func randomSelect() {
        let section: Int = Int.random(in: 0..<collectionView.numberOfSections)
        let item: Int = Int.random(in: 0..<collectionView.numberOfItems(inSection: section))
        DocsLogger.info("Did random select icon", extraInfo: ["section": section, "item": item])
        handleIndexChoosen(IndexPath(item: item, section: section), byRandom: true)
    }
    
}

extension IconPickerView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories[section].iconSet.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconPickerImageCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? IconPickerImageCell {
            let info = categories[indexPath.section].iconSet[indexPath.item]
            cell.iconInfo = info
            configureCell(cell, with: info, at: indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 48, height: 48)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isReloading else { return }
        handleIndexChoosen(indexPath, byRandom: false)
    }

    private func handleIndexChoosen(_ indexPath: IndexPath, byRandom: Bool) {
        let info = categories[indexPath.section].iconSet[indexPath.item]
        handleSelected(iconInfo: info, byRandom: byRandom) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.selectedIconData = (info.key, info.type)
                self.delegate?.iconPickerViewDidUpdateIcon(self)
            }

            // refresh the cell to be updated
            if let selectedIndexPath = self.selectedIndexPath,
                let cell = self.collectionView.cellForItem(at: selectedIndexPath) as? IconPickerImageCell {
                self.configureCell(cell, with: self.iconInfo(at: selectedIndexPath), at: selectedIndexPath)
            }
            if let cell = self.collectionView.cellForItem(at: indexPath) as? IconPickerImageCell {
                self.configureCell(cell, with: self.iconInfo(at: indexPath), at: indexPath)
            }

        }
    }
    
}

extension IconPickerView {
    
    private func setupUI() {
        addSubview(collectionView)
        collectionView.register(IconPickerImageCell.self, forCellWithReuseIdentifier: IconPickerImageCell.reuseIdentifier)

        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }

    private func modifyViewModel() {
        // Generate new model with remove icon
        var targetModels = iconViewModel.categories.value
        if targetModels.count > 0 {
            targetModels[0].iconSet.insert(removeIconItem, at: 0)
        }
        self.categories = targetModels
    }

    private func handleSelected(iconInfo: DocsIconInfo, byRandom: Bool, completion: @escaping ((Bool) -> Void)) {
        if iconInfo.type == .remove {
            delegate?.iconPickerViewShouldRemoveIcon(self, completion: completion)
        } else {
            let selectedInfo = IconSelectionInfo(key: iconInfo.key,
                                                 type: iconInfo.type.rawValue,
                                                 fsUnit: iconInfo.fsUnit,
                                                 id: iconInfo.id)
            delegate?.iconPickerView(self, didSelect: selectedInfo, byRandom: byRandom, completion: completion)
        }
    }

    private func configureCell(_ cell: IconPickerImageCell, with info: DocsIconInfo, at indexPath: IndexPath) {
        if let selectedData = selectedIconData {
            cell.isChoosen = info.key == selectedData.0 && info.type == selectedData.1
        } else {
            cell.isChoosen = info.type == .remove
        }
        if cell.isChoosen { selectedIndexPath = indexPath }
    }

    private func iconInfo(at indexPath: IndexPath) -> DocsIconInfo {
        categories[indexPath.section].iconSet[indexPath.item]
    }
}
*/
