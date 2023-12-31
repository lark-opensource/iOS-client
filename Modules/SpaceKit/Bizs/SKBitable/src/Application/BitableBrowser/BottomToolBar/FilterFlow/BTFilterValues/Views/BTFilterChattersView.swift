//
//  BTFilterChattersView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/1/29.
//

import RxCocoa
import SKCommon
import SKUIKit
import SKResource
import SKBrowser
import SKFoundation
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignLoading

protocol BTFilterChattersViewDelegate: AnyObject {
    func valueChanged(_ value: MemberItem, selected: Bool)
}

/// 后续稳定后把BTFilterUsersView 给删除掉
public final class BTFilterChattersView: UIView {
    
    private(set) var alls: [MemberItem] = []
    
    private(set) var selecteds: [MemberItem] = []
    
    private(set) var shows: [MemberItem] = []
    
    private var isAllowMultipleSelect: Bool
    
    private var viewModel: BTFilterValueChatterViewModel
    
    private var keyboard: Keyboard?

    private var isFromNewFilter = false
    
    weak var delegate: BTFilterChattersViewDelegate?
    
    var searchText: String? {
        return searchView.searchTextField.text
    }
    
    lazy var searchView: BTSearchView = {
        let view = BTSearchView(shouldShowRightBtn: false)
        view.backgroundColor = .clear
        view.searchTextField.backgroundColor = UDColor.bgFloat
        view.isHidden = true
        return view
    }()
    
    lazy var selectedMemberListView: BTSelectedChatterCollectionView = {
        let view = BTSelectedChatterCollectionView(nil)
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var membersListView: MembersTableView = {
        let tView = MembersTableView()
        tView.itemBackgroundColor = UDColor.bgFloatBase
        tView.backgroundColor = UDColor.bgFloatBase
        tView.isShowHeadLine = false
        tView.delegate = self
        return tView
    }()
    
    private lazy var emptyView = BTEmptyView()
    
    private let loadingViewManager = BTLaodingViewManager()
    
    //用来放emptyView和loading
    private lazy var placeholderViewContainer: UIView = UIView().construct { it in
        it.backgroundColor = .clear
        it.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.centerY.greaterThanOrEqualToSuperview()
        }
    }
    
    init(viewModel: BTFilterValueChatterViewModel,
         isAllowMultipleSelect: Bool) {
        self.isAllowMultipleSelect = isAllowMultipleSelect
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
    }
    
    init(datas: [MemberItem],
         isAllowMultipleSelect: Bool) {
        self.isAllowMultipleSelect = isAllowMultipleSelect
        self.isFromNewFilter = true
        // 假的用来改代码的
        self.viewModel = BTFilterValueChatterViewModel(fieldId: "", selectedMembers: [], isAllowMultipleSelect: true, chatterType: .group, btDataService: nil)
        super.init(frame: .zero)
        setupViews()
        self.setData(data: datas)
        self.membersListView.items = datas
        updateEmptyView()
        let capsules: [BTCapsuleModel] = selecteds.compactMap {
            var model = BTCapsuleModel(id: $0.identifier,
                                  text: $0.title,
                                  color: BTColorModel(),
                                  isSelected: true,
                                  token: $0.token ?? "",
                                  avatarUrl: $0.imageURL ?? "",
                                  userID: $0.identifier,
                                  enName: $0.title,
                                  chatterType: viewModel.chatterType)
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                model.avatarKey = $0.avatarKey
            }
            return model
        }
        setSelectedMemberListShow(capsules.count > 0 && isAllowMultipleSelect)
        self.selectedMemberListView.updateData(capsules)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        keyboard?.stop()
    }
    
    private func reloadData() {
        // 单允许多选，切当时已有选中时，显示顶部已选中的人员
        if isAllowMultipleSelect && selecteds.count > 0 {
            setSelectedMemberListShow(true)
            let capsules: [BTCapsuleModel] = selecteds.compactMap {
                var model = BTCapsuleModel(id: $0.identifier,
                                      text: $0.title,
                                      color: BTColorModel(),
                                      isSelected: true,
                                      token: $0.token ?? "",
                                      avatarUrl: $0.imageURL ?? "",
                                      userID: $0.identifier,
                                      enName: $0.title,
                                      chatterType: viewModel.chatterType)
                if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                    model.avatarKey = $0.avatarKey
                }
                return model
            }
            selectedMemberListView.updateData(capsules)
        } else {
            setSelectedMemberListShow(false)
        }
        // 刷新底部的表格
        self.membersListView.items = shows
        self.membersListView.reloadData()
        self.updateEmptyView()
    }
    
    func setData(data: [MemberItem]) {
        self.searchView.isHidden = false
        self.alls = data
        self.shows = data.filter({ $0.isShow ?? false })
        self.selecteds = alls.filter({ $0.selectType == .blue })
        reloadData()
    }
    
    func handleData(data: [MemberItem]) {
        self.searchView.isHidden = false
        self.alls = data
        let content = searchView.searchTextField.text ?? ""
        if content.isEmpty {
            self.shows = self.alls
        } else {
            self.shows = self.alls.filter { $0.title.contains(content) }
        }
        
        self.selecteds = alls.filter({ $0.selectType == .blue })
        
        reloadData()
    }
    
    private func updateEmptyView() {
        let desc = BundleI18n.SKResource.Bitable_Mobile_CannotEditOption
        if alls.isEmpty {
            placeholderViewContainer.isHidden = false
            emptyView.updateShowType(.showNoData(desc: desc))
        } else if shows.isEmpty {
            placeholderViewContainer.isHidden = false
            emptyView.updateShowType(.showNoRearchResult(desc: desc))
        } else {
            placeholderViewContainer.isHidden = true
            emptyView.updateShowType(.hide)
        }
    }
    
    func deselected(at index: Int, isHandleAll: Bool = true) {
        let member = isHandleAll ? shows[index] : selecteds[index]
        if self.isFromNewFilter {
            delegate?.valueChanged(member, selected: false)
        } else {
            self.selecteds.removeAll(where: { $0.identifier == member.identifier })
            self.alls = updateMembers(alls, item: member, isSelected: false)
            self.shows = updateMembers(shows, item: member, isSelected: false)
            viewModel.updateSelectedMembers(selecteds)
            reloadData()
        }
    }
    
    private func selected(at index: Int) {
        let member = shows[index]
        if self.isFromNewFilter {
            delegate?.valueChanged(member, selected: true)
        } else {
            self.alls = updateMembers(alls, item: member, isSelected: true)
            self.shows = updateMembers(shows, item: member, isSelected: true)
            if isAllowMultipleSelect {
                selecteds.append(member)
            } else {
                selecteds = [member]
            }
            viewModel.updateSelectedMembers(selecteds)
            reloadData()
        }
    }
    
    private func updateMembers(_ members: [MemberItem], item: MemberItem, isSelected: Bool) -> [MemberItem] {
        var item = item
        var members = members
        // 如果是单选，要把其他的选项给移除掉
        if isSelected, !isAllowMultipleSelect {
            members = members.map {
                var _item = $0
                _item.selectType = _item.identifier == item.identifier ? .blue : .gray
                return _item
            }
        } else {
            if let index = members.firstIndex(where: { $0.identifier == item.identifier }) {
                item.selectType = isSelected ? .blue : .gray
                members[index] = item
            }
        }
        return members
    }
    
    private func setupViews() {
        addSubview(searchView)
        addSubview(selectedMemberListView)
        addSubview(membersListView)
        addSubview(placeholderViewContainer)
        
        searchView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        
        selectedMemberListView.snp.makeConstraints { (make) in
            make.top.equalTo(searchView.snp.bottom).offset(16)
            make.bottom.equalTo(membersListView.snp.top).offset(0)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        membersListView.snp.makeConstraints { (make) in
            make.right.left.bottom.equalToSuperview()
        }
        
        placeholderViewContainer.snp.makeConstraints { (make) in
            make.top.right.left.bottom.equalTo(membersListView)
        }
        
        startKeyBoardObserver()
    }
    
    private func startKeyBoardObserver() {
        keyboard = Keyboard(listenTo: [searchView.searchTextField], trigger: "bitableFilterMember")
        keyboard?.on(events: [.willShow, .didShow]) { [weak self] option in
            guard let self = self else { return }

            let realKeyboardHeight = option.endFrame.height
            let remainHeightExceptKeyboard = self.bounds.height - self.placeholderViewContainer.frame.minY - 48
            var remainHeight = remainHeightExceptKeyboard - realKeyboardHeight

            remainHeight = max(133, remainHeight)

            let bottomOffset = remainHeightExceptKeyboard - remainHeight

            UIView.performWithoutAnimation {

                self.placeholderViewContainer.snp.updateConstraints { make in
                    make.bottom.equalTo(self.membersListView).offset(-bottomOffset)
                }

                self.layoutIfNeeded()
            }
        }

        keyboard?.on(events: [.willHide, .didHide]) { [weak self] _ in
            guard let self = self else { return }
            
            UIView.performWithoutAnimation {
                self.placeholderViewContainer.snp.updateConstraints { make in
                    make.bottom.equalTo(self.membersListView)
                }
                
                self.layoutIfNeeded()
            }
        }
        keyboard?.start()
    }
    
    private func setSelectedMemberListShow(_ isShow: Bool) {
        selectedMemberListView.isHidden = !isShow
        if isShow {
            selectedMemberListView.snp.remakeConstraints { (make) in
                make.top.equalTo(searchView.snp.bottom).offset(0)
                make.bottom.equalTo(membersListView.snp.top).offset(-12)
                make.left.right.equalToSuperview()
                make.height.equalTo(44)
            }
            
        } else {
            selectedMemberListView.snp.remakeConstraints { (make) in
                make.top.equalTo(searchView.snp.bottom).offset(16)
                make.bottom.equalTo(membersListView.snp.top).offset(0)
                make.left.right.equalToSuperview()
                make.height.equalTo(0)
            }
        }
    }
    
    ///开启loading计时器，超过200ms无数据，显示loading
    func startLoadingTimer() {
        self.perform(#selector(type(of: self).showLoading), with: nil, afterDelay: 0.2)
    }
    
    ///显示加载中的loading
    @objc
    private func showLoading() {
        DocsLogger.btInfo("[BTFilterMembersView] showLoading")
        emptyView.updateShowType(.hide)
        membersListView.isHidden = true
        placeholderViewContainer.isHidden = false
        
        loadingViewManager.showLoading(superView: placeholderViewContainer)
        
        bringSubviewToFront(placeholderViewContainer)
    }
    
    ///隐藏loading
    func hideLoading() {
        DocsLogger.btInfo("[BTFilterMembersView] hideLoading")
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        membersListView.isHidden = false
        placeholderViewContainer.isHidden = true
        loadingViewManager.hideLoading()
    }
    
    ///显示超时重试页面
    func showTryAgainEmptyView(text: String, type: UDEmptyType, tryAgainBlock: (() -> Void)? = nil) {
        DocsLogger.btInfo("[BTFilterMembersView] showTryAgainEmptyView")
        hideLoading()
        emptyView.isHidden = false
        placeholderViewContainer.isHidden = false
        let listEmptyConfig = loadingViewManager.getTryAgainEmptyConfig(description: text, type: type) {
            [weak self] in
            tryAgainBlock?()
            DocsLogger.btInfo("[BTFilterMembersView] did Click TryAgain Button")
            self?.emptyView.updateShowType(.hide)
            self?.showLoading()
        }
        
        emptyView.updateConfig(listEmptyConfig)
    }
}

extension BTFilterChattersView: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard shows.count > indexPath.row else {
            return
        }
        if shows[indexPath.row].selectType == .blue {
            deselected(at: indexPath.row)
        } else {
            selected(at: indexPath.row)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchView.endEditing(true)
    }
}

