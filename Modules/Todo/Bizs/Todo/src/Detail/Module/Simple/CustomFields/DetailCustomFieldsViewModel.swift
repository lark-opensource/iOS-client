//  DetailCustomFieldsViewModel.swift
//  Todo
//
//  Created by baiyantao on 2023/4/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import LarkRichTextCore
import LKRichView

final class DetailCustomFieldsViewModel: UserResolverWrapper {

    // view max width
    var maxContentViewWidth: CGFloat = 0 {
        didSet {
            guard oldValue != maxContentViewWidth else { return }
            reloadData()
        }
    }

    // view driver
    let rxViewState = BehaviorRelay<ViewState>(value: .hidden)
    let rxHeaderData = BehaviorRelay<DetailCustomFieldsHeaderViewData>(value: .init())
    let rxFooterData = BehaviorRelay<DetailCustomFieldsFooterViewData>(value: .init())
    let rxCellDatas = BehaviorRelay<[DetailCustomFieldsContentCellData]>(value: [])

    // dependence
    let userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    private let store: DetailModuleStore
    private let disposeBag = DisposeBag()

    // internal state
    private var isTopCollapsed = false // 顶部是否收起，可以展开收起反复操作
    private var bottomNeedFold = true // 底部是否折叠内容，点击展开后不可回退
    private let bottomFoldCount = 5

    private var styleSheets: [CSSStyleSheet] {
        var atColor = AtColor()
        atColor.OuterForegroundColor = UIColor.ud.textLinkNormal
        return RichViewAdaptor.createStyleSheets(
            config: RichViewAdaptor.Config(
                normalFont: UDFont.systemFont(ofSize: 14),
                atColor: atColor)
        )
    }

    private(set) lazy var inputController = InputController(resolver: userResolver, sourceId: store.state.scene.todoId)

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() {
        guard store.state.scene.isForEditing else {
            rxViewState.accept(.hidden)
            return
        }

        Observable.combineLatest(
            store.rxValue(forKeyPath: \.customFieldValues).distinctUntilChanged(), // 数据
            store.rxValue(forKeyPath: \.containerTaskFieldAssocList).distinctUntilChanged(), // 底座
            store.rxValue(forKeyPath: \.relatedTaskLists).distinctUntilChanged() // 排序信息
        ).subscribe(onNext: { [weak self] _, _, _ in
            self?.reloadData()
        }).disposed(by: disposeBag)
    }

    private func reloadData() {
        guard !isTopCollapsed else {
            rxCellDatas.accept([])
            rxHeaderData.accept(.init(isCollapsed: true))
            rxFooterData.accept(.init(state: .noMore))
            rxViewState.accept(.content)
            return
        }

        let fieldValues = store.state.customFieldValues
        let assocList = store.state.containerTaskFieldAssocList
        let taskLists = store.state.relatedTaskLists

        DetailCustomFields.logger.info("reload. fieldValues: \(fieldValues.values.map { $0.logInfo }), assocList: \(assocList.map { $0.logInfo })")
        if let taskLists {
            DetailCustomFields.logger.info("reload. taskLists: \(taskLists.map { $0.guid })")
        }
        var cellDatas = handleData(fieldValues, assocList, taskLists)
        guard !cellDatas.isEmpty else {
            self.rxViewState.accept(.hidden)
            return
        }

        if bottomNeedFold, cellDatas.count > bottomFoldCount {
            cellDatas = Array(cellDatas.prefix(bottomFoldCount))
            rxFooterData.accept(.init(state: .hasMore))
        } else {
            rxFooterData.accept(.init(state: .noMore))
        }

        rxHeaderData.accept(.init(isCollapsed: false))
        rxCellDatas.accept(cellDatas)
        rxViewState.accept(.content)
    }
}

// MARK: - View Data

extension DetailCustomFieldsViewModel {
    private func handleData(
        _ fieldValues: [String: Rust.TaskFieldValue],
        _ assocList: [Rust.ContainerTaskFieldAssoc],
        _ taskLists: [Rust.TaskContainer]?
    ) -> [DetailCustomFieldsContentCellData] {
        guard let taskLists = taskLists, !taskLists.isEmpty, !assocList.isEmpty else { return [] }
        //去重：FieldValue 有可能出现多次（多个清单挂了同一个字段），以第一次出现的地方为准
        let uniqueAssoc = assocList.lf_unique { $0.taskField.key }
        // 排序：先按照清单顺序排序，清单内按照创建时间排序
        var sortedAssoc = [Rust.ContainerTaskFieldAssoc]()
        taskLists.forEach { taskList in
            let belongToList = uniqueAssoc
                .filter { $0.containerGuid == taskList.guid }
                .sorted { $0.createMilliTime < $1.createMilliTime }
            sortedAssoc.append(contentsOf: belongToList)
        }
        return sortedAssoc.compactMap { assoc in
            return combine(fieldValues[assoc.taskField.key], assoc) ?? nil
        }
    }

    private func combine(
        _ fieldVal: Rust.TaskFieldValue?,
        _ assoc: Rust.ContainerTaskFieldAssoc
    ) -> DetailCustomFieldsContentCellData? {

        let iconImage: UIImage
        let type: DetailCustomFieldsContentCellData.CustomType
        var isEmpty = false, showMore = false

        switch assoc.taskField.type {
        case .datetime:
            iconImage = UDIcon.calendarDateOutlined
            let settings = assoc.taskField.settings.datetimeFieldSettings
            let formatter = DetailCustomFields.dateSettings2Formatter(settings)
            guard case .datetimeFieldValue(let val) = fieldVal?.value, val.value != 0 else {
                type = .time(date: Date(), formatter: formatter)
                isEmpty = true
                break
            }
            let date = Date(timeIntervalSince1970: TimeInterval(val.value / 1000))
            type = .time(date: date, formatter: formatter)
        case .member:
            iconImage = UDIcon.memberOutlined
            guard case .memberFieldValue(let val) = fieldVal?.value, !val.value.isEmpty else {
                type = .member(users: [], canClear: false)
                isEmpty = true
                break
            }
            type = .member(
                users: val.value.map { User(pb: $0.user) },
                canClear: store.state.permissions.customFields.isEditable
            )
        case .number:
            let settings = assoc.taskField.settings.numberFieldSettings
            iconImage = UDIcon.numberOutlined
            guard case .numberFieldValue(let val) = fieldVal?.value, !val.value.isEmpty,
                  let doubleVal = Double(val.value) else {
                type = .number(rawString: "", rawDouble: nil, settings: settings)
                isEmpty = true
                break
            }
            type = .number(rawString: val.value, rawDouble: doubleVal, settings: settings)
        case .singleSelect:
            let setting = assoc.taskField.settings.singleSelectFieldSettings
            iconImage = UDIcon.downRoundOutlined
            guard case .singleSelectFieldValue(let val) = fieldVal?.value,
                  !val.value.isEmpty,
                  let option = setting.options.first(where: { $0.guid == val.value }) else {
                type = .tag(options: [])
                isEmpty = true
                break
            }
            type = .tag(options: [option])
        case .multiSelect:
            let setting = assoc.taskField.settings.multiSelectFieldSettings
            iconImage = UDIcon.groupSelectionOutlined
            guard case .multiSelectFieldValue(let val) = fieldVal?.value, !val.value.isEmpty else {
                type = .tag(options: [])
                isEmpty = true
                break
            }
            let guid2Option = Dictionary(
                setting.options.map { ($0.guid, $0) },
                uniquingKeysWith: { (first, _) in first }
            )
            type = .tag(options: val.value.compactMap { guid2Option[$0] })
        case .text:
            if FeatureGating(resolver: userResolver).boolValue(for: .textField) {
                iconImage = UDIcon.styleOutlined
                guard case .textFieldValue(let val) = fieldVal?.value, !val.value.richText.isEmpty else {
                    type = .text(text: .init())
                    isEmpty = true
                    break
                }
                let (core, size) = makeRichViewData(val.value)
                type = .text(text: core)
                showMore = size.height > DetailCustomFields.contentMaxHeight
            } else {
                return nil
            }
        default:
            return nil
        }
        return DetailCustomFieldsContentCellData(
            iconImage: iconImage.ud.withTintColor(UIColor.ud.iconN3),
            titleText: assoc.taskField.name,
            customType: type,
            showMore: showMore && bottomNeedFold,
            isEmpty: isEmpty,
            fieldVal: fieldVal,
            assoc: assoc
        )
    }

    private func makeRichViewData(_ content: Rust.RichContent) -> (LKRichViewCore, CGSize) {
        let result = RichViewAdaptor.parseRichTextToRichElement(
            richText: content.richText,
            isShowReadStatus: false,
            checkIsMe: nil,
            defaultTextColor: UIColor.ud.textTitle
        )
        let core = LKRichViewCore()
        core.load(styleSheets: styleSheets)
        core.load(renderer: core.createRenderer(result))
        let size = core.layout(CGSize(width: (maxContentViewWidth - DetailCustomFields.hMargin * 2), height: .greatestFiniteMagnitude)) ?? .zero
        return (core, size)
    }
}

// MARK: - View Action

extension DetailCustomFieldsViewModel {

    func doExpandMore() {
        DetailCustomFields.logger.info("doExpandMore")
        bottomNeedFold = false
        reloadData()
    }

    func doToggleTopCollapsed() {
        DetailCustomFields.logger.info("doToggleTopCollapsed, val: \(isTopCollapsed)")
        isTopCollapsed = !isTopCollapsed
        Detail.Track.toggleCustomFieldsList(guid: store.state.scene.todoId, isCollapsed: isTopCollapsed)
        reloadData()
    }

    func doUpdateTime(_ date: Date, _ cellData: DetailCustomFieldsContentCellData) {
        DetailCustomFields.logger.info("doUpdateTime, assoc: \(cellData.assoc.logInfo)")
        var fieldVal = cellData.fieldVal ?? .init()
        fieldVal.completeMetaDataIfNeeded(with: cellData.assoc, and: store.state.scene.todoId ?? "")
        var dateFieldVal = fieldVal.datetimeFieldValue
        dateFieldVal.value = Int64(date.timeIntervalSince1970 * 1000)
        fieldVal.datetimeFieldValue = dateFieldVal
        doUpdateFieldVal(fieldVal)
    }

    func doUpdateTags(
        _ selection: CustomFieldsTagsPanelViewModel.Selection,
        _ cellData: DetailCustomFieldsContentCellData
    ) {
        DetailCustomFields.logger.info("doUpdateTags, assoc: \(cellData.assoc.logInfo), val: \(selection.logInfo)")
        var fieldVal = cellData.fieldVal ?? .init()
        fieldVal.completeMetaDataIfNeeded(with: cellData.assoc, and: store.state.scene.todoId ?? "")
        switch selection {
        case .single(let selectGuid):
            var singleFieldVal = fieldVal.singleSelectFieldValue
            singleFieldVal.value = selectGuid ?? ""
            fieldVal.singleSelectFieldValue = singleFieldVal
        case .multi(let selectGuids):
            var multiFieldVal = fieldVal.multiSelectFieldValue
            multiFieldVal.value = selectGuids
            fieldVal.multiSelectFieldValue = multiFieldVal
        }
        doUpdateFieldVal(fieldVal)
    }

    func doUpdateNumber(_ content: String, _ cellData: DetailCustomFieldsContentCellData) {
        DetailCustomFields.logger.info("doUpdateNumber, assoc: \(cellData.assoc.logInfo)")
        var content = content

        // 保存的时候，需要抹去精度以外的位数
        if let doubleVal = Double(content) {
            var decimalCount = cellData.assoc.taskField.settings.numberFieldSettings.decimalCount
            // 百分比类型的特化，需要额外多给两位数
            if cellData.assoc.taskField.settings.numberFieldSettings.format == .percentage {
                decimalCount += 2
            }
            if let stringVal = DetailCustomFields.double2String(doubleVal, decimalCount: decimalCount) {
                content = stringVal
            }
        }

        var fieldVal = cellData.fieldVal ?? .init()
        fieldVal.completeMetaDataIfNeeded(with: cellData.assoc, and: store.state.scene.todoId ?? "")
        var numberFieldValue = fieldVal.numberFieldValue
        guard numberFieldValue.value != content else { return }
        numberFieldValue.value = content
        fieldVal.numberFieldValue = numberFieldValue
        doUpdateFieldVal(fieldVal)
    }

    func doUpdateMembers(_ chatterIds: [String], _ cellData: DetailCustomFieldsContentCellData) {
        DetailCustomFields.logger.info("doUpdateMembers, assoc: \(cellData.assoc.logInfo), chatterIds: \(chatterIds)")
        guard !chatterIds.isEmpty else { return }
        fetchApi?.getUsers(byIds: chatterIds)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] users in
                    guard let self = self, !users.isEmpty else { return }
                    var fieldVal = cellData.fieldVal ?? .init()
                    fieldVal.completeMetaDataIfNeeded(
                        with: cellData.assoc, and: self.store.state.scene.todoId ?? ""
                    )
                    var memberFieldValue = fieldVal.memberFieldValue
                    memberFieldValue.value = users.map {
                        Rust.TaskMember(member: Member.user(User(pb: $0)))
                    }
                    fieldVal.memberFieldValue = memberFieldValue
                    self.doUpdateFieldVal(fieldVal)
                }
            )
            .disposed(by: disposeBag)
    }

    func doClearFieldVal(_ cellData: DetailCustomFieldsContentCellData) {
        DetailCustomFields.logger.info("doClearFieldVal, assoc: \(cellData.assoc.logInfo)")
        var fieldVal = Rust.TaskFieldValue()
        fieldVal.completeMetaDataIfNeeded(with: cellData.assoc, and: store.state.scene.todoId ?? "")
        doUpdateFieldVal(fieldVal)
    }

    func updateTextValue(_ new: Rust.RichContent, _ cellData: DetailCustomFieldsContentCellData) {
        var fieldVal = cellData.fieldVal ?? .init()
        fieldVal.completeMetaDataIfNeeded(with: cellData.assoc, and: store.state.scene.todoId ?? "")
        var textValue = fieldVal.textFieldValue
        textValue.value = new
        fieldVal.textFieldValue = textValue
        doUpdateFieldVal(fieldVal)
    }

    func doExpandContent(_ cellData: DetailCustomFieldsContentCellData?) {
        guard let firstIndex = rxCellDatas.value.firstIndex(where: { $0.fieldVal == cellData?.fieldVal }) else {
            DetailCustomFields.logger.error("expand custom field content failed")
            return
        }
        var cellDatas = rxCellDatas.value
        cellDatas[firstIndex].showMore = false
        rxCellDatas.accept(cellDatas)
    }

    private func doUpdateFieldVal(_ fieldVal: Rust.TaskFieldValue) {
        Detail.Track.editCustomField(with: store.state.scene.todoId)
        store.dispatch(.updateCustomFields(fieldVal))
    }
}

extension DetailCustomFieldsViewModel: MemberListViewModelDependency {
    
    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?) { }

    func listMembersContext(_ cellData: DetailCustomFieldsContentCellData) -> (
        input: MemberListViewModelInput,
        dependency: MemberListViewModelDependency
    )? {
        guard case .member(let users, _) = cellData.customType else { return nil }
        let state = store.state
        let input = MemberListViewModelInput(
            todoId: state.todo?.guid ?? "",
            todoSource: state.todo?.source ?? .todo,
            chatId: nil,
            scene: .custom_fields(fieldKey: cellData.assoc.taskField.key, title: cellData.titleText),
            selfRole: state.selfRole,
            canEditOther: state.permissions.customFields.isEditable,
            members: users.map { Member.user($0) }
        )
        return (input: input, dependency: self)
    }

    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        guard case .custom_fields(let fieldKey, _) = input.scene,
              let assoc = store.state.containerTaskFieldAssocList.first(
                where: { $0.taskField.key == fieldKey }
              ) else {
            return
        }
        DetailCustomFields.logger.info("appendMembers, assoc: \(assoc.logInfo), ids: \(members.map { $0.logInfo })")
        var fieldVal = store.state.customFieldValues[fieldKey] ?? .init()
        fieldVal.completeMetaDataIfNeeded(with: assoc, and: store.state.scene.todoId ?? "")
        var memberVal = fieldVal.memberFieldValue
        var totalMembers = memberVal.value
        totalMembers += members.map { Rust.TaskMember(member: $0) }
        memberVal.value = totalMembers
        fieldVal.memberFieldValue = memberVal
        doUpdateFieldVal(fieldVal)
    }

    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        guard case .custom_fields(let fieldKey, _) = input.scene,
              let assoc = store.state.containerTaskFieldAssocList.first(
                where: { $0.taskField.key == fieldKey }
              ) else {
            return
        }
        DetailCustomFields.logger.info("removeMembers, assoc: \(assoc.logInfo), ids: \(members.map { $0.logInfo })")
        var fieldVal = store.state.customFieldValues[fieldKey] ?? .init()
        fieldVal.completeMetaDataIfNeeded(with: assoc, and: store.state.scene.todoId ?? "")
        var memberVal = fieldVal.memberFieldValue
        let totalMembers = memberVal.value
        let idSet = Set(members.compactMap { $0.asUser()?.chatterId })
        memberVal.value = totalMembers.filter { !idSet.contains($0.user.userID) }
        fieldVal.memberFieldValue = memberVal
        doUpdateFieldVal(fieldVal)
    }
}

// MARK: - Other

extension DetailCustomFieldsViewModel {
    enum ViewState {
        case content
        case hidden
    }
}
