//
//  AIImageBrowserViewController.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/6/16.
//  


import UIKit
import SnapKit
import ByteWebImage
import LarkImageEditor
import UniverseDesignColor
import RxCocoa
import RxSwift

public struct InlineImageConfig {
    var showSaveImageButton: Bool

    public init(showSaveImageButton: Bool = false) {
        self.showSaveImageButton = showSaveImageButton
    }
}

public class InlineImageBrowserViewController: UIViewController {
    var flowLayout = UICollectionViewFlowLayout()
    
    struct Layout {
        static var cellMargin: CGFloat = 40
    }
    
    lazy var collectionView: UICollectionView = {
        self.flowLayout.scrollDirection = .horizontal
        self.flowLayout.minimumLineSpacing = Layout.cellMargin
        let cltView = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
        cltView.showsHorizontalScrollIndicator = false
        cltView.register(ImageBrowserCell.self, forCellWithReuseIdentifier: ImageBrowserCell.identifier)
        cltView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Layout.cellMargin)
        cltView.delegate = self
        cltView.dataSource = self
        cltView.bounces = false
        cltView.isPagingEnabled = true
        cltView.contentInsetAdjustmentBehavior = .never
        cltView.backgroundColor = UDColor.staticBlack
        return cltView
    }()
    
    private lazy var topBar = AIImagePreviewTopToolBarView()
    
    private lazy var bottomBar = AIImagePreviewBottomToolBarView()
    
    private var dataModels: [InlineAICheckableModel] = []
    
    private var checkList: [InlineAICheckableModel] = []

    private var currentIndex: Int = 0 {
        didSet {
            updatePageLabel()
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    enum Action {
        // topBar选中图片
        case selectImage(InlineAICheckableModel)
        // bottomBar插入图片
        case insertImages([InlineAICheckableModel])
        // bottomBar保存图片
        case saveImage(InlineAICheckableModel)
    }
    
    var eventRelay = PublishRelay<Action>()
    
    var config: InlineImageConfig

    private var currentModel: InlineAICheckableModel? {
        guard currentIndex < dataModels.count else { return nil }
        return self.dataModels[currentIndex]
    }

    public init(config: InlineImageConfig, dataSource: [InlineAICheckableModel], currentIndex: Int) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        self.dataModels = dataSource
        if currentIndex < self.dataModels.count {
            self.currentIndex = currentIndex
        }
        for model in dataModels where model.checkNum > 0{
            self.checkList.append(model)
        }
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
    }
    
    var needAutoScroll = true
    
    func setupUI() {
        view.addSubview(topBar)
        view.addSubview(collectionView)
        view.addSubview(bottomBar)
        
        topBar.delegate = self
        bottomBar.delegate = self
        bottomBar.saveButton.isHidden = !config.showSaveImageButton
        updatePageLabel()
    }
    
    func setupLayout() {
        topBar.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(88)
        }
    
        collectionView.snp.makeConstraints { (maker) in
            maker.top.equalTo(topBar.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview().offset(Layout.cellMargin)
            maker.bottom.equalTo(bottomBar.snp.top)
        }
        
        bottomBar.snp.makeConstraints { (maker) in
            maker.bottom.left.right.equalToSuperview()
            maker.height.equalTo(88)
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard collectionView.bounds.width > 0 else { return }
        let size = CGSize(width: view.bounds.width, height: collectionView.bounds.height)
        if size != self.flowLayout.itemSize {
            self.flowLayout.itemSize = size
            self.flowLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
        if needAutoScroll, currentIndex > 0 {
            let numberItems = collectionView.numberOfItems(inSection: 0)
            if self.currentIndex < numberItems {
                DispatchQueue.main.async {
                    LarkInlineAILogger.info("scroll to idx:\(self.currentIndex) frame:\(self.collectionView.frame)")
                    self.collectionView.isPagingEnabled = false
                    self.collectionView.scrollToItem(at: IndexPath(row: self.currentIndex, section: 0), at: .centeredHorizontally, animated: false)
                    self.collectionView.layoutIfNeeded()
                    self.collectionView.isPagingEnabled = true
                }
            }
        }
        self.needAutoScroll = false
    }
    
    func updatePageLabel() {
        self.topBar.textLabel.text = "\(self.currentIndex + 1)/\(self.dataModels.count)"
        updateBarSelectedNumber()
    }

    func updateCheckModel() {
        for (idx, model) in dataModels.enumerated() {
            let checkListIds = checkList.map { $0.id }
            let checkNum = checkListIds.firstIndex(of: model.id) ?? -1
            dataModels[idx].update(checkNum: checkNum + 1)
        }
    }
    
    func updateBarSelectedNumber() {
        if let currentModel = self.currentModel {
            self.topBar.numberBox.number = currentModel.checkNum == 0 ? nil : currentModel.checkNum
        }
        self.bottomBar.updateSelectNumber(self.checkList.count)
    }
}

// MARK: - UICollectionViewDelegate
extension InlineImageBrowserViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModels.count
    }
    

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < dataModels.count else { return ImageBrowserCell() }
        let model = dataModels[indexPath.row]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageBrowserCell.identifier, for: indexPath) as? ImageBrowserCell {
            cell.update(data: model.source)
            return cell
        } else {
            return ImageBrowserCell()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
        updatePageLabel()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.frame.width > 0 else { return }
        let currentIndex = Int((scrollView.contentOffset.x + scrollView.frame.width / 2.0) / scrollView.frame.width)
        guard currentIndex < dataModels.count else { return }
        self.currentIndex = currentIndex
    }
}

// MARK: - AIImagePreviewTopToolBarViewDelegate
extension InlineImageBrowserViewController: AIImagePreviewTopToolBarViewDelegate {

    func topToolBarViewDidClickCancel() {
        self.dismiss(animated: true)
    }

    func topToolBarViewDidClickCheckBox(isSelect: Bool) {
        guard let currentModel else { return }
        if isSelect {
            let contains = checkList.contains { $0.id == currentModel.id }
            if !contains {
                checkList.append(currentModel)
            } else {
                LarkInlineAILogger.error("click checkbox find no")
            }
        } else {
            checkList.removeAll { $0.id == currentModel.id }
        }
        updateCheckModel()
        updateBarSelectedNumber()
        self.bottomBar.updateSelectButton(!self.checkList.isEmpty) 
        eventRelay.accept(.selectImage(currentModel))
    }
}


// MARK: - AIImagePreviewBottomToolBarViewDelegate
extension InlineImageBrowserViewController: AIImagePreviewBottomToolBarViewDelegate {
    func bottomToolBarViewDidClickInsert() {
        let res = dataModels.compactMap { $0.checkNum > 0 ? $0 : nil }
        eventRelay.accept(.insertImages(res))
        self.presentingViewController?.dismiss(animated: false)
    }
    
    func bottomToolBarViewDidClickSave() {
        if let currentModel = self.currentModel {
            eventRelay.accept(.saveImage(currentModel))
        }
    }
}


class ImageBrowserCell: UICollectionViewCell {
    static let identifier = "ImageBrowserCell"
    
    lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var zoomView: ZoomScrollView = {
        return ZoomScrollView(zoomView: self.imgView, originSize: .zero)
    }()
    
    var placeholderImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let imgSize = CGSize(width: 50, height: 50)
        if let color =  UDColor.AIPrimaryFillTransparent01(ofSize: imgSize) {
            self.placeholderImage = UIColor.ud.image(with: color, size: imgSize, scale: UIScreen.main.scale)
            imgView.image = self.placeholderImage
        }
        
        addSubview(zoomView)
        zoomView.isUserInteractionEnabled = false
        contentView.addGestureRecognizer(zoomView.panGestureRecognizer)
        contentView.addGestureRecognizer(zoomView.pinchGestureRecognizer!)
        zoomView.contentInsetAdjustmentBehavior = .never
        zoomView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func resetZoomView() {
        zoomView.relayoutZoomView()
    }

    func update(data: InlineAIImageData) {
        switch data {
        case .image(let image):
            self.imgView.image = image
        case .url(let url):
            self.imgView.bt.setLarkImage(with: .default(key: url.absoluteString),
                                            placeholder: nil,
                                            trackStart: {
                return TrackInfo(biz: .Docs,
                                 scene: .Unknown,
                                 fromType: .image)
            }, completion: { result in
                switch result {
                case .failure(let error):
                    LarkInlineAILogger.info("load ai image error: \(error)")
                default:
                    break
                }
            })
        case .placeholder, .error:
            self.imgView.image = self.placeholderImage
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        zoomView.originSize = self.bounds.size
    }
}
