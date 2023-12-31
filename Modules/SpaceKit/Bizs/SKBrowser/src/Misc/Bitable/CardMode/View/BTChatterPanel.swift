//
//  BTChatterPanel.swift
//  SKBrowser
//
//  Created by X-MAN on 2023/1/12.
//

import UIKit
import RxCocoa
import RxSwift
import RxRelay
import SKCommon
import SKUIKit
import UniverseDesignColor
import SKResource
import UniverseDesignEmpty
import SKFoundation

public class BTChatterPanel: UIView {

    private let disposeBag = DisposeBag()

    public let viewModel: BTChatterPanelViewModel

    public weak var delegate: BTMemberPanelDelegate? {
        didSet {
            selectedMemberList.btDelegate = delegate
        }
    }

    public weak var hostView: UIView?

    public var isMultipleMembers: Bool {
        get { viewModel.isMultipleMembers }
        set {
            viewModel.isMultipleMembers = newValue
            guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel else {
                return
            }
            if chatterType == .group {
                tableView.isNoCheckBox = !newValue
                if newValue {
                    dragView.leftButton.isHidden = false
                } else {
                    dragView.leftButton.isHidden = true
                }
            }
            if chatterType == .user {
                // 不修改人面板的UI
                tableView.isNoCheckBox = false
                dragView.leftButton.isHidden = true
            }
        }
    }

    lazy var dismissArea: UIButton = UIButton(type: .custom)

    private lazy var dragView = SKDraggableTitleView().construct { it in
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
        it.layer.masksToBounds = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panToChangeSize(sender:)))
        it.addGestureRecognizer(panGestureRecognizer)
        it.rightButton.isHidden = self.viewModel.openSource == .sheetReminder
        it.rightButton.setTitle(BundleI18n.SKResource.Bitable_BTModule_Done, withFontSize: 17, fontWeight: .regular, color: UDColor.colorfulBlue, forState: .normal)
        it.rightButton.titleLabel?.textAlignment = .center
        it.rightButton.rx.tap.subscribe { [weak self] (_) in
            guard let self = self else { return }
            self.didHide(noUpdateChatterData: false)
        }.disposed(by: disposeBag)
        
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            it
                .leftButton
                .setImage(nil, for: .normal)
            it.leftButton.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }
            it
                .leftButton
                .rx
                .tap
                .subscribe { [weak self] (_) in
                    guard let self = self else { return }
                    self
                        .delegate?
                        .trackCancel()
                    self.didHide(noUpdateChatterData: true)
                }
                .disposed(by: disposeBag)
            it
                .leftButton
                .setTitle(
                    BundleI18n.SKResource.Bitable_AdvancedPermission_AddRecordButtonCancel,
                    withFontSize: 17,
                    fontWeight: .regular,
                    color: UDColor.textTitle,
                    forState: .normal
                )
            it
                .leftButton
                .titleLabel?
                .textAlignment = .center
            if self.chatterType == .group, self.isMultipleMembers {
                // 仅多选的时候展示左边取消
                it.leftButton.isHidden = false
            } else {
                it.leftButton.isHidden = true
            }
        } else {
        it.leftButton.isHidden = true
        }
        
        it.titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        it.titleLabel.textColor = UDColor.textTitle
        it.titleLabel.textAlignment = .center
        it.titleLabel.lineBreakMode = .byTruncatingTail
        
        if !UserScopeNoChangeFG.ZJ.btCardChatterPanelHeaderColorFixDisable {
            let backgroundView = UIView()
            backgroundView.backgroundColor = UDColor.bgFloat
            backgroundView.layer.cornerRadius = 12
            backgroundView.layer.maskedCorners = .top
            it.insertSubview(backgroundView, at: 0)
            backgroundView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            it.backgroundColor = UDColor.bgFloat
        }
    }

    public var titleLabel: UILabel {
        return dragView.titleLabel
    }

    lazy var searchView: BTSearchView = BTSearchView(shouldShowRightBtn: false)
    
    lazy var quickAddView: UIView = {
        let container = UIView()
        
        let view = QuickAddView()
        
        let blank = UIView()
        blank.backgroundColor = UDColor.bgBase
        
        container.addSubview(view)
        container.addSubview(blank)
        
        view.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(46)
        }
        blank.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(view.snp.bottom)
            make.height.equalTo(8)
        }
        
        container.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(quickAddViewClick))
        container.addGestureRecognizer(tapGesture)
        
        return container
    }()
    
    @objc func quickAddViewClick() {
        delegate?.quickAddViewClick()
        didHide(noUpdateChatterData: true)
    }

    lazy var selectedMemberList: BTSelectedChatterCollectionView = {
        let view = BTSelectedChatterCollectionView(self.viewModel.hostFileTitle)
        view.backgroundColor = UDColor.bgFloat
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            view.clickCallback = { [weak self] in
                guard let self = self else {
                    return
                }
                guard self.chatterType == .group else {
                    return
                }
                guard self.isMultipleMembers else {
                    return
                }
                self.delegate?.finishSelecting(
                    self,
                    type: self.chatterType,
                    chatters: self.viewModel.selectedData.value.map { return $0.asBTChatterModel },
                    notifiesEnabled: self.viewModel.notifyMode.notifiesEnabled,
                    trackInfo: self.trackInfo,
                    justUpdateChatterData: true,
                    noUpdateChatterData: false
                )
            }
        }
        return view
    }()

    lazy var notifyView: BTUserNotifyView = {
        let view = BTUserNotifyView(notifyMode: self.viewModel.notifyMode)
        view.backgroundColor = UDColor.bgFloat
        return view
    }()
    
    // 群组下不显示通知，需要一个分割去避免透出
    private lazy var divideView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
    }


    lazy var tableView: MembersTableView = {
        let tView = MembersTableView()
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, chatterType == .group {
            tView.isNoCheckBox = !isMultipleMembers
            tView.isShowHeadLine = false
        }
        tView.backgroundColor = UDColor.bgFloat
        tView.delegate = self
        return tView
    }()
    
    private var emptyConfig: UDEmptyConfig = UDEmptyConfig(title: .init(titleText: "",
                                                                        font: .systemFont(ofSize: 14, weight: .regular)),
                                                           description: .init(descriptionText: BundleI18n.SKResource.Bitable_PeopleField_NothingFound_Description),
                                                           imageSize: 100,
                                                           type: .noContent,
                                                           labelHandler: nil,
                                                           primaryButtonConfig: nil,
                                                           secondaryButtonConfig: nil)
    
    private lazy var placeholderView: UDEmptyView = {
        let blankView = UDEmptyView(config: emptyConfig)
        // 不用userCenterConstraints会非常不雅观
        blankView.useCenterConstraints = true
        blankView.backgroundColor = UDColor.bgFloat
        return blankView
    }()

    var trackInfo = BTTrackInfo()

    var initialSelectedCount = -1

    let maximumSelectCount: Int
    
    private(set) var chatterType: BTChatterType
    
    var didInitialize: Bool {
        return initialSelectedCount == -1
    }
    
    var isSubmitMode: Bool

    public init(_ hostDocsInfo: DocsInfo?,
                chatId: String? = nil,
                hostView: UIView,
                openSource: BTChatterPanelViewModel.OpenSource,
                chatterType: BTChatterType = .user,
                isSubmitMode: Bool,
                maxSelectCount: Int = Int.max,
                lastSelectNotifies: Bool? = nil) {
        self.hostView = hostView
        self.maximumSelectCount = maxSelectCount
        self.chatterType = chatterType
        self.viewModel = BTChatterPanelViewModel(hostDocsInfo,
                                                chatId: chatId,
                                                openSource: openSource,
                                                lastSelectNotifies: lastSelectNotifies ?? true,
                                                chatterType: chatterType)
        switch chatterType {
            case .group:
                self.viewModel.notifyMode = .hidden
            default:
                break
        }
        self.isSubmitMode = isSubmitMode
        super.init(frame: .zero)
        layer.ud.setShadowColor(UDColor.shadowDefaultLg) // tokenize
        layer.shadowOpacity = 1
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: -6)
        trackInfo.isEditPanelOpen = true
        trackInfo.didClickDone = false
        setupViews()
        bind()
    }

    public func updateSelected(_ models: [BTCapsuleModel]?) {
        guard let models = models else { return }
        viewModel.updateSelected(models)
    }

    public func show(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in // 等待 setupViews 布局完成
            guard let self = self else { return }
            UIView.animate(withDuration: 0.25) {
                if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                    if self.chatterType == .group {
                        if self.isMultipleMembers {
                            self.dragView.leftButton.isHidden = false
                        } else {
                            self.dragView.leftButton.isHidden = true
                        }
                    }
                    if self.chatterType == .user {
                        // 不修改人面板的UI
                        self.tableView.isNoCheckBox = false
                        self.dragView.leftButton.isHidden = true
                    }
                }
                
                self.dragView.snp.updateConstraints { (make) in
                    make.top.equalTo((self.hostView?.bounds.height ?? 0) * 0.15)
                }
                self.layoutIfNeeded()
            } completion: { (completed) in
                if completed { completion?() }
            }
        }
    }

    public func hide(immediately: Bool) {
        if immediately {
            self.dragView.snp.updateConstraints { (make) in
                make.top.equalTo(self.hostView?.bounds.height ?? 0)
            }
            self.layoutIfNeeded()
            self.didHide(noUpdateChatterData: false)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.dragView.snp.updateConstraints { (make) in
                    make.top.equalTo(self.hostView?.bounds.height ?? 0)
                }
                self.layoutIfNeeded()
            } completion: { (completed) in
                if completed || UserScopeNoChangeFG.ZJ.btCardReform {
                    self.didHide(noUpdateChatterData: false)
                }
            }
        }
    }

    private func setupViews() {
        addSubview(dismissArea)
        addSubview(dragView)
        addSubview(searchView)
        
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            searchView.searchTextField.rx.controlEvent(.editingDidBegin)
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    print("editingDidBegin")
                    if self.chatterType == .group {
                        self.delegate?.trackSearchStartEdit()
                    }
                })
                .disposed(by: disposeBag)
            if chatterType == .group, !isSubmitMode {
                addSubview(quickAddView)
            }
        }
        
        addSubview(selectedMemberList)
        addSubview(divideView)
        addSubview(tableView)
        addSubview(placeholderView)

        dismissArea.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(dragView.snp.top)
        }
        dismissArea.backgroundColor = .clear
        dragView.snp.makeConstraints { make in
            make.top.equalTo(hostView?.bounds.height ?? 0)
            make.height.equalTo(60)
            make.left.right.equalToSuperview()
        }
        searchView.snp.makeConstraints { (make) in
            make.top.equalTo(dragView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, chatterType == .group, !isSubmitMode {
            quickAddView.snp.makeConstraints { make in
                make.top.equalTo(searchView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
            }
        }
        
        selectedMemberList.snp.makeConstraints { (make) in
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, self.chatterType == .group, !self.isSubmitMode {
                make.top.equalTo(quickAddView.snp.bottom)
            } else {
            make.top.equalTo(searchView.snp.bottom)
            }
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        // 默认不显示
        placeholderView.isHidden = true
        if viewModel.notifyMode == .hidden {
            divideView.snp.makeConstraints { make in
                make.top.equalTo(selectedMemberList.snp.bottom)
                make.right.left.equalToSuperview()
                make.height.equalTo(16)
            }
            tableView.snp.makeConstraints { make in
                make.top.equalTo(divideView.snp.bottom)
                make.right.left.bottom.equalToSuperview()
            }
        } else {
            addSubview(notifyView)
            notifyView.snp.makeConstraints { make in
                make.top.equalTo(selectedMemberList.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(46)
            }
            tableView.snp.makeConstraints { (make) in
                make.top.equalTo(notifyView.snp.bottom)
                make.right.left.bottom.equalToSuperview()
            }
        }
        placeholderView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }

    private func bind() {
        selectedMemberList.didClose
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                self.searchView.searchTextField.endEditing(true)
                self.trackInfo.userDeleteItemSource = .topBar
                self.viewModel.deselect(at: index)
            }).disposed(by: disposeBag)
        searchView.searchTextField.rx.text.orEmpty.changed
            .subscribe(onNext: { [weak self] content in
                guard let self = self else { return }
                self.trackInfo.didSearch = true
                self.viewModel.searchText.accept(content)
            }).disposed(by: disposeBag)
        dismissArea.rx.tap.asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.searchView.searchTextField.endEditing(true)
                self.trackInfo.didClickDone = true
                self.hide(immediately: false)
            }).disposed(by: disposeBag)
        notifyView.notifyModeData
            .subscribe(onNext: { [weak self] notifyMode in
                self?.viewModel.notifyMode = notifyMode
            }).disposed(by: disposeBag)
        viewModel.recommendData
            .subscribe(onNext: { [weak self] recommendData in
                guard let self = self else { return }
                self.reloadTableView(recommendData)
            }).disposed(by: disposeBag)
        viewModel.selectedData
            .subscribe(onNext: { [weak self] selectedData in
                guard let self = self else { return }
                self.searchView.searchTextField.endEditing(true)
                if self.didInitialize {
                    self.initialSelectedCount = selectedData.count
                }
                self.selectedMemberList.snp.updateConstraints { (make) in
                    make.height.equalTo((selectedData.count == 0) ? 0 : 44)
                }
                self.selectedMemberList.setNeedsLayout()
                // 更新数据，如果数据量比较小，那么对比下数据是否发生变化，数据量大的情况下可能会耗时比较长，没太大必要
                var isSame = false
                let olds = self.selectedMemberList.getModels()
                if selectedData.count == olds.count , selectedData.count < 20 {
                    isSame = olds.elementsEqual(selectedData) { old, new in
                        return (old.id == new.id && old.avatarUrl == new.avatarUrl && old.name == new.name)
                    }
                }
                self.selectedMemberList.updateData(selectedData, shouldReload: !isSame)
            }).disposed(by: disposeBag)
        viewModel.updatedData
            .subscribe(onNext: { [weak self] (data, select) in
                guard let self = self else { return }
                let chatters = data.map { $0.asBTChatterModel }
                let noUpdateChatterData = UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel && self.chatterType == .group && self.isMultipleMembers
                self.delegate?.doSelect(self, chatters: chatters, currentChatter: select?.asBTChatterModel, trackInfo: self.trackInfo, noUpdateChatterData: noUpdateChatterData, completion: {
                    [weak self] update in
                    guard let self = self else { return }
                    //主要是为了避免数据还没协同过来的时候用户点了确无法跳转，如果是人员，回调的update会为nil
                    // 增加token后回调回来更新数据，如果增加token后的回调，那么不需要更新
                    if let update = update {
                        let model = update.asCapsuleModel(isSelected: true)
                        let datas: [BTCapsuleModel] = self.selectedMemberList.getModels().map {
                            return $0.id == model.id ? model : $0
                        }
                        // 仅仅更新了token，不需要刷新UI
                        self.selectedMemberList.updateData(datas, shouldReload: false)
                        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                            // 原来是依赖前端更新linktoken，现在每次点击不到前端，所以需要本地更新
                            self.viewModel.selectedData.accept(datas)
                        }
                    }
                })
            }).disposed(by: disposeBag)
    }

    @objc
    private func panToChangeSize(sender: UIPanGestureRecognizer) {
        let translationY = sender.translation(in: self).y
        var targetY = max((hostView?.bounds.height ?? 0) * 0.15 + translationY, hostView?.safeAreaInsets.top ?? 0)
        switch sender.state {
        case .changed:
            self.dragView.snp.updateConstraints { (make) in
                make.top.equalTo(targetY)
            }
            self.layoutIfNeeded()
        case .ended:
            let showHide: Bool = translationY > 0
            if translationY <= 0 {
                targetY = (hostView?.bounds.height ?? 0) * 0.15
            } else {
                targetY = hostView?.bounds.height ?? 0
            }
            UIView.animate(withDuration: 0.25) {
                self.dragView.snp.updateConstraints { (make) in
                    make.top.equalTo(targetY)
                }
                self.layoutIfNeeded()
            } completion: { (completed) in
                if (completed || UserScopeNoChangeFG.ZJ.btCardReform) && showHide  {
                    self.didHide(noUpdateChatterData: false)
                }
            }
        case .cancelled:
            targetY = (hostView?.bounds.height ?? 0) * 0.15
        default: targetY = max((hostView?.bounds.height ?? 0) * 0.15 + translationY, hostView?.safeAreaInsets.top ?? 0)
        }
    }

    private func didHide(noUpdateChatterData: Bool) {
        let finalSelectedCount = viewModel.selectedData.value.count
        if didInitialize || initialSelectedCount == finalSelectedCount {
            trackInfo.itemChangeType = .noChange
        } else if finalSelectedCount > initialSelectedCount {
            trackInfo.itemChangeType = .add
        } else {
            trackInfo.itemChangeType = .delete
        }
        if self.viewModel.notifyMode == .enabled(notifies: true) || self.viewModel.notifyMode == .enabled(notifies: false) {
            delegate?.saveNotifyStrategy(notifiesEnabled: self.viewModel.notifyMode.notifiesEnabled)
        }
        delegate?.finishSelecting(self, type: chatterType, chatters: viewModel.selectedData.value.map { return $0.asBTChatterModel },
                                  notifiesEnabled: self.viewModel.notifyMode.notifiesEnabled,
                                  trackInfo: self.trackInfo, justUpdateChatterData: false, noUpdateChatterData: noUpdateChatterData)
    }

    private func reloadTableView(_ recommendData: [RecommendData]) {
        var members = recommendData.map { (data) -> MemberItemProtocol in
            return data.asMemberItem
        }
        placeholderView.isHidden = !members.isEmpty
        viewModel.selectedData.value.forEach { (selected) in
            if !recommendData.contains(where: { return $0.token == selected.userID }) {
                members.append(selected.asMemberItem)
            }
        }

        tableView.items = members
        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BTChatterPanel: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, chatterType == .group {
            return 32
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, chatterType == .group else {
            return nil
        }
        let header = ChatterHeaderView()
        if let text = searchView.searchTextField.text {
            if text.isEmpty {
                header.label.text = BundleI18n.SKResource.Bitable_GroupChat_Recents_Title
            } else {
                header.label.text = BundleI18n.SKResource.Bitable_GroupChat_Results_Text
            }
        } else {
            header.label.text = BundleI18n.SKResource.Bitable_GroupChat_Recents_Title
        }
        return header
    }

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.selectedData.value.count < maximumSelectCount {
            return indexPath
        } else if viewModel.selectedData.value.count == maximumSelectCount &&
                    self.tableView.items[indexPath.row].selectType == .blue {
            return indexPath
        } else {
            delegate?.exceedSelectionAmount()
            return nil
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, chatterType == .group {
            delegate?.trackSelectCell()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.row
        guard self.tableView.items.count > index else {
            return
        }
        self.trackInfo.userDeleteItemSource = .bottomList
        viewModel.changeSelectStatus(at: index, token: self.tableView.items[index].identifier)
        if !isMultipleMembers, self.tableView.items[index].selectType == .blue {
            trackInfo.didClickDone = false
            trackInfo.isEditPanelOpen = false
            hide(immediately: false)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchView.endEditing(true)
    }
}

public protocol BTMemberPanelDelegate: BTSelectedChatterCollectionViewDelegate {
    func finishSelecting(_ panel: BTChatterPanel, type: BTChatterType, chatters: [BTChatterProtocol], notifiesEnabled: Bool, trackInfo: BTTrackInfo, justUpdateChatterData: Bool, noUpdateChatterData: Bool)
    func doSelect(_ panel: BTChatterPanel,
                  chatters: [BTChatterProtocol],
                  currentChatter: BTChatterProtocol?,
                  trackInfo: SKBrowser.BTTrackInfo,
                  noUpdateChatterData: Bool,
                  completion: ((BTChatterProtocol?) -> Void)?)
    func quickAddViewClick()
    func exceedSelectionAmount()
    func saveNotifyStrategy(notifiesEnabled: Bool)
    func obtainLastNotifyStrategy() -> Bool
    func trackSearchStartEdit()
    func trackSelectCell()
    func trackCancel()
}

public extension BTMemberPanelDelegate {
    func exceedSelectionAmount() {}
}

extension RecommendData {
    private static var _kRecommendDataSelectTypeKey: UInt8 = 0
    public var selectType: MemberItem.SelectType {
        get {
            guard let type = objc_getAssociatedObject(self, &Self._kRecommendDataSelectTypeKey) as? MemberItem.SelectType else {
                return .gray
            }
            return type
        }
        set { objc_setAssociatedObject(self,
                                       &Self._kRecommendDataSelectTypeKey,
                                       newValue,
                                       .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension MemberItem.SelectType {
    public mutating func changedSelectStatus() {
        self = (self == .gray) ? .blue: .gray
    }
}

extension RecommendData {

    fileprivate var asMemberItem: MemberItemProtocol {
        var item = MemberItem(identifier: token,
                          selectType: selectType,
                          imageURL: url,
                          title: contentForMainTitle,
                          detail: contentForSubTitle,
                          token: "",
                          isExternal: isExternal,
                          displayTag: displayTag,
                          isCrossTenanet: isCrossTenant)
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            item.avatarKey = avatarKey
        }
        return item
    }
}


fileprivate extension BTCapsuleModel {
    var asBTChatterModel: BTChatterProtocol {
        switch self.chatterType {
        case .group:
            return BTGroupModel(chatterId: self.id,
                                name: self.name,
                                avatarUrl: self.avatarUrl,
                                linkToken: token,
                                avatarKey: UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel ? avatarKey : nil)
        case .user:
            return BTUserModel(chatterId: self.id,
                               name: self.name,
                               enName: self.enName,
                               avatarUrl: self.avatarUrl)
        }
    }
    
    var asMemberItem: MemberItemProtocol {
        return MemberItem(identifier: self.id,
                          selectType: .blue,
                          imageURL: avatarUrl,
                          title: text,
                          detail: "",
                          token: token,
                          isExternal: false,
                          displayTag: nil,
                          isCrossTenanet: false)
    }
}
