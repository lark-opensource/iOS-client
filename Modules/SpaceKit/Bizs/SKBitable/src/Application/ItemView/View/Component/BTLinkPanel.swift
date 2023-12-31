//
// Created by duanxiaochen.7 on 2021/7/26.
// Affiliated with SKBitable.
//
// Description:
//swiftlint:disable file_length type_body_length

import UIKit
import RxCocoa
import RxSwift
import RxRelay
import SKCommon
import SKUIKit
import SKResource
import SKBrowser
import HandyJSON
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignFont
import UniverseDesignEmpty
import UniverseDesignShadow
import UniverseDesignLoading
import SKFoundation

enum BTLinkPanelMode {
    case noPermission
    case tableDeleted
    case filterInfoError(msg: String)
    case listEmpty(tableMeta: BTTableMeta)
    case searchEmpty(tableMeta: BTTableMeta)
    case showData(tableMeta: BTTableMeta, records: [BTRecordModel])
    case stopLoadingMore(requestType: BTCardFetchType, hasMore: Bool)
}

final class BTLinkPanel: UIView {

    private let disposeBag = DisposeBag()

    var couldLinkMultipleRecords: Bool = false
    var linkFieldMetaEmpty: Bool {
        get { viewModel.linkFieldMetaEmpty }
        set { viewModel.linkFieldMetaEmpty = newValue }
    }

    var couldCreateAndLinkNewRecords: Bool = false { // 仅当索引列是文本字段时允许边搜索边新建记录
        didSet {
            if couldCreateAndLinkNewRecords {
                searchView.searchTextField.placeholder = BundleI18n.SKResource.Bitable_Relation_SearchOrAddRecord
            } else {
                searchView.searchTextField.placeholder = BundleI18n.SKResource.Bitable_Relation_SearchRecord
            }
        }
    }

    private var viewModel: BTLinkPanelViewModelProtocol

    private var records: [BTRecordModel] = []

    private weak var delegate: BTLinkPanelDelegate?

    private weak var gestureManager: BTPanGestureManager!

    private var keyboard: Keyboard?
    
    //根据键盘高度计算view距离底部的offset，避免被键盘挡住
    private var bottomOffset: CGFloat = 0
    
    //superView距离屏幕底部的距离，用来适配VC场景下的键盘高度
    private var superViewBottomOffset: CGFloat
    
    //tableView的数据正在刷新中，不触发分页请求
    private var dataIsReloading: Bool = false
    
    //顶部可见cell的偏移量，用来收到数据更新时保持当前的可视区域
    private var firstVisibleCellOffset: CGFloat?
    
    //关联字段是否是文本类型
    private var linkFieldIsText: Bool = false

    private lazy var dragView = UIView().construct { it in
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panToChangeSize(sender:)))
        it.addGestureRecognizer(panGestureRecognizer)
        it.backgroundColor = UDColor.bgFloat
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
        it.layer.masksToBounds = true
        let line = UIView()
        line.backgroundColor = UDColor.lineBorderCard
        line.layer.cornerRadius = 2
        it.addSubview(line)
        line.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(4)
        }

        it.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(line.snp.bottom).offset(8)
            make.height.equalTo(24)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    private lazy var contentView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
    }

    private lazy var searchView: BTSearchView = BTSearchView().construct { it in
        let bottomSeparator = UIView()
        bottomSeparator.backgroundColor = UDColor.lineDividerDefault

        it.addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    // 无权限提示View，强业务样式，非UDstyle
    private lazy var noPermView: LinkPanelNoPermissionView = LinkPanelNoPermissionView().construct { it in
        let line = UIView()
        line.backgroundColor = UDColor.lineDividerDefault
        it.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    func setNoPermTips(hidden: Bool) {
        if hidden {
            noPermView.snp.remakeConstraints { make in
                make.top.equalTo(searchView.snp.bottom).offset(-1)
                make.left.right.equalToSuperview()
                make.height.equalTo(0)
            }
            noPermView.isHidden = true
        } else {
            noPermView.snp.remakeConstraints { make in
                make.top.equalTo(searchView.snp.bottom).offset(-1)
                make.left.right.equalToSuperview()
                make.height.equalTo(24)
            }
            noPermView.isHidden = false
        }
    }
    private var hasClickNewRecordButton = false
    private lazy var newRecordItemContainerView = UIView().construct { it in
        it.clipsToBounds = true
        it.layer.cornerRadius = 4
        it.backgroundColor = UDColor.bgFloatOverlay
        it.isUserInteractionEnabled = false
    }
    
    private lazy var newRecordButton = CustomAddLinkButton(type: .custom).construct { it in
        it.backgroundColor = UDColor.bgFloat
        
        let addImage = UIImageView(image: UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 16, height: 16)))
        it.addSubview(addImage)
        
        addImage.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        it.addSubview(newRecordLabel)
        newRecordLabel.snp.makeConstraints { make in
            make.left.equalTo(addImage.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        it.addSubview(newRecordItemContainerView)

        newRecordItemContainerView.snp.makeConstraints { make in
            make.left.equalTo(newRecordLabel.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(26)
            make.right.lessThanOrEqualToSuperview()
        }

        newRecordItemContainerView.addSubview(newRecordItemView)
        newRecordItemView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        let bottomSeparator = UIView()
        bottomSeparator.backgroundColor = UDColor.lineDividerDefault

        it.addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    private lazy var newRecordItemView = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textTitle
    }

    private lazy var newRecordLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
        it.text = BundleI18n.SKResource.Bitable_Mobile_AddRecord_Button
    }

    // MARK: 覆盖整个面板的空状态
    private lazy var panelEmptyView = BTEmptyView().construct { it in
        it.updateUIConfig(BTEmptyView.UIConfig(backgroudColor: UDColor.bgFloat))
    }

    // MARK: 覆盖 tableView 的空状态

    private lazy var listEmptyView = BTEmptyView().construct { it in
        it.updateUIConfig(BTEmptyView.UIConfig(backgroudColor: UDColor.bgFloat))
    }
    
    private lazy var listEmptyViewContainer: UIView = UIView().construct { it in
        it.addSubview(listEmptyView)
        listEmptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.centerY.greaterThanOrEqualToSuperview()
        }
    }

    private lazy var recordList = UITableView(frame: .zero, style: .plain).construct { it in
        it.register(BTLinkRecordCell.self, forCellReuseIdentifier: BTLinkRecordCell.reuseIdentifier)
        it.backgroundColor = UDColor.bgFloat
        it.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        it.dataSource = self
        it.delegate = self
        it.keyboardDismissMode = .onDrag
        it.contentInsetAdjustmentBehavior = .never
        it.separatorStyle = .none
    }
    
    private let loadingViewManager = BTLaodingViewManager()
    
    var firstRecordID: String? {
        for record in records {
            if !viewModel.placedTopRecordIds.contains(record.recordID) {
                //除去被置顶的record的第一个recordId
                return record.recordID
            }
        }
        
        return records.first?.recordID
    }
    
    var lastRecordID: String? {
        return records.last?.recordID
    }
    
    //非置顶的所有可见record的ID
    var visibleRecordIDsNotPlacedTop: [String] {
        guard !shouldFetchStartTop else {
            return []
        }
        
        return recordList.visibleCells.compactMap { cell -> String? in
            //除去被置顶的record
            guard let recordId = (cell as? BTLinkRecordCell)?.model.id,
                  !viewModel.placedTopRecordIds.contains(recordId) else {
                return nil
            }
            return recordId
        }
    }
    
    //非置顶的第一个record的index
    var firstVisibleRecordIdxNotPlacedTop: Int {
        guard !shouldFetchStartTop else {
            return 0
        }
        let firstRecordID = firstRecordID
        return records.firstIndex(where: { $0.recordID == firstRecordID }) ?? 0
    }
    
    //包含置顶的第一个recordId
    var firstVisibleRecordID: String? {
        guard !shouldFetchStartTop else {
            return nil
        }
        return (recordList.visibleCells.first as? BTLinkRecordCell)?.model.id
    }

    var currentVisibleRecordsCount: Int {
        guard !shouldFetchStartTop else {
            return 0
        }
        
        return recordList.visibleCells.count
    }
    
    //是否从0开始请求
    var shouldFetchStartTop: Bool {
        return recordList.isHidden || hasClickNewRecordButton
    }
    
    private weak var dataSource: BTLinkPanelDataSource?

    init(gestureManager: BTPanGestureManager,
         delegate: BTLinkPanelDelegate,
         dataSource: BTLinkPanelDataSource,
         superViewBottomOffset: CGFloat) {
        self.gestureManager = gestureManager
        self.delegate = delegate
        self.superViewBottomOffset = superViewBottomOffset
        if UserScopeNoChangeFG.YY.baseAddRecordPage {
            self.dataSource = dataSource
            let linkFieldContext = dataSource.linkFiledContext
            self.viewModel = linkFieldContext.viewMode == .addRecord ? BTRecordLinkPanelViewModel(delegate: delegate, dataSource: dataSource) : BTLinkPanelViewModel(delegate: delegate, dataSource: dataSource, mode: dataSource.nextMode)
        } else {
            self.viewModel = BTLinkPanelViewModel(delegate: delegate, dataSource: dataSource, mode: dataSource.nextMode)
        }
        super.init(frame: .zero)
        layer.ud.setShadow(type: .s4Up)
        setupViews()
        bindAction()
        bindData()
        startKeyboardObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func panToChangeSize(sender: UIPanGestureRecognizer) {
        gestureManager?.panToChangeSize(ofPanel: self, sender: sender)
    }

    func updateSelectedRecords(_ models: [BTRecordModel]) {
        viewModel.updateSelectedRecords(models)
    }

    func reloadViews(_ type: BTCardFetchType) {
        viewModel.reloadTable(type)
    }

    func hide(immediately: Bool) {
        if immediately {
            removeFromSuperview()
        } else {
            UIView.animate(withDuration: 0.25) {
                self.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
            } completion: { _ in
                self.removeFromSuperview()
            }
        }
        keyboard?.stop()
    }

    private func setupViews() {
        addSubview(dragView)
        addSubview(contentView)
        contentView.addSubview(panelEmptyView)
        contentView.addSubview(searchView)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            contentView.addSubview(noPermView)
        }
        contentView.addSubview(newRecordButton)
        contentView.addSubview(recordList)
        contentView.addSubview(listEmptyViewContainer)

        dragView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(42)
            make.left.right.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(dragView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        panelEmptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panelEmptyView.isHidden = true
        searchView.snp.makeConstraints { make in
            make.top.equalTo(dragView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            noPermView.snp.remakeConstraints { make in
                make.top.equalTo(searchView.snp.bottom).offset(-1)
                make.left.right.equalToSuperview()
                make.height.equalTo(24)
            }
        }
        newRecordButton.snp.makeConstraints { make in
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                make.top.equalTo(noPermView.snp.bottom)
            } else {
                make.top.equalTo(searchView.snp.bottom)
            }
            make.height.equalTo(0)
            make.left.right.equalToSuperview()
        }
        newRecordButton.isHidden = true
        listEmptyViewContainer.snp.makeConstraints { make in
            make.top.equalTo(newRecordButton.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        listEmptyViewContainer.isHidden = true
        recordList.snp.makeConstraints { make in
            make.top.equalTo(newRecordButton.snp.bottom)
            make.right.left.bottom.equalToSuperview()
        }
        addHeaderAndFooter()
        layoutIfNeeded()
    }
    
    private func bindAction() {
        searchView.searchTextField.rx.text.orEmpty.asDriver()
            .skip(1)
            .throttle(DispatchQueueConst.MilliSeconds_250)
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                self.viewModel.searchText = text
            })
            .disposed(by: disposeBag)
        searchView.rightButton.rx.tap.asSignal()
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                self.viewModel.searchText = ""
            })
            .disposed(by: disposeBag)
        searchView.searchTextField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                self?.delegate?.beginSearching()
            })
            .disposed(by: disposeBag)
        newRecordButton.rx.tap.asSignal()
            .emit(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let searchText = self.searchView.searchTextField.text, !searchText.isEmpty {
                    self.delegate?.createAndLinkNewRecord(primaryText: self.linkFieldIsText ? searchText : nil)
                    self.hasClickNewRecordButton = true
                    if !self.couldLinkMultipleRecords {
                        self.delegate?.finishLinking(self)
                    } else {
                        self.cancelSearch()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindData() {
        viewModel.updateLinkPanelSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] mode in
                guard let `self` = self else { return }
                self.hideLoading()
                self.hasClickNewRecordButton = false
                switch mode {
                case .noPermission:
                    self.clearPanel(emptyType: .noAccess(desc: BundleI18n.SKResource.Bitable_Relation_NoPermissionToViewLinkedTable))
                case .tableDeleted:
                    self.titleLabel.isHidden = true
                    self.clearPanel(emptyType: .showNoData(desc:
                                                            BundleI18n.SKResource.Bitable_Relation_LinkedTableWasDeleted))
                case .filterInfoError(let msg):
                    self.clearPanel(emptyType: .showNoData(desc: msg))
                case .listEmpty(let tableMeta):
                    self.setAddRecordButton()
                    self.setupMetaInfo(tableMeta)
                    self.setListEmpty(emptyType: .showNoData(desc: BundleI18n.SKResource.Bitable_Relation_NoResultFound))
                    DocsLogger.btInfo("[BTLinkPanle] listEmpty")
                case .searchEmpty(let tableMeta):
                    self.setAddRecordButton()
                    self.setupMetaInfo(tableMeta)
                    self.setListEmpty(emptyType: .showNoRearchResult(desc: BundleI18n.SKResource.Bitable_Relation_NoResultFound))
                    DocsLogger.btInfo("[BTLinkPanle] searchEmpty")
                case let .stopLoadingMore(requestType, hasMore):
                    switch requestType {
                    case .linkCardTop:
                        self.finishLoadTopData()
                        self.setEnableLoadTopMore(enable: hasMore)
                    case .linkCardBottom:
                        if dataSource?.linkFiledContext.viewMode == .addRecord {
                            if hasMore {
                                self.startLoadBottomData()
                            }
                        } else {
                            self.finishLoadBottomData()
                        }
                        self.setEnableLoadBottomMore(enable: hasMore)
                    default:
                        break
                    }
                case let .showData(tableMeta, records):
                    DocsLogger.btInfo("[BTLinkPanle] update records count: \(records.count)")
                    self.setupMetaInfo(tableMeta)
                    self.setFirstVisibleCellOffset()
                    self.records = records
                    self.panelEmptyView.isHidden = true
                    self.listEmptyViewContainer.isHidden = true
                    self.searchView.isHidden = false
                    self.titleLabel.isHidden = false
                    self.recordList.isHidden = false
                    if dataSource?.linkFiledContext.viewMode == .addRecord {
                        self.searchView.isHidden = false
                    }
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.recordList.reloadData()
                    self.dataIsReloading = true
                    CATransaction.setCompletionBlock { [weak self] in
                        self?.dataIsReloading = false
                    }
                    CATransaction.commit()
                    self.setAddRecordButton()
                }
            }).disposed(by: disposeBag)
    }
    
    private func setFirstVisibleCellOffset() {
        //更新列表前记录顶部可见第一个cell的offset
        guard let firstVisibleCell = recordList.visibleCells.first else {
            return
        }
        
        let cellFramInContentView = recordList.convert(firstVisibleCell.frame, to: contentView)
        firstVisibleCellOffset = recordList.frame.minY - cellFramInContentView.minY
        DocsLogger.btInfo("[BTLinkPanel] currentVisibleRecordIDs cellFramInContentView:\(cellFramInContentView) firstVisibleCellOffset:\(String(describing: firstVisibleCellOffset))")
    }
    
    private func setAddRecordButton() {
        let searchText = viewModel.searchText
        newRecordItemView.text = linkFieldIsText ? searchText : nil
        let shouldShowCreateNewRecordView = !searchText.isEmpty && self.couldCreateAndLinkNewRecords
        newRecordButton.snp.updateConstraints { make in
            make.height.equalTo(shouldShowCreateNewRecordView ? 50 : 0)
        }
        newRecordButton.isHidden = !shouldShowCreateNewRecordView
        newRecordItemContainerView.isHidden = !linkFieldIsText
    }

    private func cancelSearch() {
        searchView.searchTextField.text = nil
        searchView.searchTextField.endEditing(true)
        searchView.hideRightButton()
    }

    private func clearPanel(emptyType: BTEmptyView.ShowType) {
//        titleLabel.isHidden = true
        searchView.isHidden = true
        newRecordButton.isHidden = true
        listEmptyViewContainer.isHidden = true
        recordList.isHidden = true
        
        panelEmptyView.updateShowType(emptyType)
        panelEmptyView.isHidden = false
    }

    private func setListEmpty(emptyType: BTEmptyView.ShowType) {
        panelEmptyView.isHidden = true
        titleLabel.isHidden = false
        searchView.isHidden = false
        recordList.isHidden = true
        
        listEmptyView.updateShowType(emptyType)
        listEmptyViewContainer.isHidden = false
    }

    private func setupMetaInfo(_ tableMeta: BTTableMeta) {
        let fieldMeta = tableMeta.fields[tableMeta.primaryFieldId]
        linkFieldIsText = fieldMeta?.compositeType.uiType == .text || (fieldMeta?.compositeType.uiType == .barcode && fieldMeta?.allowedEditModes.manual == true)
        couldCreateAndLinkNewRecords = tableMeta.recordAddable
        if !UserScopeNoChangeFG.ZJ.btLinkPanelCreatRecordOpt {
            couldCreateAndLinkNewRecords = couldCreateAndLinkNewRecords && linkFieldIsText
        }
        if viewModel.mode == .addRecord {
            couldCreateAndLinkNewRecords = false    // 记录新建页目前暂不支持添加关联记录
        }
        if tableMeta.isPartial {
            // 按需加载的文档不支持新建关联记录
            couldCreateAndLinkNewRecords = false
        }
        titleLabel.text = BundleI18n.SKResource.Bitable_Relation_From(tableMeta.tableName)
    }

    private func startKeyboardObserver() {
        keyboard = Keyboard(listenTo: [searchView.searchTextField], trigger: "bitablelink")
        keyboard?.on(events: [.willShow, .didShow]) { [weak self] option in
            guard let self = self else { return }
            let realKeyboardHeight = option.endFrame.height - self.superViewBottomOffset

            let remainHeightExceptKeyboard = self.bounds.height - 152
            var remainHeight = remainHeightExceptKeyboard - realKeyboardHeight

            remainHeight = max(133, remainHeight)

            let bottomOffset = remainHeightExceptKeyboard - remainHeight

            self.bottomOffset = bottomOffset
            UIView.performWithoutAnimation {
                self.listEmptyViewContainer.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-bottomOffset)
                }
                
                self.loadingViewManager.updateLoadingViewBottomOffset(bottomOffset)
                self.layoutIfNeeded()
            }
        }

        keyboard?.on(events: [.willHide, .didHide]) { [weak self] _ in
            guard let self = self else { return }
            
            self.bottomOffset = 0
            UIView.performWithoutAnimation {
                self.listEmptyViewContainer.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                
                self.loadingViewManager.updateLoadingViewBottomOffset(0)
                
                self.layoutIfNeeded()
            }
        }
        keyboard?.start()

    }
    
    func startLoadingTimer(hideSearchView: Bool = true) {
        DocsLogger.btInfo("[BTLinkPanle] startLoadingTimer")
        self.perform(#selector(type(of: self).showLoading), with: nil, afterDelay: 0.2)
    }

    @objc
    private func showLoading() {
        DocsLogger.btInfo("[BTLinkPanle] showLoading")
        listEmptyViewContainer.isHidden = true
        recordList.isHidden = true
        newRecordButton.isHidden = true
        if dataSource?.linkFiledContext.viewMode == .addRecord {
            titleLabel.isHidden = true
            searchView.isHidden = true
            loadingViewManager.showLoading(superView: contentView)
        } else {
            loadingViewManager.showLoading(superView: contentView,
                                           minTop: searchView.bounds.height,
                                           centeryOffset: bottomOffset)
        }
    }

    private func hideLoading() {
        DocsLogger.btInfo("[BTLinkPanle] hideLoading")
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        loadingViewManager.hideLoading()
    }
    
    //显示超时重试页面
    func showTryAgainEmptyView(text: String, type: UDEmptyType, tryAgainBlock: (() -> Void)? = nil) {
        DocsLogger.btInfo("[BTLinkPanle] showTryAgainEmptyView")
        hideLoading()
        var newEmptyConfig = UDEmptyConfig(type: type)
        newEmptyConfig.description = .init(descriptionText: text)
        if let tryAgainBlock = tryAgainBlock {
            newEmptyConfig.primaryButtonConfig = (BundleI18n.SKResource.Bitable_Common_ButtonRetry, { [weak self] _ in
                DocsLogger.btInfo("[BTLinkPanle] didClick tryAgain button")
                tryAgainBlock()
                self?.listEmptyViewContainer.isHidden = true
                self?.showLoading()
            })
        }
        listEmptyView.updateConfig(newEmptyConfig)
        setListEmpty(emptyType: .show)
    }
    
    
    /// 滚动列表到指定的index
    /// - Parameters:
    ///   - index: 滚动的位置
    ///   - animated: 是否需要滚动动画
    ///   - needFixOffest: 是否需要设置上次列表顶部cell的偏移量，用来更新列表数量时保持列表的偏移量
    func scrollToIndex(index: Int, animated: Bool = false, needFixOffest: Bool = false) {
        DocsLogger.btInfo("[BTLinkPanel] scrollToIndex index:\(index)")
        guard !recordList.isHidden, records.count > index else {
            DocsLogger.btInfo("[BTLinkPanle] empty cant scroll to index")
            return
        }
        if index == 0 {
            recordList.setContentOffset(.zero, animated: true)
        } else {
            recordList.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: animated)
        }
        if needFixOffest,
           let firstVisibleCellOffset = firstVisibleCellOffset {
            let currentOffsetY = recordList.contentOffset.y + firstVisibleCellOffset + recordList.contentInset.top
            recordList.setContentOffset(CGPoint(x: 0, y: currentOffsetY), animated: animated)
            self.firstVisibleCellOffset = nil
        }
    }

    private func addHeaderAndFooter() {
        if recordList.header == nil && dataSource?.linkFiledContext.viewMode != .addRecord {
            recordList.es.addPullToRefreshOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
                guard let self = self else { return }
                guard !self.dataIsReloading else {
                    // reload触发的上拉事件不请求数据
                    self.finishLoadTopData()
                    self.dataIsReloading = false
                    return
                }
                
                //向上请求分页数据
                self.viewModel.fetchLinkCardList(.linkCardTop, { _ in
                    self.finishLoadTopData()
                })
            }
        }
        if recordList.footer == nil {
            recordList.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
                guard let self = self else { return }
                
                guard !self.dataIsReloading else {
                    // reload触发的下拉事件不请求数据
                    self.finishLoadBottomData()
                    self.dataIsReloading = false
                    return
                }
                
                //向下请求分页数据
                self.viewModel.fetchLinkCardList(.linkCardBottom, { _ in
                    self.finishLoadBottomData()
                })
            }
        }
    }
    
    private func setEnableLoadBottomMore(enable: Bool) {
        recordList.footer?.noMoreData = !enable
        recordList.footer?.isHidden = !enable
    }
    
    private func setEnableLoadTopMore(enable: Bool) {
        recordList.header?.isHidden = !enable
    }
    
    //结束向下分页请求的loading
    private func finishLoadBottomData() {
        recordList.es.stopLoadingMore()
    }
    
    private func startLoadBottomData() {
        recordList.es.autoLoadMore()
    }
    
    //结束向上分页请求的loading
    private func finishLoadTopData() {
        recordList.es.stopPullToRefresh()
    }

    func handleDataLoaded(router: BTAsyncRequestRouter) {
        viewModel.handleDataLoaded(router: router)
    }
}

extension BTLinkPanel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BTLinkRecordCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTLinkRecordCell {
            let record = records[indexPath.row]
            if let (primaryText, isSelected) = viewModel.cellState(recordModel: record) {
                cell.configModel(BTLinkRecordModel(id: record.recordID, text: primaryText, isSelected: isSelected))
            }
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let cell = tableView.cellForRow(at: indexPath) as? BTLinkRecordCell else { return }
        viewModel.changeSelectionStatus(id: cell.model.id,
                                        isSelected: !cell.isSelectedCheckbox,
                                        couldSelectMultiple: couldLinkMultipleRecords)
        if !couldLinkMultipleRecords, !cell.isSelectedCheckbox {
            delegate?.finishLinking(self)
        }
    }
}


protocol BTLinkPanelDelegate: AnyObject {

    func updateLinkedRecords(recordIDs: [String], recordTitles: [String: String])

    func trackOpenLinkPanel(currentLinkageCount: Int, fieldModel: BTFieldModel)

    func trackUpdatedLinkage(selectionStatus: Bool)

    func beginSearching()

    func createAndLinkNewRecord(primaryText: String?)

    func finishLinking(_ panel: BTLinkPanel)
    
    func startLoadingTimer()
    
    func showTryAgainEmptyView(text: String, type: UDEmptyType, tryAgainBlock: (() -> Void)?)
    
    func scrollToIndex(index: Int, animated: Bool, needFixOffest: Bool)
    
}


struct BTLinkRecordModel: Equatable, HandyJSON {
    var id: String = ""
    var text: String = ""
    var isSelected: Bool = false
    var isShow: Bool?
    var callbackId: String?
}

final class BTLinkRecordCell: UITableViewCell {
    
    struct UIConfig {
        var recordViewBackgroundColor: UIColor = UDColor.bgFloatOverlay
        var contentViewBackgroundColor: UIColor = UDColor.bgFloat
    }
    
    var model: BTLinkRecordModel = BTLinkRecordModel(id: "", text: "", isSelected: false)
    
    var isSelectedCheckbox: Bool {
        return checkbox.isSelected
    }
    
    private lazy var checkbox = UDCheckBox(boxType: .multiple,
                                           config: .init(borderEnabledColor: UDColor.N500,
                                                         borderDisabledColor: .clear,
                                                         selectedBackgroundEnabledColor: UDColor.primaryContentDefault,
                                                         unselectedBackgroundEnabledColor: .clear,
                                                         style: .circle))
    
    private lazy var recordView = UIView().construct { it in
        it.layer.cornerRadius = 4
        it.backgroundColor = UDColor.bgFloatOverlay
    }
    
    private lazy var primaryLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textTitle
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(checkbox)
        checkbox.isUserInteractionEnabled = false
        checkbox.snp.makeConstraints { it in
            it.left.equalTo(16)
            it.width.height.equalTo(20)
            it.centerY.equalToSuperview()
        }
        contentView.addSubview(recordView)
        recordView.snp.makeConstraints { it in
            it.left.equalTo(checkbox.snp.right).offset(12)
            it.centerY.equalToSuperview()
            it.height.equalTo(36)
            it.right.equalTo(-16)
        }
        recordView.addSubview(primaryLabel)
        primaryLabel.snp.makeConstraints { it in
            it.centerY.equalToSuperview()
            it.left.equalTo(12)
            it.right.equalTo(-12)
        }
    }
                    
    func configModel(_ model: BTLinkRecordModel, uiConfig: UIConfig = UIConfig()) {
        self.model = model
        primaryLabel.text = model.text.isEmpty ? BundleI18n.SKResource.Doc_Block_UnnamedRecord : model.text
        checkbox.isSelected = model.isSelected
        
        contentView.backgroundColor = uiConfig.contentViewBackgroundColor
        recordView.backgroundColor = uiConfig.recordViewBackgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class CustomAddLinkButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UDColor.fillPressed : UDColor.bgFloat
        }
    }
}
// 关联添加面板无权限tips
final class LinkPanelNoPermissionView: UIView {
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.lockFilled.ud.withTintColor(UDColor.iconN3)
        return view
    }()
    lazy var title: UILabel = {
        var view = UILabel()
        view.textColor = UDColor.textPlaceholder
        view.font = UDFont.caption1
        view.text = BundleI18n.SKResource.Bitable_Dashboard_DrillDown_NoPermToViewSomeData
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgFloat
        addSubview(imageView)
        addSubview(title)
        imageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(14)
        }
        title.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(4)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(18)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
