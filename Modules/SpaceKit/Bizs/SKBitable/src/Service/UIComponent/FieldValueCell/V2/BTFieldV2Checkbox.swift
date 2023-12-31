//
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
//
// Description:

import SKFoundation
import UniverseDesignCheckBox
import SKResource

struct BTFieldUIDataCheckbox: BTFieldUIData {
    struct Const {
        static let itemSize: CGFloat = 18.0
        static let itemSpace: CGFloat = 12.0
    }
}

final class BTFieldV2Checkbox: BTFieldV2Base {
    // MARK: - public
    
    // MARK: - life cycle
    
    override func subviewsInit() {
        super.subviewsInit()
        
        containerView.addSubview(listView)
        listView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        listView.dataSource = self
        listView.delegate = self
        listView.register(CheckboxCell.self, forCellWithReuseIdentifier: CheckboxCell.defaultReuseID)
        listView.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(onListViewCellOutsideClick(_:)))
        tap.delegate = self
        listView.addGestureRecognizer(tap)
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        
        checkboxValues = model.selectValue
        if listView.collectionViewLayout.collectionViewContentSize.height <= listView.bounds.height {
            // 比较诡异，如果 scrollEnable，滚动的时候 offset 可能会改变导致 checkbox 位置不对
            listView.isScrollEnabled = false
            listView.contentOffset = .zero
        } else {
            listView.isScrollEnabled = true
        }
        listView.reloadData()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        handleCheckboxOutsideClick()
    }
    
    // MARK: - private
    
    private var checkboxValues: [Bool] = [false] {
        didSet {
            if checkboxValues.isEmpty {
                // 至少会显示一个 checkbox，默认值为 false
                checkboxValues = [false]
            }
        }
    }
    
    private var listView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    @objc
    private func onListViewCellOutsideClick(_ sender: UITapGestureRecognizer) {
        handleCheckboxOutsideClick()
    }
    
    private func handleCheckboxOutsideClick() {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        guard checkboxValues.count <= 1 else {
            // 有多个可编辑的 checkbox，暂时没有这种场景，不处理
            return
        }
        guard let cell = listView.cellForItem(at: IndexPath(row: 0, section: 0)) as? CheckboxCell else {
            return
        }
        let value = checkboxValues.first ?? false
        cell.updateCheckStatus(!value)
        delegate?.didToggleCheckbox(forFieldID: fieldID, toStatus: !value)
    }
}

extension BTFieldV2Checkbox {
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == listView {
            let point = touch.location(in: listView)
            for cell in listView.visibleCells {
                if cell.frame.contains(point) {
                    return false
                }
            }
            return true
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
}

extension BTFieldV2Checkbox: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return checkboxValues.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckboxCell.defaultReuseID, for: indexPath)
        if let cell = cell as? CheckboxCell {
            cell.updateCheckStatus(checkboxValues[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? CheckboxCell else {
            return
        }
        let value = checkboxValues[indexPath.row]
        cell.updateCheckStatus(!value)
        delegate?.didToggleCheckbox(forFieldID: fieldID, toStatus: !value)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: BTFieldUIDataCheckbox.Const.itemSize, height: BTFieldUIDataCheckbox.Const.itemSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        BTFieldUIDataCheckbox.Const.itemSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        BTFieldUIDataCheckbox.Const.itemSpace
    }
}

private final class CheckboxCell: UICollectionViewCell {
    static var defaultReuseID = "CheckboxCell"
    
//    let checkbox: UDCheckBox = UDCheckBox()
    
    private let checkbox = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCheckStatus(_ selected: Bool) {
        if selected {
            checkbox.image = BundleResources.SKResource.Bitable.icon_bitable_checkbox_on
        } else {
            checkbox.image = BundleResources.SKResource.Bitable.icon_bitable_checkbox_off
        }
    }
}
