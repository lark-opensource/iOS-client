// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description:

import RxCocoa
import RxSwift
import SKCommon
import SKResource
import SKBrowser
import UniverseDesignColor
import SKFoundation

final class BTCheckboxField: BTBaseField {

    private let disposeBag = DisposeBag()

    // 可编辑时只会显示一个 checkbox
    
    private lazy var checkButton = UIButton(type: .custom).construct { it in
        it.setImage(BundleResources.SKResource.Bitable.icon_bitable_checkbox_off, for: .normal)
        it.setImage(BundleResources.SKResource.Bitable.icon_bitable_checkbox_on, for: .selected)
        it.contentHorizontalAlignment = .fill
        it.contentVerticalAlignment = .fill
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.rx.tap.subscribe(onNext: { [weak it, weak self] _ in
            guard let it = it, let self = self else {
                return
            }
            if self.fieldModel.editable {
                self.delegate?.didToggleCheckbox(forFieldID: self.fieldID, toStatus: !it.isSelected)
            } else {
                self.showUneditableToast()
            }
        })
        .disposed(by: disposeBag)
    }

    // 不可编辑时可能会显示一排 checkbox，超出部分截断，不可滚动

    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.scrollDirection = .horizontal
        it.itemSize = CGSize(width: 18, height: 18)
        it.minimumLineSpacing = 8
    }

    private lazy var checkboxes = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.isScrollEnabled = false
        it.register(BTCheckboxCell.self, forCellWithReuseIdentifier: NSStringFromClass(BTCheckboxCell.self))
        it.delegate = self
        it.dataSource = self
        it.backgroundColor = .clear
    }

    var checkboxValues: [Bool] = []

    var singleCheckButton: Bool {
        // 查找引用 和 公式 都可能会引用 checkbox，这两种情况都是不可编辑的
        return fieldModel.compositeType.uiType != .lookup && fieldModel.compositeType.uiType != .formula
    }
    
    override func resetLayout() {
        super.resetLayout()
        checkButton.removeFromSuperview()
        checkboxes.removeFromSuperview()
        if singleCheckButton {
            verticalStackView.snp.remakeConstraints { (it) in
                it.left.equalTo(horizontalStackView)
                it.bottom.equalToSuperview().offset(-9)
                it.top.equalTo(horizontalStackView.snp.bottom).offset(8)
                it.right.equalToSuperview().offset(-BTFieldLayout.Const.containerLeftRightMargin)
            }
            containerView.addSubview(checkButton)
            containerView.snp.remakeConstraints { it in
                it.height.equalTo(40)
                it.width.equalTo(50)
            }
            checkButton.snp.makeConstraints { (it) in
                it.center.equalToSuperview()
                it.width.height.equalTo(18)
            }
        } else { // 当前字段是查找结果为 checkbox 的 lookup 字段，可能会显示多个 checkbox
            verticalStackView.snp.remakeConstraints { it in
                it.left.equalTo(horizontalStackView)
                it.bottom.equalToSuperview().offset(-9)
                it.top.equalTo(horizontalStackView.snp.bottom).offset(8)
                it.right.equalToSuperview().offset(-BTFieldLayout.Const.containerLeftRightMargin)
            }
            containerView.addSubview(checkboxes)
            containerView.snp.remakeConstraints { it in
                it.width.equalTo(verticalStackView)
            }
            checkboxes.snp.makeConstraints { (it) in
                it.edges.equalToSuperview().inset(10)
            }
        }
        layoutIfNeeded()
    }

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        checkboxValues = model.selectValue
        if singleCheckButton {
            checkButton.isSelected = checkboxValues.first ?? false
        } else {
            checkboxes.reloadData()
        }
    }
}

extension BTCheckboxField: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        checkboxValues.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(BTCheckboxCell.self), for: indexPath)
        if let cell = cell as? BTCheckboxCell {
            cell.setSelected(checkboxValues[indexPath.item])
        }
        return cell
    }
}

final class BTCheckboxCell: UICollectionViewCell {
    lazy var imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ selected: Bool) {
        if selected {
            imageView.image = BundleResources.SKResource.Bitable.icon_bitable_checkbox_on
        } else {
            imageView.image = BundleResources.SKResource.Bitable.icon_bitable_checkbox_off
        }
    }
}
