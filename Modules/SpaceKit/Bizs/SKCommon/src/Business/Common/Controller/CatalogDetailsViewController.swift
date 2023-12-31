//
//  CatalogDetailsViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/4/28.
//
// swiftlint:disable file_length

import Foundation
import SKFoundation
import SKResource
import SKUIKit
import ThreadSafeDataStructure
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignIcon

public protocol CatalogDetailsViewControllerDelegate: AnyObject {
    func didClickItem(_ item: CatalogItemDetail, controller: CatalogDetailsViewController)
    func didClickImage(_ item: CatalogItemDetail, controller: CatalogDetailsViewController)
    func didAppear(height: CGFloat, controller: CatalogDetailsViewController)
    func disAppear(controller: CatalogDetailsViewController)
}

extension CatalogDetailsViewControllerDelegate {
    public func didAppear(height: CGFloat, controller: CatalogDetailsViewController) { return }
    public func disAppear(controller: CatalogDetailsViewController) { return }
}

public enum CatalogOpenSource {
    case more
    case navCatalog
}

public final class CatalogDetailsViewController: DraggableViewController, UICollectionViewDelegate,
                                    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var clickDelegate: CatalogDetailsViewControllerDelegate?
    public var openFrom: CatalogOpenSource = .navCatalog
    private var items: SafeArray<CatalogItemDetail> = [] + .readWriteLock
    private let cellReuseIdentifier = "com.bytedance.ee.docs.CatalogDetails"
    private let itemHeight: CGFloat = 40
    private var currentIndex: Int = -1
    private var currentIdentifier: String = ""
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var enableZoomFontSize: Bool = false
    
    public var supportOrentations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrentations
    }

    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [.windowOrVC]
        return preventer
    }()
    
    private var layout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        return layout
    }

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(CatalogDetailCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var dismissView: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapDimissView))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var titleView: DragTitleView = {
        let view = DragTitleView()
        view.updateTitle(title: BundleI18n.SKResource.Doc_Doc_MoreStructure)
        if enableZoomFontSize {
            view.updateTitleFontSize(fontSize: UIFont.ud.headline(.s4))
        } else {
            view.updateTitleFontSize(fontSize: UIFont.systemFont(ofSize: 17, weight: .medium))
        }
        view.clickClose = { [weak self] in
            self?.onTapDimissView()
        }
        view.removeDragLine()
        return view
    }()

    private lazy var blankView: UDEmpty = {
        let blankView = UDEmpty(config: .init(title: .init(titleText: ""),
                                              description: .init(descriptionText: BundleI18n.SKResource.Doc_Doc_StructureEmtpyTips),
                                              imageSize: 100,
                                              type: .noCloudFile,
                                              labelHandler: nil,
                                              primaryButtonConfig: nil,
                                              secondaryButtonConfig: nil))
        blankView.isHidden = true
        return blankView
    }()

    public init(fontZoomable: Bool,
         details: [CatalogItemDetail],
         delegate: CatalogDetailsViewControllerDelegate?,
         selected: Int) {
        super.init(nibName: nil, bundle: nil)
        currentIndex = selected
        if selected >= 0, selected < details.count {
            currentIdentifier = details[selected].identifier
        }
        self.items.append(contentsOf: details)
        self.clickDelegate = delegate
        self.enableZoomFontSize = fontZoomable
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupContentView()
        feedbackGenerator.prepare()
    }

    private func setupContentView() {
        if ViewCapturePreventer.isFeatureEnable {
            contentView = viewCapturePreventer.contentView
        } else {
            contentView = UIView()
        }
        contentView.backgroundColor = UDColor.bgBody
        blankView.isHidden = !items.isEmpty
        view.addSubview(dismissView)
        dismissView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        view.addSubview(contentView)
        updateContentSize()
        contentView.layer.maskedCorners = .top
        contentView.layer.cornerRadius = 12
        contentView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        contentView.layer.shadowOffset = CGSize(width: 5, height: -5)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 22

        contentView.addSubview(titleView)
        let titleHeight = enableZoomFontSize ? 50.auto(.s4) : 50
        titleView.snp.makeConstraints { (make) in
            make.top.right.left.equalToSuperview()
            make.height.equalTo(titleHeight)
        }
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleView.snp.bottom)
            make.bottom.equalToSuperview().offset(-(view.window?.safeAreaInsets.bottom ?? 0.0))
        }

        contentView.addSubview(blankView)
        blankView.snp.makeConstraints { (make) in
            make.center.left.right.equalTo(collectionView)
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if currentIndex >= 0, items.count > 0, currentIndex < items.count { // 可能是空白页
            collectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .centeredVertically, animated: false)
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clickDelegate?.didAppear(height: view.bounds.height - contentViewMaxY, controller: self)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clickDelegate?.disAppear(controller: self)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let `self` = self else { return }
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    private func updateContentSize() {
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            contentViewMaxY = 97
            contentView.snp.remakeConstraints { (make) in
                make.bottom.centerX.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
                make.top.equalTo(contentViewMaxY)
            }
        } else {
            contentViewMaxY = (1 - 0.63) * view.frame.size.height
            contentView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(contentViewMaxY)
                make.bottom.equalToSuperview()
            }
        }
    }
    
    public func orientationDidChange() {
        updateContentSize()
    }

    public func reload(_ details: [CatalogItemDetail], index: Int? = nil) {
        if let index = details.firstIndex(where: { $0.identifier == currentIdentifier }) {
            currentIndex = index
        } else if let outIndex = index, outIndex > 0, outIndex < details.count {
            currentIndex = outIndex
            currentIdentifier = details[outIndex].identifier
        } else {
            currentIndex = 0
        }
        self.items.replaceInnerData(by: details)
        self.collectionView.reloadData()
        self.blankView.isHidden = !items.isEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onTapDimissView() {
        dismiss(animated: true, completion: nil)
    }

    public override func dragDismiss() {
        super.dragDismiss()
        onTapDimissView()
    }
    
    /// 设置允许被截图
    public func setCaptureAllowed(_ allow: Bool) {
        DocsLogger.info("CatalogDetailsVC setCaptureAllowed => \(allow)")
        viewCapturePreventer.isCaptureAllowed = allow
    }
    
// MARK: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let cell = cell1 as? CatalogDetailCell else {
            return cell1
        }
        cell.delegate = self
        cell.configure(by: items[indexPath.row], indexPath: indexPath, enableZoomFontSize: enableZoomFontSize)
        cell.ligthUp(indexPath.row == currentIndex)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let realItemHeight = enableZoomFontSize ? itemHeight.auto(.s4) : itemHeight
        return CGSize(width: collectionView.frame.width, height: realItemHeight)
    }
// MARK: UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*
        let selectedCell = collectionView.cellForItem(at: indexPath) as? CatalogDetailCell
        selectedCell?.ligthUp(true)
        if currentIndex >= 0, currentIndex != indexPath.row {
            let oldCell = collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) as? CatalogDetailCell
            oldCell?.ligthUp(false)
        }
        currentIndex = indexPath.row
        self.clickDelegate?.didClickItem(items[indexPath.row], controller: self)
        */
    }
}

extension CatalogDetailsViewController: CatalogDetailCellDelegate {
    public func selectText(_ cell: CatalogDetailCell, model: CatalogItemDetail?) {
        guard let item = model else { return }
        lightUpCell(cell)
        clickDelegate?.didClickItem(item, controller: self)
        feedbackGenerator.impactOccurred()
    }

    public func selectImage(_ cell: CatalogDetailCell, model: CatalogItemDetail?) {
        guard let item = model else { return }
        lightUpCell(cell)
        clickDelegate?.didClickImage(item, controller: self)
        feedbackGenerator.impactOccurred()
    }

    private func lightUpCell(_ cell: CatalogDetailCell) {
        cell.ligthUp(true)
        if currentIndex >= 0, currentIndex != cell.indexPath.row {
                   let oldCell = collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) as? CatalogDetailCell
                   oldCell?.ligthUp(false)
               }
        currentIndex = cell.indexPath.row
        currentIdentifier = cell.model?.identifier ?? ""
    }
}

/// 侧边目录栏的item cell

public protocol CatalogDetailCellDelegate: AnyObject {
    func selectText(_ cell: CatalogDetailCell, model: CatalogItemDetail?)
    func selectImage(_ cell: CatalogDetailCell, model: CatalogItemDetail?)
}

public final class CatalogDetailCell: UICollectionViewCell {
    private let selectedColor = UDColor.colorfulBlue
    private let normalColor = UDColor.textTitle
    private let defaultPadding: CGFloat = 12
    private let iconWidth: CGFloat = 8
    private let iconPadding: CGFloat = 6
    private let titleLabelHeight: CGFloat = 24
    private let normalContainerWidth: CGFloat = 32
    var model: CatalogItemDetail?
    weak var delegate: CatalogDetailCellDelegate?
    var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var iconContainer: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = normalColor
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var highLightBgView: UIView = {
        var view = UIView()
        view.backgroundColor = UIColor.ud.fillSelected
        view.isHidden = true
        view.layer.cornerRadius = 6
        view.isUserInteractionEnabled = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(highLightBgView)
        contentView.addSubview(iconContainer)
        iconContainer.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(normalContainerWidth)
            make.height.equalTo(titleLabelHeight)
            make.centerY.equalToSuperview()
        }
        
        highLightBgView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(8)
        }

        iconContainer.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(iconWidth)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconContainer.snp.right).offset(4)
            make.right.equalToSuperview().offset(defaultPadding)
            make.height.equalTo(titleLabelHeight)
            make.centerY.equalToSuperview()
        }

        let titleTap = UITapGestureRecognizer(target: self, action: #selector(tapTitle))
        titleLabel.addGestureRecognizer(titleTap)

        let imageTap = UITapGestureRecognizer(target: self, action: #selector(tapImage))
        iconContainer.addGestureRecognizer(imageTap)

    }

    func ligthUp(_ light: Bool) {
        highLightBgView.isHidden = !light
        titleLabel.textColor = light ? selectedColor : normalColor
        highLightIcon(light)
    }

    func configure(by item: CatalogItemDetail, indexPath: IndexPath, enableZoomFontSize: Bool) {
        self.indexPath = indexPath
        model = item
        if enableZoomFontSize {
            titleLabel.font = (item.level == 1) ? UIFont.ud.body1(.s4)  : UIFont.ud.body2(.s4) 
        } else {
            let weight: UIFont.Weight = (item.level == 1) ? .medium : .regular
            titleLabel.font = UIFont.systemFont(ofSize: 14, weight: weight)
        }
        titleLabel.text = item.title
        highLightIcon(false)
    }

    private func highLightIcon(_ light: Bool) {
        guard let info = model else { return }
        let width: CGFloat = info.showCollapse ? (normalContainerWidth + textPadding()) : (defaultPadding)
        let titleLeftPadding: CGFloat = info.showCollapse ? 4 : textPadding()
        var image: UIImage?
        if info.showCollapse {
            if !info.collapse, light {
                image = UDIcon.expandDownFilled.ud.withTintColor(UDColor.colorfulBlue)
            } else if !info.collapse, !light {
                image = UDIcon.expandDownFilled.ud.withTintColor(UDColor.N600)
            } else if info.collapse, light {
                image = UDIcon.expandRightFilled.ud.withTintColor(UDColor.colorfulBlue)
            } else if info.collapse, !light {
                image = UDIcon.expandRightFilled.ud.withTintColor(UDColor.N600)
            }
        }
        iconContainer.isHidden = !info.showCollapse
        imageView.image = image

        iconContainer.snp.remakeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(titleLabelHeight)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(iconContainer.snp.right).offset(titleLeftPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(titleLabelHeight)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    func tapTitle() {
        delegate?.selectText(self, model: model)
    }

    @objc
    func tapImage() {
        delegate?.selectImage(self, model: model)
    }

    private func textPadding() -> CGFloat {
        guard let detail = model else { return 0 }
        let padding: CGFloat = detail.showCollapse ? 20 : 14
        return padding * CGFloat(detail.level - 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

public protocol CatalogBottomEntryViewDelegate: AnyObject {
    func didRequestOpenCatalogDetails(_ view: CatalogBottomEntryView)
}

public final class CatalogBottomEntryView: UIView {
    public weak var delegate: CatalogBottomEntryViewDelegate?
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = BundleI18n.SKResource.Doc_Doc_OpenStructure
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UDColor.colorfulBlue
        label.isUserInteractionEnabled = true
        return label
    }()

    public init(frame: CGRect, alignment: NSTextAlignment, fontZoomable: Bool) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.bgBody
        titleLabel.textAlignment = alignment
        addSubview(titleLabel)
        let enableZoomFontSize = fontZoomable
        var titleHeight = 20
        if enableZoomFontSize {
            titleLabel.font = UIFont.ud.body1(.s4)
            titleHeight = 20.auto(.s4)
        }
        if alignment == .center {
            titleLabel.snp.makeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(titleHeight)
                make.top.equalToSuperview().offset(10)
                make.centerX.equalToSuperview()
            }
        } else {
            titleLabel.snp.makeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(titleHeight)
                make.right.equalToSuperview().offset(-44)
                make.centerY.equalToSuperview()
            }
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didReceivedLabelClicked))
        titleLabel.addGestureRecognizer(tapGesture)
        let newTap = UITapGestureRecognizer(target: self, action: #selector(didReceivedLabelClicked))
        self.addGestureRecognizer(newTap)
    }

    public func displayTopShadow() {
        layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        layer.shadowOffset = CGSize(width: 5, height: -5)
        layer.shadowOpacity = 1
        layer.shadowRadius = 22
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didReceivedLabelClicked() {
        self.delegate?.didRequestOpenCatalogDetails(self)
    }
}
