//
//  WhiteboardPhoneSnapshotViewController.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/5.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import UniverseDesignColor
import UniverseDesignIcon
import LarkAlertController
import ByteViewNetwork
import UniverseDesignToast

enum SnapshotSelectedState: Int {
    case normal = 1
    case selected
}

struct WhiteboardSnapshotItem: Equatable {
    var image: UIImage?
    var index: Int
    var totalCount: Int
    var page: WhiteboardPage
    var whiteboardId: Int64
    var state: SnapshotSelectedState = .normal
    var isCompressed: Bool = true

    static func == (lhs: WhiteboardSnapshotItem, rhs: WhiteboardSnapshotItem) -> Bool {
        return lhs.page.pageID == rhs.page.pageID
    }
}

protocol DeleteWhiteboardPageDeledate: AnyObject {
    func deletePage(item: WhiteboardSnapshotItem?)
}

// MARK: Cell
class WhiteboardPhoneSnapshotCell: SnapshotBaseCell {
    fileprivate enum Layout {
        static let labelMarginTop: CGFloat = 8
        static let labelFont: CGFloat = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        indexLabel.font = UIFont.systemFont(ofSize: 12)
        self.contentView.addSubview(indexLabel)
        indexLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(18)
        }
        self.contentView.addSubview(snapshotImageView)
        snapshotImageView.snp.makeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(indexLabel.snp.top).offset(-Layout.labelMarginTop)
        }
        self.contentView.addSubview(selectedView)
        selectedView.snp.makeConstraints { maker in
            maker.edges.equalTo(snapshotImageView)
        }
        let image = UDIcon.getIconByKey(.closeFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
        deleteButton.setImage(image, for: .normal)
        self.contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.right.top.equalToSuperview().inset(4)
            maker.size.equalTo(CGSize(width: 20, height: 20))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configCell(with item: WhiteboardSnapshotItem) {
        super.configCell(with: item)
        indexLabel.text = "\(item.index)/\(item.totalCount)"
        if let image = item.image {
            snapshotImageView.image = image
        } else {
            snapshotImageView.backgroundColor = WhiteboardViewModel.currentTheme.color
        }
    }
}

class WhiteboardPhoneSnapshotViewController: WhiteboardSnapshotBaseViewController {

    let itemMinimumLineSpacing: CGFloat = 24
    var itemMinimumInteritemSpacing: CGFloat {
        self.view.isPhoneLandscape ? 10 : 9
    }
    var itemSize: CGSize {
        let size = self.view.isPhoneLandscape ? CGSize(width: 189, height: 136) : CGSize(width: 167, height: 120)
        return size
    }

    var scaleLayerBlock: (() -> Void)?
    var resetMiniScaleBlock: (() -> Void)?
    let userId: String
    let whiteboardId: Int64
    let maxPageCount: Int
    private var items: [WhiteboardSnapshotItem] = []
    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    // 由于在pan页面弹一个pan页面，因此自定义导航栏
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        return button
    }()

    // 新建白板页面
    private lazy var createNewPageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.setBackgroundColor(UIColor.ud.primaryContentLoading, for: .disabled)
        button.addTarget(self, action: #selector(createNewPage), for: .touchUpInside)
        button.setTitle(BundleI18n.Whiteboard.View_MV_NewBoardsButton, for: .normal)
        button.addInteraction(type: .lift)
        return button
    }()

    private lazy var loadingView = LoadingView(frame: CGRect(x: 0, y: 0, width: 36, height: 36), style: .white)

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = itemSize
        layout.minimumLineSpacing = itemMinimumLineSpacing
        layout.minimumInteritemSpacing = itemMinimumInteritemSpacing
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.register(WhiteboardPhoneSnapshotCell.self, forCellWithReuseIdentifier: WhiteboardPhoneSnapshotCell.description())
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = true
        return collection
    }()

    private lazy var naviBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Whiteboard.View_MV_OtherBoardsTitle
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()

    init(items: [WhiteboardSnapshotItem], userId: String, whiteboardId: Int64, maxPageCount: Int) {
        self.userId = userId
        self.whiteboardId = whiteboardId
        self.maxPageCount = maxPageCount
        self.items = items.sorted(by: { $0.index < $1.index })
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.right.equalToSuperview().inset(16)
            maker.centerX.equalToSuperview()
            if self.view.isPhoneLandscape {
                maker.height.equalTo(48)
            } else {
                maker.height.equalTo(56)
            }
        }
        naviBar.addSubview(backButton)
        naviBar.addSubview(titleLabel)
        backButton.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        view.addSubview(line)
        line.isHidden = self.view.isPhoneLandscape ? false : true
        line.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(naviBar.snp.bottom)
            maker.height.equalTo(0.5)
        }
        view.addSubview(createNewPageButton)
        createNewPageButton.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(16)
            maker.height.equalTo(48)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.top.equalTo(line.snp.bottom)
            maker.left.right.equalToSuperview().inset(16)
            maker.bottom.equalTo(createNewPageButton.snp.top).offset(-16)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            if Display.phone {
                self.remakeLayout()
                self.configCellsize()
            }
        }
    }

    private func configCellsize() {
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.minimumInteritemSpacing = 0
        layout?.itemSize = itemSize
        layout?.minimumLineSpacing = itemMinimumLineSpacing
        layout?.minimumInteritemSpacing = itemMinimumInteritemSpacing
        layout?.prepare()
        layout?.invalidateLayout()
    }

    // 重约束导航栏高度
    private func remakeLayout() {
        line.isHidden = !self.view.isPhoneLandscape
        naviBar.snp.remakeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.right.equalToSuperview().inset(16)
            maker.centerX.equalToSuperview()
            if self.view.isPhoneLandscape {
                maker.height.equalTo(48)
            } else {
                maker.height.equalTo(56)
            }
        }
    }

    private func getSelectedIndex() -> Int? {
        for (index, item) in self.items.enumerated() {
            if item.state == .selected {
                return index
            }
        }
        return nil
    }

    func resetItems(items: [WhiteboardSnapshotItem]) {
        DispatchQueue.main.async {
            self.items = items.sorted(by: { $0.index < $1.index })
            self.collectionView.reloadData()
            if let index = self.getSelectedIndex() {
                let lastItemIndex = IndexPath(item: index, section: 0)
                self.collectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: true)
            }
        }
    }

    func reloadItem(item: WhiteboardSnapshotItem) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0 == item }) {
                self.items[index] = item
                let indexPath = IndexPath(row: index, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }

    func changeMultiPageInfo(currentPageNum: Int32) {
        DispatchQueue.main.async {
            // 更新正在共享页码框选
            for index in self.items.indices {
                if self.items[index].page.pageNum == currentPageNum {
                    self.items[index].state = .selected
                } else {
                    self.items[index].state = .normal
                }
            }
            self.collectionView.reloadData()
        }
    }

    func showLoading(_ isLoading: Bool, isFailed: Bool = false) {
        DispatchQueue.main.async {
            if isLoading {
                self.createNewPageButton.isEnabled = false
                self.createNewPageButton.addSubview(self.loadingView)
                let offset = self.createNewPageButton.titleLabel?.text?.vc.boundingWidth(height: 48, font: .systemFont(ofSize: 17)) ?? 0
                self.loadingView.snp.remakeConstraints { (maker) in
                    maker.right.equalTo(self.createNewPageButton.snp.centerX).offset(-offset / 2.0)
                    maker.centerY.equalToSuperview()
                    maker.size.equalTo(CGSize(width: 16, height: 16))
                }
                self.loadingView.play()
                self.createNewPageButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            } else {
                self.createNewPageButton.isEnabled = true
                self.createNewPageButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                self.loadingView.stop()
                self.loadingView.removeFromSuperview()
            }
        }
    }

    @objc func dismissAction() {
        DispatchQueue.main.async {
            self.presentingViewController?.dismiss(animated: true)
        }
    }
}

// MARK: TableView
extension WhiteboardPhoneSnapshotViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WhiteboardPhoneSnapshotCell.description(), for: indexPath) as? WhiteboardPhoneSnapshotCell else {
            return UICollectionViewCell()
        }
        cell.configCell(with: items[indexPath.row])
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for i in 0..<items.count {
            items[i].state = .normal
        }
        items[indexPath.row].state = .selected
        collectionView.reloadData()
        // 切换共享页面
        let pageNum = items[indexPath.row].page.pageNum
        let page: WhiteboardPage = WhiteboardPage(pageID: items[indexPath.row].page.pageID, pageNum: pageNum, isSharing: true)
        WhiteboardTracks.trackBoardClick(.multiBoardSelectPage(pageNum: Int(pageNum)), whiteboardId: whiteboardId)
        let request = OperateWhiteboardPageRequest(action: .changeSharePage, whiteboardId: items[indexPath.row].whiteboardId, pages: [page])
        HttpClient(userId: userId).getResponse(request) { [weak self] r in
            switch r {
            case .success:
                logger.info("operateWhiteboardPage changeSharePage success")
                self?.resetMiniScaleBlock?()
            case .failure(let error):
                logger.info("operateWhiteboardPage changeSharePage error: \(error)")
            }
            self?.dismissAction()
        }
    }
}

// MARK: deletePage And CreatePage
extension WhiteboardPhoneSnapshotViewController: DeleteWhiteboardPageDeledate {
    func deletePage(item: WhiteboardSnapshotItem?) {
        self.deleteOnePage(item: item, whiteboardId: self.whiteboardId, userId: self.userId)
    }

    @objc func createNewPage() {
        // 上限maxPageCount页, 可配置
        guard self.items.count < maxPageCount else {
            let config = UDToastConfig(toastType: .info, text: BundleI18n.Whiteboard.View_G_MaxBoardCreateNote(maxPageCount), operation: nil)
            UDToast.showToast(with: config, on: view)
            return
        }
        guard let item = items.last else { return }
        showLoading(true)
        let newPage = WhiteboardPage(pageID: 0, pageNum: item.page.pageNum + 1, isSharing: true)
        WhiteboardTracks.trackBoardClick(.newBoard, whiteboardId: whiteboardId)
        let request = OperateWhiteboardPageRequest(action: .newPage, whiteboardId: item.whiteboardId, pages: [item.page, newPage])
        HttpClient(userId: userId).getResponse(request) { [weak self] r in
            switch r {
            case .success:
                logger.info("operateWhiteboardPage newPage success")
                self?.showLoading(false)
                self?.scaleLayerBlock?()
            case .failure(let error):
                self?.showLoading(false, isFailed: true)
                logger.info("operateWhiteboardPage newPage error: \(error)")
            }
            self?.dismissAction()
        }
    }
}

extension WhiteboardPhoneSnapshotViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        line.isHidden = !isRegular
    }
}

extension WhiteboardPhoneSnapshotViewController: PanChildViewControllerProtocol {
    public var panScrollable: UIScrollView? {
        return nil
    }

    public var showDragIndicator: Bool {
        return false
    }

    public var showBarView: Bool {
        return false
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        if Display.phone, axis == .landscape {
            return .maxHeightWithTopInset(8)
        }
        return .maxHeightWithTopInset(44 + (view.window?.safeAreaInsets.top ?? 0))
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        vc.setBackgroundColor(color, for: state)
    }
}
