//
//  BTRatingSymbolPickerViewController.swift
//  Demo
//
//  Created by yinyuan on 2023/2/13.
//

import HandyJSON
import SKUIKit
import SKResource
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignIcon

protocol BTRatingSymbolPickerViewControllerDelegate: AnyObject {
    func didSelectedRatingSymbol(item: BTRatingSymbol, relatedView: UIView?)
}

final class BTRatingSymbolPickerViewController: BTDraggableViewController {
    
    typealias Item = BTRatingSymbol
    
    weak var delegate: BTRatingSymbolPickerViewControllerDelegate?
    
    var callback: ((BTRatingSymbol) -> ())?
    
    weak var relatedView: UIView?
    
    private let items: [Item]
    
    private var selectedItem: Item {
        didSet {
            update()
        }
    }
    
    private func update(animation: Bool = true) {
        previewView.update(ratingConfig(item: selectedItem), 3)
        nameView.text = selectedItem.name
        
        // 进入时滚动到选中项
        if let index = items.firstIndex(where: { color in
            color.symbol == selectedItem.symbol
        }) {
            itemsView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: animation)
        }
    }
    
    lazy var mainView: UIView = {
        let view = UIStackView()
        
        view.addSubview(previewBackgroundView)
        view.addSubview(itemsView)
        
        previewBackgroundView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(180)
        }
        
        itemsView.snp.makeConstraints { make in
            make.top.equalTo(previewBackgroundView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        return view
    }()
    
    lazy var nameView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return view
    }()
    
    lazy var previewBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgFloat
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        
        let wrapperView = UIView()
        view.addSubview(wrapperView)
        wrapperView.addSubview(previewView)
        
        view.addSubview(nameView)
        
        nameView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
        }
        wrapperView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(nameView.snp.top)
            make.left.right.equalToSuperview()
            make.width.equalTo(180)
        }
        previewView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(180)
        }
        
        return view
    }()
    
    private func ratingConfig(item: Item) -> BTRatingView.Config {
        BTRatingView.Config(
            minValue: 1,
            maxValue: 5,
            iconWidth: 32,
            iconSpacing: 4,
            iconPadding: 1.45,
            iconBuilder: { value in
                return BitableCacheProvider.current.ratingIcon(symbol: item.symbol, value: value)
        })
    }
    
    lazy var previewView: BTRatingView = {
        let view = BTRatingView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    final class ItemCell: UICollectionViewCell {
        
        lazy var imageView: UIImageView = {
            let view = UIImageView()
            view.tintColor = UIColor.ud.primaryOnPrimaryFill
            view.image = UDIcon.listCheckOutlined.withRenderingMode(.alwaysTemplate)
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            layer.cornerRadius = self.frame.width / 2
            layer.masksToBounds = true
            layer.ud.setBorderColor(UDColor.textLinkHover)
        }
        
        private func setup() {
            backgroundColor = UDColor.bgFloat
            
            contentView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(32)
                make.center.equalToSuperview()
            }
        }
    }
    
    lazy var itemsView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        layout.itemSize = .init(width: 60, height: 60)
        layout.minimumInteritemSpacing = 6
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.reuseIdentifier)
        
        return view
    }()
    
    var onCloseRatingPanel: (() -> ())?
    
    init(items: [Item], selectedItem: Item, relatedView: UIView? = nil) {
        self.items = items
        self.selectedItem = selectedItem
        self.relatedView = relatedView
        super.init(title: BundleI18n.SKResource.Bitable_Rating_Icon_Title,
                   shouldShowDragBar: false,
                   shouldShowDoneButton: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onCloseRatingPanel?()
    }
    
    override var maxViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height
    }
    
    override func setupUI() {
        super.setupUI()
        initViewHeight = 348.0 + 48
        
        contentView.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        itemsView.reloadData()
        itemsView.layoutIfNeeded()
        update(animation: false)
    }
    
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard self.navigationController?.modalPresentationStyle == .overFullScreen,
              !self.hasBackPage else { return }
        
        let contenViewHeight = min(initViewHeight + view.safeAreaInsets.bottom, maxViewHeight)
        containerView.snp.remakeConstraints { make in
            make.height.equalTo(contenViewHeight)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
}

extension BTRatingSymbolPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ItemCell {
            let item = items[indexPath.row]
            cell.imageView.image = BitableCacheProvider.current.ratingIcon(symbol: item.symbol, value: nil).background.selectImage
            cell.layer.borderWidth = item.symbol == selectedItem.symbol ? 2 : 0
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        selectedItem = items[indexPath.row]
        delegate?.didSelectedRatingSymbol(item: selectedItem, relatedView: relatedView)
        callback?(selectedItem)
        collectionView.performBatchUpdates {
            collectionView.reloadSections(.init(integer: 0))
        } completion: { _ in
            CATransaction.commit()
        }
    }
}
