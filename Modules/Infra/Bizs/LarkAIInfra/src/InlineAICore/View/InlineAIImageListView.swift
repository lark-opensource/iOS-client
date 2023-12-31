//
//  InlineAIImageListView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/6/15.
//  


import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import ByteWebImage


class AIImageCell: UICollectionViewCell, LKNumberBoxDelegate {

    static let identifier = "AIImageCell"

    struct Layout {
        static let checkBoxPadding = CGFloat(8)
        static let checkBoxSize = CGSize(width: 25, height: 25)
        static let cellMargin = CGFloat(8)
    }

    var checkboxDelegage: LKNumberBoxDelegate? {
        didSet {
            numberBox.delegate = checkboxDelegage
        }
    }

    lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var defaultImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var udEmptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: UDEmptyConfig(type: .wrong))
        emptyView.isHidden = true
        emptyView.isUserInteractionEnabled = false
        return emptyView
    }()

    lazy var numberBox: LKNumberBox = {
        let box = LKNumberBox(number: nil)
        box.hitTestEdgeInsets = UIEdgeInsets(top: -9, left: -9, bottom: -9, right: -9)
        box.delegate = self
        return box
    }()

    var placeholderImage: UIImage?
    
    var clickCheckBox: (() -> Void)?
    var downloadImageResult: ((UIImage?, InlineAICheckableModel) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imgView)
        contentView.addSubview(defaultImgView)
        contentView.addSubview(udEmptyView)
        let imgSize = CGSize(width: 50, height: 50)
        if let color =  UDColor.AIPrimaryFillTransparent01(ofSize: imgSize) {
            self.placeholderImage = UIColor.ud.image(with: color, size: imgSize, scale: UIScreen.main.scale)
            defaultImgView.image = self.placeholderImage
        }
        imgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        defaultImgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        udEmptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(numberBox)
        numberBox.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 25, height: 25))
            make.top.equalToSuperview().inset(Layout.checkBoxPadding)
            make.right.equalToSuperview().inset(Layout.checkBoxPadding)
        }
    }
    
    func moveCheckBoxFrame(picker: UIView) {
        guard let cellFrameInPicker = self.superview?.convert(self.frame, to: picker) else { return }

        if cellFrameInPicker.maxY >= getMin(view: picker) {
            
            let point = CGPoint(x: 0, y: Layout.checkBoxPadding)
            
            // 转换到cell的坐标上
            var newY = self.convert(point, from: picker).y

            newY = max(Layout.checkBoxPadding, newY)

            self.numberBox.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(newY)
            }
        } else {
            // 设置checkbox的位置为贴cell最下边
            self.numberBox.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(self.frame.height - Layout.checkBoxSize.height - Layout.checkBoxPadding)
            }
        }
    }
    
    func resetCheckBoxFrame() {
        self.numberBox.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(Layout.checkBoxPadding)
        }
    }
    
    // checkbox不跟随手势滑动的相对于当前view的最小Y坐标值
    func getMin(view: UIView) -> CGFloat {
        return 2 * Layout.checkBoxPadding + Layout.checkBoxSize.height
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(model: InlineAICheckableModel) {
        self.udEmptyView.isHidden = true
        self.defaultImgView.isHidden = false
        self.imgView.isHidden = true
        switch model.source {
        case .image(let image):
            self.defaultImgView.isHidden = true
            self.imgView.isHidden = false
            self.imgView.image = image
            self.numberBox.isHidden = model.style == .disable
//        case .url(let url): // 不在UI层处理
//            self.numberBox.isHidden = model.checkNum >= 0
//            let id = url.absoluteString.md5()
//            LarkInlineAILogger.info("[ai image] downloading id:\(id)")
//            self.imgView.bt.setLarkImage(with: .default(key: url.absoluteString),
//                                            placeholder: self.placeholderImage,
//                                            trackStart: {
//                return TrackInfo(biz: .Unknown,
//                                 scene: .Unknown,
//                                 fromType: .image)
//            }, completion: { [weak self] result in
//                switch result {
//                case .failure(let error):
//                    LarkInlineAILogger.info("[ai image] error: \(error)")
//                    self?.downloadImageResult?(nil, model)
//                case let .success(result):
//                    if result.image == nil {
//                        LarkInlineAILogger.info("[ai image] error, image is nil, id:\(id)")
//                    } else {
//                        LarkInlineAILogger.info("[ai image] download successid:\(id)")
//                    }
//                    self?.downloadImageResult?(result.image, model)
//                }
//            })
        case .placeholder, .url:
            self.imgView.isHidden = false
            self.numberBox.isHidden = true
            self.imgView.image = self.placeholderImage
        case .error:
            self.defaultImgView.isHidden = true
            self.udEmptyView.isHidden = false
            self.numberBox.isHidden = true
        }
        updateCheckbox(model: model)
    }
    
    func updateCheckbox(model: InlineAICheckableModel) {
        if model.checkNum > 0 {
            self.numberBox.number = model.checkNum
        } else {
            self.numberBox.number = nil
        }
    }

    func didTapNumberbox(_ numberBox: LarkUIKit.LKNumberBox) {
        clickCheckBox?()
    }
}

class InlineAIImageListView: InlineAIItemBaseView {

    struct Layout {
        static let itemSpacing: CGFloat = 8
        static let bottomInset: CGFloat = 4
    }

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.register(AIImageCell.self, forCellWithReuseIdentifier: AIImageCell.identifier)
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgFloat
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(Layout.bottomInset)
        }
        collectionView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var models: [InlineAICheckableModel] = []
    
    func update(models: [InlineAICheckableModel]) {
        self.models = models
        self.collectionView.reloadData()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.collectionView.layoutIfNeeded()
    }
    
    func updateImageCheckbox(models: [InlineAICheckableModel]) {
        guard self.models.count == models.count else {
            // 不reloadData更新model要保证数量一致
            LarkInlineAILogger.error("update checkbox error \(self.models.count) != \(models.count)")
            return
        }
        self.models = models
        for item in self.collectionView.indexPathsForVisibleItems {
            guard item.row < models.count else { return }
            if let cell = collectionView.cellForItem(at: item) as? AIImageCell {
                cell.updateCheckbox(model: models[item.row])
            }
        }
    }
    
    func getDispalyHeight() -> CGFloat {
        guard !models.isEmpty else {
            return 0
        }
        guard cellItemSize.height > 10 else {
            return 0
        }
        let bottomInset: CGFloat = 10
        return cellItemSize.height * 2 + Layout.itemSpacing + bottomInset
    }
}


extension InlineAIImageListView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var cellItemSize: CGSize {
        var contentW = self.bounds.width
        if contentW < 10,
           let aiPanelView = self.aiPanelView {
            contentW = aiPanelView.frame.size.width - 20
        }
        guard contentW > 10 else { return .zero }
        let width = (contentW - 8) / 2.0
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.count < models.count else { return AIImageCell() }
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AIImageCell.identifier, for: indexPath) as? AIImageCell {
            let model = models[indexPath.row]
            cell.clickCheckBox = { [weak self] in
                guard let self = self else { return }
                guard indexPath.count < self.models.count else { return }
                self.eventRelay.accept(.clickCheckbox(self.models[indexPath.row]))
            }
//            cell.downloadImageResult = { [weak self] (img, model) in
//                guard let self = self else { return }
//                self.eventRelay.accept(.downloadImage(img, model))
//            }
            cell.update(model: model)
            return cell
        } else {
            return AIImageCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.count < models.count else { return }
        let model = models[indexPath.row]
        self.eventRelay.accept(.clickAIImage(model))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellItemSize
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // UICollectionView与UITableview机制不太一样，cell消失后，再出现，cellForItemAt不一定会调用
        if let collectionCell = cell as? AIImageCell {
            // 主要处理首屏的时候需要设置最上边cell的checkBox的位置
            // 和复用cell后位置需要重新调整
            let cellFrameInPicker = collectionView.convert(collectionCell.frame, to: self)
            // 通过cell的Y是否在容器顶部之外
            if cellFrameInPicker.origin.y <= 0 {
                collectionCell.moveCheckBoxFrame(picker: self)
            } else {
                collectionCell.resetCheckBoxFrame()
            }

        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let lastVisibleCells = collectionView.visibleCells.sorted(by: { (left, right) -> Bool in
            guard let leftPath = collectionView.indexPath(for: left),
                  let rightPath = collectionView.indexPath(for: right) else {
                return false
            }
            return leftPath.row < rightPath.row
        })
        var checkCells: [UICollectionViewCell] = []
        if lastVisibleCells.count >= 2 {
            checkCells = [lastVisibleCells[0], lastVisibleCells[1]]
        } else if lastVisibleCells.count > 1 {
            checkCells = [lastVisibleCells[0]]
        }
        for cell in checkCells {
            guard let AIImageCell = cell as? AIImageCell else {
                continue
            }
            // 跟随滑动动态设置cell的checkbox位置
            AIImageCell.moveCheckBoxFrame(picker: self)
        }
    }
}
