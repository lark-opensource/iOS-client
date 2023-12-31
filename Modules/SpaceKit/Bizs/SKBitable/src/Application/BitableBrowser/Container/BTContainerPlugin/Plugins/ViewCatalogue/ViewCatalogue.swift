//
//  ViewCatalogue.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/29.
//

import Foundation
import UniverseDesignTabs
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import SKBrowser
import SKCommon
import ByteWebImage
import SKUIKit

struct ViewCatalogueModel: Equatable {
    var icon: UIImage?
    var text: String = ""
    var isSelected: Bool = false
    var viewId: String?
    var clickAction: String?
    var iconUrl: String? // 临时视图的icon是url
    var radius: CGFloat?
}

final class ViewCatalogueCell: UICollectionViewCell {
    
    private var model = ViewCatalogueModel()
    private static let font = UIFont.systemFont(ofSize: 14, weight: .medium)
    
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        return generator
    }()
    
    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var title: UILabel = {
        let label = UILabel()
        label.font = Self.font
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(icon)
        contentView.addSubview(title)
        title.font = .systemFont(ofSize: 14, weight: .regular)
        title.textColor = UDColor.textCaption
        icon.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
        }
        title.snp.remakeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
//        self.impactGenerator.impactOccurred()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func configModel(_ model: ViewCatalogueModel, selected: Bool) {
        self.model = model
        let tintColor = selected ? UDColor.iconN1 : UDColor.iconN2
        if let udIcon = model.icon?.ud.withTintColor(tintColor) {
            // 有icon用icon，没有用url
            icon.image = udIcon
        } else if let urlString = model.iconUrl, let url = URL(string: urlString) {
            icon.bt.setImage(url, completionHandler:  { [weak self] imageResult in
                if selected {
                    self?.icon.image = try? imageResult.get().image
                } else {
                    self?.icon.image = (try? imageResult.get().image?.ud.withTintColor(tintColor))?.docs_grayscale()
                }
            })
        } else {
            icon.image = nil
            DocsLogger.btError("[ViewCatalogueCell] does not has udKey and url with model \(model)")
        }
        if let iconRadius = model.radius {
            icon.layer.cornerRadius = iconRadius
            icon.layer.masksToBounds = true
        } else {
            icon.layer.masksToBounds = false
            icon.layer.cornerRadius = 0
        }
        title.text = model.text
        title.font = .systemFont(ofSize: 14, weight: selected ? .medium : .regular)
        title.textColor = selected ? UDColor.textTitle : UDColor.textCaption
        let offset = 8
        icon.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(offset)
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
        }
        title.snp.remakeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-offset)
        }
    }
    
    static func cacluteWidth(with model: ViewCatalogueModel) -> CGFloat {
        let font = Self.font
        let width = (model.text as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: 20),
                                                           options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                           attributes: [.font: font],
                                                           context: nil).size.width
        return min(width, 200) + 38
    }
}

final class ViewCatalogueCollectionView: UICollectionView {
        
    lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.dynamic(light: UDColor.bgFloat, dark: UDColor.bgFloatOverlay)
        return view
    }()
    
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        addSubview(indicatorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        indicatorView.layer.cornerRadius = bounds.height / 2.0
        sendSubviewToBack(indicatorView)
    }
}

final class ViewCatalogue: UIView {
        
    private let contentInsetLeft = 18.0
    private let contentInsetRight = 12.0 + 20.0 + 16.0 + 6.0
    private let itemSpaceing = 8.0
    private let maskWidth = 57.0
    private let maskTopPadding = 6.0
    private let maskBottomPadding = 6.0
    private let indicatorPadding = 6.0
    
//    weak var api: ViewCatalogueService?
//    private var callback: String?
    
    private lazy var collectionView: ViewCatalogueCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = itemSpaceing
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: contentInsetLeft, bottom: 0, right: contentInsetRight)
        let col = ViewCatalogueCollectionView(frame: .zero, collectionViewLayout: layout)
        col.register(ViewCatalogueCell.self, forCellWithReuseIdentifier: ViewCatalogueCell.reuseIdentifier)
        col.delegate = self
        col.dataSource = self
        col.showsHorizontalScrollIndicator = false
        col.allowsSelection = true
        col.allowsMultipleSelection = false
        col.backgroundColor = .clear
        col.contentInsetAdjustmentBehavior = .never
        return col
    }()
    
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        // 纯透明-纯透明-(渐变段)-不透明-不透明-(渐变段)-纯透明-纯透明
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor]
        gradientLayer.locations = [0.0, 0.05, 0.1, 0.9, 0.95, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        return gradientLayer
    }()
        
    private(set) var models: [ViewCatalogueModel] = []
    private var selectedIndex: Int = -1 // 默认用户触发点击为第一次
    var selectBlock: ((Int) -> Void)?
            
    private var lastWidth: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastWidth != frame.width {
            lastWidth = frame.width
            if frame.width > 0 {
                // 宽度发生变化
                gradientLayer.frame = self.bounds
                let start0 = (0) / frame.width
                let end0 = (10) / frame.width
                let start1 = (frame.width - 67) / frame.width
                let end1 = (frame.width - 44) / frame.width
                gradientLayer.locations = [0.0, NSNumber(value: start0), NSNumber(value: end0), NSNumber(value: start1), NSNumber(value: end1), 1.0]
            }
            // 宽度发生变化，需要重新定位到中间
            let selectedIndex = self.selectedIndex
            if selectedIndex >= 0, selectedIndex < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: .init(row: selectedIndex, section: 0), at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        layer.mask = gradientLayer
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData(_ datas: [ViewCatalogueModel], with selectedIndex: Int, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            guard selectedIndex >= 0, selectedIndex < datas.count else {
                return
            }
            let indexPath = IndexPath(row: selectedIndex, section: 0)
            self.selectedIndex = selectedIndex
            self.models = datas
            self.collectionView.reloadData()
            self.layoutIfNeeded()

            let indicator = self.collectionView.indicatorView
            if animated {
                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    guard selectedIndex >= 0, selectedIndex < self.models.count else {
                        return
                    }
                    let indexPath = IndexPath(row: selectedIndex, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                    let cell = self.collectionView(self.collectionView, cellForItemAt: indexPath)
                    let destFrame = cell.frame
                    let indicator = self.collectionView.indicatorView
                    indicator.frame = CGRectMake(destFrame.minX - self.indicatorPadding, destFrame.minY, destFrame.width + self.indicatorPadding * 2, destFrame.height)
                }) { _ in
                    
                }
            } else {
                let indicator = self.collectionView.indicatorView
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    guard selectedIndex >= 0, selectedIndex < self.models.count else {
                        return
                    }
                    let indexPath = IndexPath(row: selectedIndex, section: 0)
                    let cell = self.collectionView(self.collectionView, cellForItemAt: indexPath)
                    let destFrame = cell.frame
                    indicator.frame = CGRectMake(destFrame.minX - self.indicatorPadding, destFrame.minY, destFrame.width + self.indicatorPadding * 2, destFrame.height)
                }
            }
        }
    }
    
    func shouldSelect(at index: Int, animated: Bool = true) {
        guard index >= 0, index < self.models.count else {
            return
        }
        collectionView.indicatorView.frame = .zero
        collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: animated, scrollPosition: .centeredHorizontally)
    }
    
}

extension ViewCatalogue: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewCatalogueCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ViewCatalogueCell, let model = models.safe(index: indexPath.row) {
            let selected = indexPath.row == selectedIndex
            cell.configModel(model, selected: selected)
        }
        return cell
    }
}

extension ViewCatalogue: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let model = models.safe(index: indexPath.row) {
            let width = ViewCatalogueCell.cacluteWidth(with: model)
            return CGSize(width: width, height: 40)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectBlock?(indexPath.row)
    }
}

extension ViewCatalogue {
    func setData(currentViewData: BTViewContainerModel, animated: Bool = true) {
//        self.api = api
//        self.callback = currentViewData.callback
        if let items = currentViewData.viewList?.map({ raw in
            return ViewCatalogueModel(
                icon: raw.iconImage,
                text: raw.text ?? "",
                isSelected: raw.id == currentViewData.currentViewId,
                viewId: raw.id,
                clickAction: raw.clickAction,
                iconUrl: raw.icon?.url,
                radius: raw.icon?.iconRadius
            )
        }) {
            let selectedIndex = items.firstIndex(where: { model in
                return model.isSelected
            }) ?? -1
            reloadData(items, with: selectedIndex, animated: animated)
        }
    }
}
