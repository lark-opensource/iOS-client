//
//  TodoSectionsManager.swift
//  LarkContact
//
//  Created by 白言韬 on 2021/2/3.
//

import Foundation
import LarkUIKit
import LarkModel
import LarkContainer
import LarkSDKInterface
import RustPB
import RxSwift
import LarkSearchCore
import LarkMessengerInterface
import LKCommonsTracker
import Homeric
import LarkBizAvatar
import LarkAccountInterface
import UniverseDesignCheckBox
import LarkTag
import LarkBizTag
import UIKit
import LarkFeatureGating
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignToast
import UniverseDesignButton

/// Todo业务对于选人组件的特化逻辑
final class TodoSectionsManager: UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    var recommendSection: TodoRecommendSection?
    var inChatSection: TodoRecommendSection?
    private let passportUserService: PassportUserService?

    weak var selectionDataSource: SelectionDataSource?

    private var chatterAPI: ChatterAPI?
    private var chatAPI: ChatAPI?
    private var userApi: UserAPI?

    private let disposeBag = DisposeBag()

    private(set) var info: ChatterPickerSource.TodoInfo?
    private(set) var isShowSelectAll: IsShowSelectAll = .hidden
    private(set) var formatRule: UserNameFormatRule = .nameFirst

    init(selectionDataSource: SelectionDataSource?, source: ChatterPickerSource?, resolver: UserResolver) {
        self.selectionDataSource = selectionDataSource
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
        self.chatterAPI = try? resolver.resolve(assert: ChatterAPI.self)
        self.chatAPI = try? resolver.resolve(assert: ChatAPI.self)
        self.userApi = try? resolver.resolve(assert: UserAPI.self)
        if case .todo(let info) = source {
            self.info = info
        }
    }

    func setup(tableView: UITableView) {
        guard let info = self.info, let userApi = self.userApi, let chatterAPI = self.chatterAPI, let chatAPI = self.chatAPI else {
            return
        }

        Tracker.post(TeaEvent("todo_select_view"))

        let recommendSection = TodoRecommendSection(headerTitle: BundleI18n.Todo.Todo_Task_Mention, isAssignee: info.isAssignee, currentTenantID: passportUserService?.userTenant.tenantID ?? "")
        recommendSection.selectionDataSource = selectionDataSource
        recommendSection.setup(tableView: tableView, completion: nil)
        recommendSection.trackerSource = info.chatId == nil ? "center" : "im"
        self.recommendSection = recommendSection

        if let chatId = info.chatId, !chatId.isEmpty {
            let inChatSection = TodoRecommendSection(headerTitle: BundleI18n.Todo.Todo_Task_ChatMembers, isAssignee: info.isAssignee, currentTenantID: passportUserService?.userTenant.tenantID ?? "")
            inChatSection.selectionDataSource = selectionDataSource
            inChatSection.setup(tableView: tableView, completion: nil)
            inChatSection.trackerSource = "im"
            self.inChatSection = inChatSection

            Observable.zip(
                chatAPI.getChatLimitInfo(chatId: chatId),
                chatAPI.fetchChat(by: chatId, forceRemote: false),
                userApi.getAnotherNameFormat()
            ).take(1).asSingle()
            .subscribe(onSuccess: { [weak self] tuple in
                guard let self = self else { return }
                let (limitInfo, chat, rule) = tuple
                if !limitInfo.openSecurity,
                   let isMultiple = self.selectionDataSource?.isMultiple, isMultiple,
                   let chat = chat, chat.type != .p2P {
                    self.isShowSelectAll = chat.userCount <= 100 ? .show(disabled: false) : .show(disabled: true)
                }
                self.formatRule = rule
                self.inChatSection?.isShowSelectAll = self.isShowSelectAll
                self.fetchChatData(chatId, tableView)
            }).disposed(by: disposeBag)
        } else {
            Observable.zip(
                chatterAPI.getTodoRecommendedChatters(count: nil),
                userApi.getAnotherNameFormat()
            ).observeOn(MainScheduler.instance)
            .take(1).asSingle()
            .subscribe(onSuccess: { [weak self](tuple) in
                let (response, rule) = tuple
                self?.formatRule = rule
                self?.onRecommendData(response, tableView: tableView)
                tableView.reloadData()
            })
            .disposed(by: disposeBag)
        }

        selectionDataSource?.selectedChangeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    func isChatSectionAllSeletcted(tableView: UITableView) -> Bool {
        /// 判断当前所有选项是否已被全部选中
        guard let options = inChatSection?.cellInfos, let dataSource = selectionDataSource else { return false }
         return !options.contains(where: {
            let optionState = dataSource.state(for: $0.0, from: tableView)
            return !optionState.selected
        })
    }

    private func fetchChatData(_ chatId: String, _ tableView: UITableView) {
        guard let chatterAPI = self.chatterAPI else { return }
        if case .show(let disabled) = isShowSelectAll, !disabled {
            Observable.zip(
                // filter: 第二个参数是 isRemote，这里筛掉非 remote 的结果
                chatterAPI.fetchAtListWithLocalOrRemote(chatId: chatId, query: nil).filter { $0.1 }.map { $0.0 },
                chatterAPI.getChatChatters(
                    chatId: chatId, filter: nil, cursor: nil, limit: 100, condition: nil, forceRemote: false, offset: nil, fromScene: nil
                )
            ).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] tuple in
                guard let self = self else { return }
                let (chatData, allChatData) = tuple

                self.onChatData(
                    chatData,
                    allChatChatters: allChatData.entity.chatChatters[chatId]?.chatters ?? [:],
                    tableView: tableView
                )
                tableView.reloadData()
            }).disposed(by: disposeBag)
        } else {
            // filter: 第二个参数是 isRemote，这里筛掉非 remote 的结果
            chatterAPI.fetchAtListWithLocalOrRemote(chatId: chatId, query: nil)
            .filter { $0.1 }.map { $0.0 }
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] chatData in
                guard let self = self else { return }

                self.onChatData(chatData, tableView: tableView)
                tableView.reloadData()
            }).disposed(by: disposeBag)
        }
    }

    /// 通过API获取当前用户的 Chatter，插入到 recommend section 的首位
    private func insertCurrentChatter(tableView: UITableView) {
        guard let userService = self.passportUserService, let chatterAPI = self.chatterAPI else { return }
        let currentChatterId = userService.user.userID
        chatterAPI.getChatter(id: currentChatterId)
        .filter { $0 != nil }
        .take(1).asSingle()
        .observeOn(MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] chatter in
            guard let self = self, let chatter = chatter else { return }
            if var cellInfos: [(Chatter, String?)] = self.recommendSection?.cellInfos.filter({ $0.0.id != currentChatterId }) {
                cellInfos.insert((chatter, nil), at: 0)
                self.recommendSection?.cellInfos = cellInfos.filter { self.chatterFilter($0.0, tableView: tableView) }
                tableView.reloadData()
            }
        }).disposed(by: disposeBag)
    }

    private func onRecommendData(_ data: RustPB.Todo_V1_GetRecommendedContentsResponse, tableView: UITableView) {
        let chattersDic = data.chatters
        guard let userService = self.passportUserService else { return }
        let currentChatterId = userService.user.userID
        let currentDepartment = data.recommendContents.filter({ $0.id == currentChatterId })
            .map({ $0.department }).first
        // 可能想添加的人中，先把自己过滤掉，再放到首位
        var cellInfos: [(Chatter, String?)] = data.recommendContents.compactMap {
            if let pb = chattersDic[$0.id] {
                return (Chatter.transform(pb: pb), $0.department)
            }
            return nil
        }.filter { $0.0.id != currentChatterId }
        if let pb = chattersDic[currentChatterId], let department = currentDepartment {
            cellInfos.insert((Chatter.transform(pb: pb), department), at: 0)
        } else {
            insertCurrentChatter(tableView: tableView)
        }
        recommendSection?.cellInfos = cellInfos.filter({ chatterFilter($0.0, tableView: tableView) })
        // 需要把名字的展示规则传入
        recommendSection?.manager = self
    }

    private func onChatData(
        _ data: RustPB.Im_V1_GetMentionChatChattersResponse,
        allChatChatters: [String: Basic_V1_Chatter] = [:],
        tableView: UITableView
    ) {
        func getCellInfo(_ id: String) -> (Chatter, String?)? {
            // 因为有群外的人，所以优先取群成员，取不到则尝试取‘entity.chatters’
            if let chatId = self.info?.chatId,
               let pb = data.entity.chatChatters[chatId]?.chatters[id] ??
                data.entity.chatters[id] {
                return (Chatter.transform(pb: pb), nil)
            }
            return nil
        }

        func getCellInfos(_ ids: [String]) -> [(Chatter, String?)] {
            ids.compactMap {(chatterId) -> (Chatter, String?)? in
                return getCellInfo(chatterId)
            }
        }

        // 在可能想添加的人中，首位默认展示自己
        func sortCellInfos(_ cellInfos: [(Chatter, String?)]) -> [(Chatter, String?)] {
            let currentChatterId = passportUserService?.user.userID ?? ""
            if let currentChatterItem = getCellInfo(currentChatterId) {
                var newCellInfos = cellInfos.filter { $0.0.id != currentChatterId }
                newCellInfos.insert(currentChatterItem, at: 0)
                return newCellInfos
            } else {
                insertCurrentChatter(tableView: tableView)
                return cellInfos
            }
        }

        var cellInfos = getCellInfos(data.wantedMentionIds)
        recommendSection?.cellInfos = sortCellInfos(cellInfos).filter {
            chatterFilter($0.0, tableView: tableView)
        }
        if !allChatChatters.isEmpty {
            inChatSection?.cellInfos = allChatChatters.values.map { (chatter) -> (Chatter, String?) in
                return (Chatter.transform(pb: chatter), nil)
            }.filter { chatterFilter($0.0, tableView: tableView) }
        } else {
            inChatSection?.cellInfos = getCellInfos(data.inChatChatterIds).filter {
                chatterFilter($0.0, tableView: tableView)
            }
        }
        // 仅会话 section 把 manager 的依赖传进去，用来展示全选按钮
        recommendSection?.manager = self
        inChatSection?.manager = self
    }

    private func chatterFilter(_ chatter: Chatter, tableView: UITableView) -> Bool {
        guard chatter.type == .user, !chatter.isAnonymous,
              let state = selectionDataSource?.state(for: chatter, from: tableView),
              state.asContactCheckBoxStaus != .defaultSelected else {
            return false
        }
        return true
    }
}

final class TodoRecommendSection: SectionDataSource {

    weak var manager: TodoSectionsManager?
    weak var selectionDataSource: SelectionDataSource?
    var cellInfos: [(Chatter, String?)] = []
    var trackerSource: String?

    var isShowSelectAll: IsShowSelectAll?

    var formatRule: UserNameFormatRule {
        manager?.formatRule ?? .nameFirst
    }

    var isSelectAll: Bool {
        get {
            manager?.info?.isSelectAll ?? false
        }
        set {
            manager?.info?.isSelectAll = newValue
        }
    }

    private let headerTitle: String
    private let isAssignee: Bool
    private let currentTenantID: String

    init(headerTitle: String, isAssignee: Bool, currentTenantID: String) {
        self.headerTitle = headerTitle
        self.isAssignee = isAssignee
        self.currentTenantID = currentTenantID
    }

    func setup(tableView: UITableView, completion: ((Result<Void, Error>) -> Void)?) {
        tableView.register(TodoRecommendSectionCell.self, forCellReuseIdentifier: "TodoRecommendSectionCell")
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !cellInfos.isEmpty else { return nil }
        let header = TodoRecommendSectionHeader()
        header.titleLabel.text = headerTitle
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellInfos.isEmpty ? .zero : 30
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fixedCount()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellInfos.isEmpty ? .zero : 72
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(
            withIdentifier: "TodoRecommendSectionCell",
            for: indexPath
        )
        var index = indexPath.row
        guard let cell = reusableCell as? TodoRecommendSectionCell,
              index < fixedCount() else {
            return UITableViewCell()
        }

        // 全选按钮
        if case .show(let disabled) = isShowSelectAll, index == 0 {
            var checkBoxStatus: ContactCheckBoxStaus
            if disabled {
                checkBoxStatus = .defaultSelected
            } else {
                checkBoxStatus = isSelectAll ? .selected : .unselected
            }
            cell.viewData = TodoRecommendSectionCellData(
                identifier: "",
                avatarKey: "",
                avatarImage: Resources.todoSelectAllImage,
                name: BundleI18n.Todo.Todo_GroupTask_MobSelectAllGroupMembersNum_CheckBox,
                tagInfo: [],
                department: nil,
                checkBoxStatus: checkBoxStatus
            )
            return cell
        }

        if case .show = isShowSelectAll {
            index -= 1
        }
        let chatter = cellInfos[index].0
        let department = cellInfos[index].1

        let dispalyName = { (chatter: Chatter, rule: UserNameFormatRule) -> String in
            switch rule {
            case.nameFirst, .unknown:
                if !chatter.alias.isEmpty {
                    return "\(chatter.alias)(\(chatter.localizedName))"
                } else if !chatter.anotherName.isEmpty {
                    return "\(chatter.localizedName)(\(chatter.anotherName))"
                } else {
                    return "\(chatter.localizedName)"
                }
            case .anotherNameFirst:
                switch (!chatter.alias.isEmpty, !chatter.anotherName.isEmpty) {
                case (true, true):
                    return "\(chatter.alias)(\(chatter.anotherName))"
                case (true, false):
                    return "\(chatter.alias)(\(chatter.localizedName))"
                case (false, true):
                    return "\(chatter.anotherName)(\(chatter.localizedName))"
                case (false, false):
                    return "\(chatter.localizedName)"
                }
            }
        }

        var pb = chatter.transform()
        var tagInfo: [TagDataItem] = pb.tagInfo.transform()

        cell.viewData = TodoRecommendSectionCellData(
            identifier: chatter.id,
            avatarKey: chatter.avatarKey,
            name: dispalyName(chatter, formatRule),
            tagInfo: tagInfo,
            department: department,
            checkBoxStatus: getCheckBoxStaus(chatter: chatter, from: tableView)
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        var index = indexPath.row
        guard index < fixedCount(), let selectionDataSource = selectionDataSource else {
            return
        }

        // 全选按钮
        if case .show(let disabled) = isShowSelectAll, index == 0 {
            if disabled {
                if let window = tableView.window {
                    UDToast.showWarning(with: BundleI18n.Todo.Todo_TooManyGroupMembersUnableToSelectAll_Hover, on: window)
                }
                return
            }
            isSelectAll = !isSelectAll
            if isSelectAll {
                selectionDataSource.batchSelect(options: cellInfos.map { $0.0 }, from: tableView)
            } else {
                selectionDataSource.batchDeselect(options: cellInfos.map { $0.0 }, from: tableView)
            }
            Tracker.post(TeaEvent("todo_select_click", params: [
                "click": isSelectAll ? "select_all" : "remove_all",
                "select_type": isAssignee ? "is_exector" : "is_follower"
            ]))
            tableView.reloadData()
            return
        }

        if case .show = isShowSelectAll {
            index -= 1
        }
        selectionDataSource.toggle(option: cellInfos[index].0, from: tableView)

        let isSelected = selectionDataSource.state(for: cellInfos[index].0, from: tableView).selected

        if (isSelectAll && !isSelected) || (!isSelectAll && manager?.isChatSectionAllSeletcted(tableView: tableView) ?? false) {
            ///两种判断情况
            ///1. 当前已经全选，并且刚刚取消了一个选中，则需要全选状态转变
            ///2. 当前没有全选，并且刚刚选中已经是最后一个选项，即代表所有选中，则需要全选状态转变
            isSelectAll = !isSelectAll
            tableView.reloadData()
        }
        if let source = trackerSource, isSelected {
            Tracker.post(TeaEvent(Homeric.TODO_ADD_PERFORMER, params: [
                "type": "suggest",
                "source": source
            ]))
        }
        Tracker.post(TeaEvent("todo_select_click", params: [
            "click": isSelected ? "select_user" : "remove_user",
            "select_type": isAssignee ? "is_exector" : "is_follower"
        ]))
    }

    private func fixedIndex(_ index: Int) -> Int {
        if case .show = isShowSelectAll {
            return index + 1
        } else {
            return index
        }
    }

    private func fixedCount() -> Int {
        if cellInfos.isEmpty {
            return 0
        }
        if case .show = isShowSelectAll {
            return cellInfos.count + 1
        } else {
            return cellInfos.count
        }
    }

    private func getCheckBoxStaus(chatter: Chatter, from: UITableView) -> ContactCheckBoxStaus {
        if let source = selectionDataSource, !source.isMultiple {
            return .invalid
        }
        if let state = selectionDataSource?.state(for: chatter, from: from) {
            return state.asContactCheckBoxStaus
        }
        return .unselected
    }
}

private final class TodoRecommendSectionHeader: UITableViewCell {

    let titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBase

        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private struct TodoRecommendSectionCellData {
    var identifier: String
    var avatarKey: String
    var avatarImage: UIImage?
    var name: String
    var tagInfo: [TagDataItem]
    var department: String?
    var checkBoxStatus: ContactCheckBoxStaus
}

enum IsShowSelectAll {
    case show(disabled: Bool)
    case hidden
}

private final class TodoRecommendSectionCell: UITableViewCell {

    var viewData: TodoRecommendSectionCellData? {
        didSet {
            guard let viewData = viewData else { return }

            nameLabel.text = viewData.name
            departmentLabel.text = viewData.department
            departmentLabel.isHidden = viewData.department?.isEmpty ?? true
            if let image = viewData.avatarImage {
                avatarView.image = image
            } else {
                avatarView.setAvatarByIdentifier(
                    viewData.identifier,
                    avatarKey: viewData.avatarKey,
                    avatarViewParams: .init(sizeType: .size(avatarSize)),
                    backgroundColorWhenError: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5)
                )
            }
            updateCheckBox(status: viewData.checkBoxStatus)

            chatterTagBuilder.update(with: viewData.tagInfo)
            nameTag.isHidden = chatterTagBuilder.isDisplayedEmpty()

            nameLabel.snp.updateConstraints {
                $0.top.equalTo(avatarView).offset(departmentLabel.isHidden ? 12 : 0)
            }
        }
    }

    private let avatarSize = CGFloat(48)

    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    private lazy var nameTag: TagWrapperView = {
        let tagView = chatterTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()
    private lazy var chatterTagBuilder = ChatterTagViewBuilder()
    private let departmentLabel = UILabel()
    private let checkBox = UDCheckBox(boxType: .multiple, config: .init(unselectedBackgroundEnabledColor: .clear))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = BaseCellSelectView()

        contentView.backgroundColor = UIColor.ud.bgBody

        checkBox.isUserInteractionEnabled = false
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints {
            $0.width.height.equalTo(20)
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        contentView.addSubview(avatarView)
        updateAvatarViewLayout(hideCheckBox: false)

        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarView)
            $0.left.equalTo(avatarView.snp.right).offset(12)
            $0.height.equalTo(24)
        }

        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(nameTag)
        nameTag.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.left.equalTo(nameLabel.snp.right).offset(6)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
        }

        departmentLabel.textColor = UIColor.ud.textPlaceholder
        departmentLabel.font = .systemFont(ofSize: 14)
        departmentLabel.text = nil
        contentView.addSubview(departmentLabel)
        departmentLabel.snp.makeConstraints {
            $0.bottom.equalTo(avatarView)
            $0.left.equalTo(avatarView.snp.right).offset(12)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(20)
        }

        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalTo(nameLabel)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAvatarViewLayout(hideCheckBox: Bool) {
        if hideCheckBox {
            avatarView.snp.remakeConstraints {
                $0.width.height.equalTo(avatarSize)
                $0.left.equalToSuperview().offset(16)
                $0.centerY.equalToSuperview()
            }
        } else {
            avatarView.snp.remakeConstraints {
                $0.width.height.equalTo(avatarSize)
                $0.left.equalTo(checkBox.snp.right).offset(12)
                $0.centerY.equalToSuperview()
            }
        }
    }

    private func updateCheckBox(status: ContactCheckBoxStaus) {
        updateAvatarViewLayout(hideCheckBox: status == .invalid)
        switch status {
        case .invalid:
            checkBox.isHidden = true
        case .selected:
            checkBox.isHidden = false
            updateCheckBox(selected: true, enabled: true)
        case .unselected:
            checkBox.isHidden = false
            updateCheckBox(selected: false, enabled: true)
        case .defaultSelected:
            checkBox.isHidden = false
            updateCheckBox(selected: true, enabled: false)
        case .disableToSelect:
            checkBox.isHidden = false
            updateCheckBox(selected: false, enabled: false)
        }
    }

    private func updateCheckBox(selected: Bool, enabled: Bool) {
       selectionStyle = enabled ? .default : .none
       checkBox.isEnabled = enabled
       checkBox.isSelected = selected
    }

}

// Todo业务批量指派子任务
final class TodoBatchAddView: UIView {

    lazy var topLineView = UIView()
    lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.getIconByKey(
            .teamAddOutlined,
            renderingMode: .automatic,
            iconColor: isDisableBatch ? UIColor.ud.textLinkDisabled : UIColor.ud.textLinkNormal,
            size: CGSize(width: 20, height: 20)
        )
        return icon
    }()
    lazy var batchAddLabel: UILabel = {
        let labelView = UILabel()
        labelView.font = UIFont.systemFont(ofSize: 16)
        labelView.textColor = isDisableBatch ? UIColor.ud.textLinkDisabled : UIColor.ud.textLinkNormal
        return labelView
    }()
    var batchAdd: (() -> Void)?

    private let isDisableBatch: Bool

    init(isDisableBatch: Bool) {
        self.isDisableBatch = isDisableBatch
        super.init(frame: .zero)
        setComponents()
        setConstraints()
        setApperance()
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAddBatch))
        self.addGestureRecognizer(singleTapGesture)
        self.isUserInteractionEnabled = true //允许视图交互
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setComponents() {
        addSubview(icon)
        addSubview(batchAddLabel)
        addSubview(topLineView)
    }

    private func setConstraints() {
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(17)
        }
        batchAddLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(12)
            make.centerY.equalTo(icon)
            make.height.equalTo(22)
        }
        topLineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    private func setApperance() {
        topLineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.backgroundColor = UIColor.ud.bgBody
        batchAddLabel.text = BundleI18n.Todo.Todo_MultiselectMembersToAssignTasks_Button
    }

    @objc
    func tapAddBatch() {
        batchAdd?()
    }

}

final class TodoShareBottomView: UIView {
    lazy var topLineView: UIView = {
        let topLineView = UIView()
        topLineView.backgroundColor = UIColor.ud.lineDividerDefault
        return topLineView
    }()
    lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Todo.Todo_TaskList_ShareSelectNum_Text(0)
        label.textColor = UIColor.ud.primaryContentDefault
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    lazy var nextBtn: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let nextBtn = UDButton(config)
        nextBtn.titleLabel?.font = .systemFont(ofSize: 12)
        nextBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        nextBtn.setTitle(BundleI18n.Todo.Todo_TaskList_ShareNext_Button, for: .normal)
        nextBtn.layer.cornerRadius = 4
        nextBtn.addTarget(self, action: #selector(tapNextBtn), for: .touchUpInside)
        nextBtn.isEnabled = false
        return nextBtn
    }()
    var doShare: (() -> Void)?

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        setComponents()
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setComponents() {
        addSubview(topLineView)
        addSubview(label)
        addSubview(nextBtn)
    }

    private func setConstraints() {
        topLineView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
        label.snp.makeConstraints { (make) in
            make.top.equalTo(topLineView.snp.bottom).offset(15)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(nextBtn.snp.left).offset(-16)
        }
        nextBtn.snp.makeConstraints { (make) in
            make.top.equalTo(topLineView.snp.bottom).offset(11)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(28)
        }
    }

    func updateState(num: Int) {
        label.text = BundleI18n.Todo.Todo_TaskList_ShareSelectNum_Text(num)
        nextBtn.isEnabled = num > 0
    }

    @objc
    func tapNextBtn() {
        doShare?()
    }
}
