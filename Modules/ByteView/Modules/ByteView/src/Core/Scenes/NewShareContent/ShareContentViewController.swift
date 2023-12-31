//
//  ShareContentViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/9/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ReplayKit
import UniverseDesignColor
import RxSwift
import RxCocoa
import Action
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI
import ByteViewTracker
import UniverseDesignDialog

final class ShareContentViewController: VMViewController<ShareContentSettingsVMProtocol>, UITableViewDataSource, UITableViewDelegate, DocsIconDelegate {

    var isSearching: Bool = false

    private var createAndShareViewModel: NewShareSettingsVMProtocol?

    /// 会议相关文档，单独拉取；如果没有，则不显示妙享文档的区块标题
    var meetingRelatedDocuments: [SearchDocumentResultCellModel] = []
    var commonItems: [SearchDocumentResultCellModel] = []
    var commonVM: SearchShareDocumentsVMProtocol?

    enum ShareContentReuseIdentifier {
        static let shareScreenOrWhiteboardCell: String = "shareScreenOrWhiteboardCell"
        static let newFileCell: String = "ShareContentNewFileCell"
        static let magicShareHeaderView: String = "ShareContentMagicShareHeaderView"
        static let magicShareItemCell: String = "ShareContentMagicShareItemCell"
        static let documentSectionTitleCell: String = "DocumentSectionTitleCell"
    }

    private enum Layout {
        static let horizontalEdgeInsets: CGFloat = 16.0
    }

    // MARK: - Common Table View

    private let loadMoreSubject: PublishSubject<Void> = PublishSubject()

    private lazy var contentView: UIView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        view.addArrangedSubview(tipsView)
        /// stackview 不加 container 会存在高度布局过大问题
        let tableViewContainer = UIView()
        tableViewContainer.addSubview(tableView)
        view.addArrangedSubview(tableViewContainer)
        tipsView.snp.makeConstraints {
            $0.height.equalTo(0).priority(.low)
        }
        return view
    }()

    private lazy var tipsView: UIView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 1
        view.addArrangedSubview(cautionTipView)
        view.addArrangedSubview(ultrasonicTipView)
        ultrasonicTipView.snp.makeConstraints {
            $0.height.equalTo(68.0).priority(.low)
        }
        return view
    }()

    private lazy var cautionTipView: UIView = {
        let iconImage = UDIcon.getIconByKey(.infoFilled, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
        let icon = UIImageView(image: iconImage)

        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: I18n.View_G_LargeMeetShareCaution, config: .bodyAssist)
        label.setContentHuggingPriority(.required, for: .vertical)

        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryFillSolid02
        view.setContentHuggingPriority(.required, for: .vertical)
        view.isHidden = true

        let contentView = UIView()
        contentView.addSubview(icon)
        contentView.addSubview(label)
        view.addSubview(contentView)

        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(18)
            make.size.equalTo(16)
        }

        label.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(16)
        }

        contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            if Display.pad {
                make.centerX.equalToSuperview()
            } else {
                make.left.right.equalTo(view.safeAreaLayoutGuide)
            }
        }

        return view
    }()

    private lazy var ultrasonicTipView: TipView = {
        let tipView = TipView()
        var content = I18n.View_G_UsingUltrasonicToShareVerTwo_Desc(deviceType: UIDevice.current.name)
        let array = content.components(separatedBy: "@@")
        var range: NSRange?
        if array.count >= 3 {
            content = content.replacingOccurrences(of: "@@\(array[1])@@", with: array[1])
            range = NSRange(location: array[0].count, length: array[1].count)
        }
        var tipInfo = TipInfo(content: content,
                              iconType: .info,
                              type: .other,
                              isFromNotice: false,
                              canCover: false,
                              canClosedManually: true,
                              highLightRange: range)
        tipView.delegate = self
        tipView.presentTipInfo(tipInfo: tipInfo)
        return tipView
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .plain)
        if self.viewModel.shareContentEnabledConfig.isMagicShareEnabled {
            tableView.backgroundColor = UIColor.ud.bgFloat
        } else {
            tableView.backgroundColor = UIColor.clear
        }
        tableView.estimatedRowHeight = 66.0
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.keyboardDismissMode = .onDrag
        tableView.loadMoreDelegate?.addBottomLoading { [weak self] in
            self?.loadMoreSubject.onNext(())
        }
        tableView.register(ShareContentScreenOrWhiteboardCell.self, forCellReuseIdentifier: ShareContentReuseIdentifier.shareScreenOrWhiteboardCell)
        tableView.register(ShareContentNewFileCell.self, forCellReuseIdentifier: ShareContentReuseIdentifier.newFileCell)
        tableView.register(ShareContentMagicShareHeaderView.self, forHeaderFooterViewReuseIdentifier: ShareContentReuseIdentifier.magicShareHeaderView)
        tableView.register(SearchDocumentResultCell.self, forCellReuseIdentifier: ShareContentReuseIdentifier.magicShareItemCell)
        tableView.register(DocumentSectionTitleCell.self, forCellReuseIdentifier: ShareContentReuseIdentifier.documentSectionTitleCell)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    lazy var loadingView: UIView = {
        let view = LoadingTipView(frame: .zero, padding: 8, style: .blue)
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        view.start(with: I18n.View_VM_Loading)

        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        return containerView
    }()

    lazy var noResultLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_MV_NoDocsToShare_Status
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private func addDefaultNoResultView() {
        tableView.addSubview(noResultLabel)
        noResultLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(tableView.vc.keyboardLayoutGuide.snp.top)
        }
    }

    @RwAtomic
    var requestRecentDocumentsStatus: SearchContainerView.Status = .loading
    @RwAtomic
    var isMeetingRelatedDocumentsRequested: Bool = false

    func update(_ status: SearchContainerView.Status) {
        requestRecentDocumentsStatus = status
        loadingView.isHidden = true
        noResultLabel.isHidden = true

        switch status {
        case .loading:
            loadingView.isHidden = false
        case let .result(hasMore):
            tableView.loadMoreDelegate?.endBottomLoading(hasMore: hasMore)
        case .noResult:
            if isMeetingRelatedDocumentsRequested {
                noResultLabel.isHidden = false
            }
            noResultLabel.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                maker.centerX.equalToSuperview()
                maker.top.equalToSuperview().offset(self.firstDocumentTopOffset)
                maker.bottom.equalTo(tableView.vc.keyboardLayoutGuide.snp.top)
            }
        }
        if !self.viewModel.shareContentEnabledConfig.isMagicShareEnabled {
            loadingView.isHidden = true
        }
    }

    var statusObserver: AnyObserver<SearchContainerView.Status> {
        return AnyObserver<SearchContainerView.Status>(eventHandler: { [weak self] element in
            if case let .next(status) = element {
                self?.update(status)
            }
        })
    }

    var loadMoreObservable: Observable<Void> {
        return loadMoreSubject.asObservable()
    }

    // MARK: - search page

    let searchBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.isHidden = true
        return view
    }()

    let searchBar: SearchBarView = {
        let searchBar = SearchBarView(frame: .zero, isNeedCancel: true)
        searchBar.iconImageLeftMargin = 8.0
        searchBar.iconImageToContentMargin = 8.0
        searchBar.iconImageDimension = 18.0
        searchBar.iconImageView.image = UDIcon.getIconByKey(.searchOutlined, iconColor: .ud.iconN3, size: CGSize(width: 18.0, height: 18.0))
        searchBar.setPlaceholder(I18n.View_M_Search, attributes: [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: UIFont.systemFont(ofSize: 16.0)
        ])
        searchBar.layer.cornerRadius = 6.0
        searchBar.contentView.layer.cornerRadius = 6.0
        searchBar.contentView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        return searchBar
    }()

    let saperateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy var searchView: SearchContainerView = {
        let searchResult = SearchContainerView(frame: CGRect.zero)
        searchResult.tableView.backgroundColor = UIColor.ud.bgBody
        searchResult.tableView.tableFooterView = UIView(frame: CGRect.zero)
        searchResult.tableView.separatorStyle = .none
        searchResult.tableView.rowHeight = UITableView.automaticDimension
        searchResult.tableView.estimatedRowHeight = 72
        searchResult.tableView.register(SearchDocumentResultCell.self, forCellReuseIdentifier: ShareContentReuseIdentifier.magicShareItemCell)
        return searchResult
    }()

    lazy var maskSearchViewTap = UITapGestureRecognizer()

    lazy var searchResultMaskView: UIView = {
        let backView = UIView(frame: .zero)
        backView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
        backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backView.addGestureRecognizer(maskSearchViewTap)
        backView.isHidden = true
        return backView
    }()

    // MARK: - loading view (when ultrawave unready)

    lazy var ultrawaveLoadingView: UIView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center

        stackView.addArrangedSubview(loadingAnimationView)

        let label = UILabel()
        label.text = I18n.View_VM_Loading
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        stackView.addArrangedSubview(label)

        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        return view
    }()

    lazy var loadingAnimationView = LoadingView(frame: CGRect(x: 0, y: 0, width: 32, height: 28), style: .grey)

    // MARK: - tap actions

    lazy var tapCreateAndShareButtonClosure: ((UIView) -> Void) = { [weak self] (targetView: UIView) in
        self?.tapCreateAndShareButton(targetView)
    }

    lazy var tapSearchBarClosure: (() -> Void) = { [weak self] in
        self?.searchBackgroundView.isHidden = false
        self?.searchBar.textField.becomeFirstResponder()
        self?.setNavigationBarBgColor(.ud.bgBody)
        self?.view.backgroundColor = .ud.bgBody
        self?.searchResultMaskView.isHidden = false
        self?.isSearching = true
        MagicShareTracksV2.trackTapSearchBar()
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(contentView)
        view.addSubview(loadingView)
        view.addSubview(searchBackgroundView)
        searchBackgroundView.addSubview(searchBar)
        searchBackgroundView.addSubview(saperateLine)
        searchBackgroundView.addSubview(searchView)
        searchBackgroundView.addSubview(searchResultMaskView)

        setupTableView()
        // setup search views
        setupSearchViews()
        searchBar.hideSelfClosure = { [weak self] in
            self?.searchBackgroundView.isHidden = true
            self?.searchBar.textField.resignFirstResponder()
            self?.setNavigationBarBgColor(.ud.bgFloatBase)
            self?.view.backgroundColor = .ud.bgFloatBase
            self?.isSearching = false
        }
        setupUltrawaveLoadingView()
    }

    private func setupTableView() {
        contentView.snp.makeConstraints { maker in
            maker.bottom.top.equalToSuperview()
            maker.left.right.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.left.right.equalToSuperview().inset(Layout.horizontalEdgeInsets)
        }
        loadingView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            // loading 位置在搜索栏下面空间居中，168为搜索栏高度及其以上高度
            maker.top.equalTo(tableView).inset(168)
            maker.bottom.equalTo(view.vc.keyboardLayoutGuide.snp.top)
        }
        addDefaultNoResultView()
    }

    private func setupSearchViews() {
        searchBackgroundView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        searchBar.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.right.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            maker.height.equalTo(36.0)
        }
        saperateLine.snp.makeConstraints { maker in
            maker.top.equalTo(searchBar.snp.bottom).offset(8.0)
            maker.height.equalTo(0.5)
            maker.left.right.equalTo(view)
        }
        searchView.snp.makeConstraints { maker in
            maker.top.equalTo(saperateLine.snp.bottom)
            maker.bottom.equalToSuperview()
            maker.left.right.equalToSuperview()
        }
        searchResultMaskView.snp.makeConstraints { maker in
            maker.left.right.bottom.equalTo(searchView)
            maker.top.equalTo(saperateLine.snp.bottom)
        }
    }

    private func setupUltrawaveLoadingView() {
        view.addSubview(ultrawaveLoadingView)
        ultrawaveLoadingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        let commonVM = viewModel.generateSearchViewModel(isSearch: false)
        bindCommonViewModel(commonVM)
        let searchVM = viewModel.generateSearchViewModel(isSearch: true)
        bindSearchViewModel(searchVM)
        // generate create and share VM
        let createAndShareVM = viewModel.generateCreateAndShareViewModel()
        self.createAndShareViewModel = createAndShareVM

        if let vm = viewModel as? ShareContentSettingsViewModel {
            vm.hostVC = self
        }
        if let vm = viewModel as? LocalShareContentViewModel {
            vm.shareContentVC = self
        }
        viewModel.canSharingDocsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isEnabled: Bool) in
                if !isEnabled {
                    self?.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                }
                self?.tableView.isScrollEnabled = isEnabled
                self?.tableView.reloadData()
            })
            .disposed(by: rx.disposeBag)

        viewModel.isLoadingObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.ultrawaveLoadingView.isHidden = !isLoading
                if isLoading {
                    self?.loadingAnimationView.play()
                } else {
                    self?.loadingAnimationView.stop()
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.shouldReloadWhiteboardItemObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: rx.disposeBag)
    }

    private func bindCommonViewModel(_ model: SearchShareDocumentsVMProtocol) {
        commonVM = model

        loadMoreObservable
            .bind(to: model.loadNext)
            .disposed(by: rx.disposeBag)

        model.resultData
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.commonItems = $0
                self.tableView.reloadData()
                self.updateTipsView()
            }).disposed(by: rx.disposeBag)

        model.meetingRelatedDocument
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.isMeetingRelatedDocumentsRequested = true
                self.meetingRelatedDocuments = $0
                self.tableView.reloadData()
                self.updateTipsView()
            }).disposed(by: rx.disposeBag)

        model.resultStatus
            .observeOn(MainScheduler.instance)
            .bind(to: statusObserver)
            .disposed(by: rx.disposeBag)

        model.dismissPublishSubject.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
        // 进入页面手动触发一次
        model.searchText.onNext("")
    }

    private func updateTipsView() {
        updateLoadingTips()
        updateEmptyListTips()
    }

    private func updateLoadingTips() {
        if !meetingRelatedDocuments.isEmpty || !commonItems.isEmpty {
            loadingView.isHidden = true
        }
    }

    private func updateEmptyListTips() {
        if case .noResult = self.requestRecentDocumentsStatus, isMeetingRelatedDocumentsRequested,
            meetingRelatedDocuments.isEmpty, commonItems.isEmpty {
            noResultLabel.isHidden = false
        }
    }

    private func bindSearchViewModel(_ model: SearchShareDocumentsVMProtocol) {
        model.bindToViewController(self)
        maskSearchViewTap.rx.event
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.searchBar.resetSearchBar()
                self?.searchResultMaskView.isHidden = true
                self?.searchBar.textField.resignFirstResponder()
                self?.searchBackgroundView.isHidden = true
                self?.setNavigationBarBgColor(.ud.bgFloatBase)
                self?.view.backgroundColor = .ud.bgFloatBase
                self?.isSearching = false
            })
            .disposed(by: rx.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBar()
        self.cautionTipView.isHidden = !viewModel.showTip
        self.ultrasonicTipView.isHidden = !viewModel.shareContentEnabledConfig.isUltrasonicEnabled || viewModel.hasShowUltrawaveTip
    }

    private func setNavigationBar() {
        title = I18n.View_MV_Share_TopTitleBar
        setNavigationBarBgColor(isSearching ? .ud.bgBody : .ud.bgFloatBase)
        view.backgroundColor = isSearching ? .ud.bgBody : .ud.bgFloatBase
    }

    /// 点击新建按钮
    /// - Parameter sourceView: 新建按钮的视图
    private func tapCreateAndShareButton(_ sourceView: UIView) {
        guard let createAndShareVM = self.createAndShareViewModel else {
            return
        }
        MagicShareTracks.trackClickShareNew()
        let appearance = ActionSheetAppearance(backgroundColor: UIColor.ud.bgFloat,
                                               contentViewColor: UIColor.ud.bgFloat,
                                               separatorColor: UIColor.clear,
                                               modalBackgroundColor: UIColor.ud.bgMask,
                                               customTextHeight: 50.0,
                                               tableViewInsets: UIEdgeInsets(top: 8.0, left: 0, bottom: 8.0, right: 0),
                                               tableViewCornerRadius: 0)
        let actionSheetVC = ActionSheetController(appearance: appearance)
        actionSheetVC.modalPresentation = .alwaysPopover

        for fileTypeItem in createAndShareVM.validFileTypes {
            let actionView = self.buildRefreshSheetAction(with: fileTypeItem)
            actionSheetVC.addAction(actionView)
        }

        let anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        contentWidth: .fixed(actionSheetVC.maxIntrinsicWidth),
                                        contentHeight: CGFloat(Double(createAndShareVM.validFileTypes.count) * 50.0 + 16.0),
                                        positionOffset: CGPoint(x: 0, y: 4),
                                        minPadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                        cornerRadius: 8,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        containerColor: UIColor.ud.bgFloat)
        AlignPopoverManager.shared.present(viewController: actionSheetVC, from: self, anchor: anchor)
    }

    private func buildRefreshSheetAction(with fileTypeItem: NewShareContentItem) -> SheetAction {
        return SheetAction(title: fileTypeItem.title,
                           titleFontConfig: VCFontConfig.bodyAssist,
                           icon: fileTypeItem.image,
                           showBottomSeparator: false,
                           sheetStyle: fileTypeItem.showBeta ? .iconLabelAndBeta : .iconAndLabel,
                           isNewMS: true,
                           handler: { _ in
                            fileTypeItem.action(fileTypeItem)
                           })
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return true
    }

    // MARK: - tableView
    var shareContentDataModel: [ShareContentTableViewSectionModel] {
        let config = viewModel.shareContentEnabledConfig
        var dataModel = [ShareContentTableViewSectionModel]()
        if config.isShareScreenEnabled || config.isWhiteboardEnable {
            var shareCells = [ShareContentTableViewRowModel]()
            if config.isShareScreenEnabled {
                let shareScreenRowModel = ShareContentTableViewRowModel(shareContentType: .shareScreen)
                shareCells.append(shareScreenRowModel)
            }
            if config.isWhiteboardEnable {
                let whiteboardRowModel = ShareContentTableViewRowModel(shareContentType: .whiteboard)
                shareCells.append(whiteboardRowModel)
            }
            let shareScreenSectionModel = ShareContentTableViewSectionModel(rowModel: shareCells)
            dataModel.append(shareScreenSectionModel)
        }
        if config.isNewFileEnabled && config.isMagicShareEnabled {
            let newFilesCell = ShareContentTableViewRowModel(shareContentType: .newFiles)
            let newFilesSection = ShareContentTableViewSectionModel(rowModel: [newFilesCell])
            dataModel.append(newFilesSection)
        }
        if config.isMagicShareEnabled {
            // 搜索栏
            let searchDocumentHeader = ShareContentTableViewHeaderModel(shareContentType: .searchDocument)
            var rowModels = [ShareContentTableViewRowModel]()
            if !meetingRelatedDocuments.isEmpty {
                // “会议相关“
                let meetingRelatedTitleCell = ShareContentTableViewRowModel(shareContentType: .documentSectionTitle)
                rowModels.append(meetingRelatedTitleCell)
                // ”会议相关“文档
                meetingRelatedDocuments.forEach { _ in
                    let shareDocumentCell = ShareContentTableViewRowModel(shareContentType: .meetingRelatedDocument)
                    rowModels.append(shareDocumentCell)
                }
                if !commonItems.isEmpty {
                    // “最近”
                    let recentTitleCell = ShareContentTableViewRowModel(shareContentType: .documentSectionTitle)
                    rowModels.append(recentTitleCell)
                }
            }
            // ”最近“文档
            commonItems.forEach { _ in
                let shareDocumentCell = ShareContentTableViewRowModel(shareContentType: .shareDocument)
                rowModels.append(shareDocumentCell)
            }
            let shareDocumentHeaderSection = ShareContentTableViewSectionModel(rowModel: rowModels,
                                                                               headerModel: searchDocumentHeader)
            dataModel.append(shareDocumentHeaderSection)
        }
        return dataModel
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shareContentDataModel[section].rowModel.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return shareContentDataModel.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = shareContentDataModel[indexPath.section].getEstimatedHeight(indexPath.row)
        return height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch shareContentDataModel[indexPath.section].rowModel[indexPath.row].type {
        case .shareDocument:
            let minusRowCount = {
                if self.meetingRelatedDocuments.isEmpty {
                    return 0
                } else {
                    return 2 + self.meetingRelatedDocuments.count
                }
            }()
            let docs = commonItems[indexPath.row - minusRowCount]
            InMeetFollowViewModel.logger.debug("""
                selected doc info
                title: xxx,
                status: \(docs.status),
                url.hash: \(docs.url.vc.removeParams().hash),
                isSharing: \(docs.isSharing)
                """)
            commonVM?.didSelectedModel.onNext(docs)
        case .meetingRelatedDocument:
            let docs = meetingRelatedDocuments[indexPath.row - 1]
            commonVM?.didSelectedModel.onNext(docs)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let canSharingDocs: Bool = viewModel.canSharingDocs
        switch shareContentDataModel[indexPath.section].rowModel[indexPath.row].type {
        case .shareScreen, .whiteboard:
            switch shareContentDataModel[indexPath.section].rowModel[indexPath.row].type {
            case .whiteboard:
                let whiteboardCell = tableView.dequeueReusableCell(withIdentifier: ShareContentReuseIdentifier.shareScreenOrWhiteboardCell, for: indexPath)
                let tapShareClosure: (() -> Void) = { [weak self] in
                    if self?.viewModel.checkShowChangeAlert(isWhiteBoard: true) == true {
                        Self.showShareChangeAlert(from: self) { result in
                            switch result {
                            case .success:
                                self?.viewModel.didTapShareWhiteboard()
                            case .failure:
                                break
                            }
                        }
                    } else {
                        self?.viewModel.didTapShareWhiteboard()
                    }
                }
                if let cell = whiteboardCell as? ShareContentScreenOrWhiteboardCell {
                    cell.shareType = .whiteboard
                    cell.configAppearance(with: viewModel.whiteboardIcon,
                                          imageBgDriver: viewModel.whiteboardIconBackgroundColor,
                                          title: viewModel.whiteboardTitle,
                                          titleColor: viewModel.whiteboardTitleColor)
                    cell.tapShareClosure = tapShareClosure
                    let shouldShowEmptyView = shareContentDataModel[indexPath.section].rowModel.count > 1 && indexPath.row == 0
                    cell.configEmptyView(shouldShowEmptyView: shouldShowEmptyView)
                }
                return whiteboardCell
            case .shareScreen:
                let shareScreenCell = tableView.dequeueReusableCell(withIdentifier: ShareContentReuseIdentifier.shareScreenOrWhiteboardCell, for: indexPath)
                let tapShareClosure: (() -> Void) = { [weak self] in
                    if self?.viewModel.checkShowChangeAlert(isWhiteBoard: false) == true {
                        Self.showShareChangeAlert { result in
                            switch result {
                            case .success:
                                self?.viewModel.showShareScreenAlert()
                            case .failure:
                                break
                            }
                        }
                    } else {
                        self?.viewModel.showShareScreenAlert()
                    }
                }
                if let cell = shareScreenCell as? ShareContentScreenOrWhiteboardCell {
                    cell.shareType = .shareScreen
                    cell.configAppearance(with: viewModel.shareScreenIcon,
                                          imageBgDriver: viewModel.shareScreenIconBackgroundColor,
                                          title: viewModel.shareScreenTitle,
                                          titleColor: viewModel.shareScreenTitleColor)
                    cell.tapShareClosure = tapShareClosure
                    let shouldShowEmptyView = shareContentDataModel[indexPath.section].rowModel.count > 1 && indexPath.row == 0
                    cell.configEmptyView(shouldShowEmptyView: shouldShowEmptyView)
                }
                return shareScreenCell
            default:
                return UITableViewCell()
            }
        case .newFiles:
            let newFileCell = tableView.dequeueReusableCell(withIdentifier: ShareContentReuseIdentifier.newFileCell, for: indexPath)
            if let cell = newFileCell as? ShareContentNewFileCell {
                cell.configTapAction(tapCreateAndShare: tapCreateAndShareButtonClosure)
                cell.configCellEnabled(canSharingDocs)
            }
            return newFileCell
        case .shareDocument:
            let minusRowCount = {
                if self.meetingRelatedDocuments.isEmpty {
                    return 0
                } else {
                    return 2 + self.meetingRelatedDocuments.count
                }
            }()
            let item = self.commonItems[indexPath.row - minusRowCount]
            let magicShareCell = tableView.dequeueReusableCell(withIdentifier: ShareContentReuseIdentifier.magicShareItemCell, for: indexPath)
            if let cell = magicShareCell as? SearchDocumentResultCell {
                cell.docsIconDelegate = self
                cell.update(item, account: self.viewModel.accountInfo)
                cell.setBackgroundViewColor(UIColor.ud.bgFloat)
            }
            magicShareCell.updateMSAvailableStataus(isEnabled: canSharingDocs)
            return magicShareCell
        case .documentSectionTitle:
            let documentSectionTitleCell = tableView.dequeueReusableCell(withIdentifier: ShareContentReuseIdentifier.documentSectionTitleCell,
                                                                         for: indexPath)
            if let cell = documentSectionTitleCell as? DocumentSectionTitleCell {
                cell.setTitle(getDocumentSectionTitle(with: indexPath.row))
            }
            return documentSectionTitleCell
        case .meetingRelatedDocument:
            let item = self.meetingRelatedDocuments[indexPath.row - 1]
            let magicShareCell = tableView.dequeueReusableCell(withIdentifier: ShareContentReuseIdentifier.magicShareItemCell, for: indexPath)
            if let cell = magicShareCell as? SearchDocumentResultCell {
                cell.docsIconDelegate = self
                cell.update(item, account: self.viewModel.accountInfo, isFromMeetingRelated: true)
                cell.setBackgroundViewColor(UIColor.ud.bgFloat)
            }
            magicShareCell.updateMSAvailableStataus(isEnabled: canSharingDocs)
            return magicShareCell
        default:
            return UITableViewCell()
        }
    }

    private func getDocumentSectionTitle(with row: NSInteger) -> String {
        return row == 0 ? I18n.View_G_RelatedtoMeeting_Desc : I18n.View_G_RecentlyUsed_Desc
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerType = shareContentDataModel[section].headerModel?.type else { return nil }
        switch headerType {
        case .searchDocument:
            if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShareContentReuseIdentifier.magicShareHeaderView) as? ShareContentMagicShareHeaderView {
                headerView.configTapAction(tapSearchBarClosure: tapSearchBarClosure)
                headerView.handleEnabled(viewModel.canSharingDocs)
                return headerView
            }
            return UIView()
        default:
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerType = shareContentDataModel[section].headerModel?.type else { return 0 }
        switch headerType {
        case .searchDocument:
            return 60.0
        default:
            return 0
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        }
    }

    func getDocsIconImage(with iconInfo: String, url: String, completion: ((UIImage) -> Void)?) {
        viewModel.ccmDependency.setDocsIcon(iconInfo: iconInfo, url: url, completion: completion)
    }
}

extension ShareContentViewController {

    static func showShareChangeAlert(from: UIViewController? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        Util.runInMainThread {
            ByteViewDialog.Builder()
                .id(.shareContentChange)
                .title(I18n.View_G_ShareStopOngoingSure)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    VCTracker.post(name: .vc_meeting_onthecall_popup_click,
                                   params: [.content: "share_screen_stop", .click: "cancel"])
                    completion(.failure(VCError.unknown))
                })
                .rightTitle(I18n.View_G_Continue)
                .rightHandler({ _ in
                    VCTracker.post(name: .vc_meeting_onthecall_popup_click,
                                   params: [.content: "share_screen_stop", .click: "continue_share"])
                    completion(.success(Void()))
                })
                .show()
        }
    }

}

extension ShareContentViewController: SearchShareDocumentsViewControllerProtocol {
    var searchViewCellIdentifier: String { ShareContentReuseIdentifier.magicShareItemCell }
    var disposeBag: DisposeBag { rx.disposeBag }
    var scenario: ShareContentScenario { self.viewModel.scenario }
}

private extension UITableViewCell {
    /// 不可共享文档时，UI需置灰
    func updateMSAvailableStataus(isEnabled: Bool) {
        contentView.alpha = isEnabled ? 1.0 : 0.5
        isUserInteractionEnabled = isEnabled ? true : false
    }
}

class ShareContentTableViewSectionModel {

    let rowModel: [ShareContentTableViewRowModel]
    let headerModel: ShareContentTableViewHeaderModel?

    init(rowModel: [ShareContentTableViewRowModel],
         headerModel: ShareContentTableViewHeaderModel? = nil) {
        self.rowModel = rowModel
        self.headerModel = headerModel
    }

    var rowType: ShareContent? {
        return rowModel.first?.type
    }

    var estimatedHeight: CGFloat {
        guard let type = rowModel.first?.type else {
            return 0
        }
        switch type {
        case .shareScreen, .whiteboard:
            return 56.0
        case .newFiles:
            return 52.0
        case .searchDocument:
            return 60.0
        case .shareDocument, .meetingRelatedDocument:
            return 66.0
        case .documentSectionTitle:
            return 38.0
        default:
            return 0
        }
    }

    func getEstimatedHeight(_ row: Int) -> CGFloat {
        guard rowModel.count > row else { return 0 }
        let type = rowModel[row].type
        switch type {
        case .shareScreen, .whiteboard:
            if rowModel.count == 1 { return 56.0 }
            if row >= rowModel.count { return 0 }
            switch rowModel[row].type {
            case .shareScreen:
                return 76.0
            case .whiteboard:
                return 56.0
            default:
                return 0
            }
        case .newFiles:
            return 52.0
        case .searchDocument:
            return 60.0
        case .documentSectionTitle:
            return 38.0
        case .shareDocument, .meetingRelatedDocument:
            return 66.0
        default:
            return 0
        }
    }

}

class ShareContentTableViewHeaderModel {

    let type: ShareContent

    init(shareContentType: ShareContent) {
        self.type = shareContentType
    }

}

class ShareContentTableViewRowModel {

    let type: ShareContent

    init(shareContentType: ShareContent) {
        self.type = shareContentType
    }

    var isHeaderEnabled: Bool {
        switch type {
        case .searchDocument:
            return true
        default:
            return false
        }
    }

    var isFooterEnabled: Bool {
        return false
    }

}

extension ShareContentViewController {

    var firstDocumentTopOffset: CGFloat {
        var offset: CGFloat = 0.0
        let config = viewModel.shareContentEnabledConfig
        if config.isShareScreenEnabled {
            offset += 56.0
        }
        if config.isNewFileEnabled && config.isMagicShareEnabled {
            offset += 52.0
        }
        offset += 60.0 // searchDocument
        return offset
    }

}

extension ShareContentViewController: TipViewDelegate {
    func tipViewDidClickLeadingButton(_ sender: UIButton, tipInfo: TipInfo) {
    }

    func tipViewDidTapLeadingButton(tipInfo: TipInfo) {
    }

    func tipViewDidTapLink(tipInfo: TipInfo) {
        let vc = viewModel.setting.ui.createGeneralSettingViewController(source: "vc_share_content")
        self.presentDynamicModal(vc,
                                 regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                 compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }

    func tipViewDidClickClose(_ sender: UIButton, tipInfo: TipInfo) {
        ultrasonicTipView.dismissTipView()
        tipsView.invalidateIntrinsicContentSize()
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        viewModel.hasShowUltrawaveTip = true
    }
}

enum ShareContent: CaseIterable, Equatable {
    case shareScreen
    case whiteboard
    case newFiles
    case searchDocument
    /// “会议相关”、“最近”这种文档分区标题
    case documentSectionTitle
    /// 会议相关文档
    case meetingRelatedDocument
    case shareDocument
    case docsContent
}
