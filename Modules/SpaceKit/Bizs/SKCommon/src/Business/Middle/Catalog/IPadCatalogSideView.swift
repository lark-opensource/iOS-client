//
//  IPadCatalogSideView.swift
//  SKDoc
//
//  Created by lizechuang on 2021/3/31.
//

import SKFoundation
import SKResource
import ThreadSafeDataStructure
import UniverseDesignColor
import UniverseDesignEmpty

public final class IPadCatalogSideView: UIView {
    private var status: IpadCatalogStatus
    private var mode: IPadCatalogMode = .covered
    private var items: SafeArray<CatalogItemDetail> = [] + .readWriteLock
    private var curIdentifier: String = ""
    private var curIndex: Int {
        if let index = self.items.firstIndex(where: { $0.identifier == curIdentifier }) {
            return index
        }
        return -1
    }

    public var isShown = false
    private var _darkModeEnable: Bool = true
    private var darkModeEnable: Bool {
        get {
            return _darkModeEnable
        }
        set {
            _darkModeEnable = newValue
            if #available(iOS 13.0, *) {
                self.overrideUserInterfaceStyle = _darkModeEnable ? .unspecified : .light
            }
        }
    }
    public weak var delegate: IPadCatalogSideViewDelegate?

    private var _curKeyboardHeight: CGFloat = 0
    public var curKeyboardHeight: CGFloat {
        get {
            return _curKeyboardHeight
        }
        set {
            guard newValue != _curKeyboardHeight else {
                return
            }
            _curKeyboardHeight = newValue
            var curContentInset = collectionView.contentInset
            curContentInset.bottom = _curKeyboardHeight
            collectionView.contentInset = curContentInset
            collectionView.layoutIfNeeded()
        }
    }

    // view
    private var layout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        return layout
    }
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // 目录这里的防护不需要toast,因为正文已经有了
        return preventer
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(CatalogSideViewCell.self, forCellWithReuseIdentifier: String(describing: CatalogSideViewCell.self))
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Docs_Outline_Placeholder),
                                                  imageSize: 100,
                                                  type: .noContent,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        // 不用userCenterConstraints会非常不雅观
        emptyView.useCenterConstraints = true
        let container = self.getViewContainer()
        container.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return emptyView
    }()
    
    public var docsInfo: DocsInfo?

    private var loadingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        view.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        return view
    }()

    public init(frame: CGRect, status: IpadCatalogStatus, darkModeEnable: Bool, details: [CatalogItemDetail]) {
        self.status = status
        super.init(frame: frame)
        self.items.append(contentsOf: details)
        self.backgroundColor = UDColor.bgBody
        if ViewCapturePreventer.isFeatureEnable {
           addSubview(viewCapturePreventer.contentView)
           viewCapturePreventer.contentView.snp.makeConstraints {
               $0.edges.equalToSuperview()
           }
        }
        setupUI()
        self.darkModeEnable = darkModeEnable
    }

    public func reload(_ detail: [CatalogItemDetail]) {
        if detail.isEmpty {
            status = .empty
        } else {
            status = .normal
        }
        self.items.replaceInnerData(by: detail)
        self.setupUI()
        self.collectionView.reloadData()
    }

    // present的时候有一定概率当前的高度不对
    public func setIPadCatalogMode(_ mode: IPadCatalogMode, docsInfo: DocsInfo?, browserHeight: CGFloat) {
        let needReloadEmpty = (self.mode != mode) && (self.status == .empty)
        self.docsInfo = docsInfo
        self.mode = mode
        if needReloadEmpty {
            // 用于切换mode情况更新当前面板，只有.empty情况用到
            self.hiddenEmptyView()
            self.setupUI()
        } else {
            collectionView.contentInset = UIEdgeInsets(top: calculateContentInsetY(browserHeight: browserHeight), left: 0, bottom: curKeyboardHeight, right: 0)
            self.collectionView.reloadData()
        }
        showShadow(mode == .covered)
    }

    public func setHighlightCatalogItemWith(_ identifier: String) {
        guard !self.collectionView.isHidden, identifier != curIdentifier else {
            return
        }
        if self.curIndex >= 0, let oldCell = collectionView.cellForItem(at: IndexPath(row: self.curIndex, section: 0)) as? CatalogSideViewCell {
            oldCell.highlight(false, shouldSetCorner: false)
        }
        self.curIdentifier = identifier
        if self.curIndex >= 0, let curCell = collectionView.cellForItem(at: IndexPath(row: self.curIndex, section: 0)) as? CatalogSideViewCell {
            curCell.highlight(true, shouldSetCorner: true && mode == .embedded)
        }
        DispatchQueue.main.async {
            if self.curIndex >= 0, !self.items.isEmpty {
                self.collectionView.scrollToItem(at: IndexPath(row: self.curIndex, section: 0), at: .centeredVertically, animated: false)
            }
        }
    }

    public func updateLayout() {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        switch self.status {
        case .loading:
            showLoading()
            hiddenCollectionView()
            hiddenEmptyView()
        case .empty:
            showEmptyView()
            hiddenCollectionView()
            hiddenLoading()
        case .normal:
            showCollectionView()
            hiddenEmptyView()
            hiddenLoading()
        }
    }
}

// MARK: - Action
extension IPadCatalogSideView {
    private func showCollectionView() {
        if collectionView.superview == nil {
            let container = getViewContainer()
            container.addSubview(collectionView)
            collectionView.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(8)
            }
        }
        collectionView.isHidden = false
        collectionView.contentInset = UIEdgeInsets(top: calculateContentInsetY(), left: 0, bottom: curKeyboardHeight, right: 0)
    }
    private func hiddenCollectionView() {
        collectionView.isHidden = true
    }

    private func showEmptyView() {
        emptyView.isHidden = false
    }
    private func hiddenEmptyView() {
        emptyView.isHidden = true
    }

    private func showLoading() {
        if loadingIndicatorView.superview == nil {
            let container = getViewContainer()
            container.addSubview(loadingIndicatorView)
            loadingIndicatorView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        }
        loadingIndicatorView.isHidden = false
        loadingIndicatorView.startAnimating()
    }

    private func hiddenLoading() {
        loadingIndicatorView.isHidden = true
        loadingIndicatorView.stopAnimating()
    }

    private func calculateContentInsetY(browserHeight: CGFloat? = nil) -> CGFloat {
        var yInset = IPadCatalogConst.contentInsetY
        if mode == .embedded {
            let holdInsetY = ((browserHeight ?? self.frame.height) - CGFloat(self.items.count) * IPadCatalogConst.lindHeight) / 2.0
            yInset = holdInsetY > 0 ? holdInsetY : IPadCatalogConst.contentInsetY
        }
        return yInset
    }

    private func showShadow(_ show: Bool) {
        if show {
            self.layer.shadowRadius = 8
            self.layer.ud.setShadowColor(UDColor.shadowDefaultMd)
            self.layer.shadowOpacity = 1.0
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
        } else {
            self.layer.shadowRadius = 0
            self.layer.shadowColor = nil
        }
    }
}

extension IPadCatalogSideView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CatalogSideViewCell.self), for: indexPath)
        guard let cell1 = cell as? CatalogSideViewCell else {
            return cell
        }
        let item = items[indexPath.row]
        cell1.configure(by: item, fontZoomable: docsInfo?.fontZoomable == true)
        cell1.highlight(item.identifier == curIdentifier, shouldSetCorner: item.identifier == curIdentifier && mode == .embedded)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: IPadCatalogConst.lindHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let item = self.items[indexPath.row]
        if item.identifier != self.curIdentifier {
            if let curCell = collectionView.cellForItem(at: indexPath) as? CatalogSideViewCell {
                curCell.highlight(true, shouldSetCorner: true && mode == .embedded)
            }
            if self.curIndex >= 0, let oldCell = collectionView.cellForItem(at: IndexPath(row: self.curIndex, section: 0)) as? CatalogSideViewCell {
                oldCell.highlight(false, shouldSetCorner: false)
            }
            self.curIdentifier = item.identifier
        }
        delegate?.didClickItem(item, mode: mode)
    }
}

// MARK: - 防截图
extension IPadCatalogSideView {
    
    /// 设置允许被截图
    public func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
    
    private func getViewContainer() -> UIView {
        if ViewCapturePreventer.isFeatureEnable { // 功能可用时，子视图都加在防截图视图上
            return viewCapturePreventer.contentView
        } else {
            return self
        }
    }
}
