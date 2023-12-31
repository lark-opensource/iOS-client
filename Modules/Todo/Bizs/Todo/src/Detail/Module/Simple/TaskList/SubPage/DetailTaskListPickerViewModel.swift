//
//  DetailTaskListPickerViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2022/12/27.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignFont

enum DetailTaskListPicker {
    case taskList(Rust.TaskContainer, [String: Rust.SectionRefResult])
    case sectionRef(Rust.TaskContainer, [String: Rust.SectionRefResult], Rust.ContainerTaskRef)
    case ownedSection(Rust.ContainerSection?, Rust.TaskSection)
    case none
}

enum DetailTaskListCreate {
    case taskList(String?)
    case sectionRef(Rust.TaskContainer, String?)
    case ownedSection(String?)
    case none
}

final class DetailTaskListPickerViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    /// picker的不同场景
    enum TaskListPickerScene {
        case taskList(_ selected: [Rust.TaskContainer]?)
        case sectionRefs([Rust.TaskContainer]?, [String: Rust.SectionRefResult]?)
        case ownedSections(Rust.ContainerSection?, [Rust.TaskSection])
    }
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    var onUpdate: (() -> Void)?

    /// 是否是清单场景
    var isTaskListScene: Bool {
        if case .taskList = scene { return true }
        return false
    }

    private let scene: TaskListPickerScene

    private let disposeBag = DisposeBag()
    /// 数据源
    private var taskListTuple: ([Rust.TaskContainer], [String: Rust.SectionRefResult]) = ([], [:])
    // cell Data
    private var cellDatas: [DetailTaskListPickerViewCellData] = []
    private var originalCellDatas: [DetailTaskListPickerViewCellData] = []

    private enum AttributeScene {
        case normal
        case caption
        case linkHover
        case blod
    }

    @ScopedInjectedLazy var listApi: TaskListApi?

    init(resolver: UserResolver, scene: TaskListPickerScene) {
        self.userResolver = resolver
        self.scene = scene
    }

    func setup() {
        switch scene {
        case .taskList(let selected):
            queryTaskList("", selected)
        case .sectionRefs(let taskLists, let sectionRefRes):
            fetchSections(taskLists: taskLists, sectionRefRes: sectionRefRes)
        case .ownedSections(let ownedSection, let sections):
            let data = sections.map { section in
                return SimpleCellData(name: section.displayName, identifier: section.guid)
            }
            var selectedIds = [String]()
            if let selectedId = ownedSection?.sectionGuid {
                selectedIds.append(selectedId)
            }
            makeCellData(data, markSelected: ownedSection?.sectionGuid, query: "")
            originalCellDatas = cellDatas
            onUpdate?()
        }
    }

    private func makeCellData(
        _ source: [SimpleCellData]?,
        removeSelected: [String]? = nil,
        markSelected: String? = nil,
        query: String
    ) {
        let seelctedTaskLists = removeSelected ?? [], sourceTaskList = source ?? []
        let leftDatas = sourceTaskList.filter { data in
            if seelctedTaskLists.contains(where: { $0 == data.identifier }) {
                return false
            }
            return true
        }

        cellDatas = leftDatas.map { data in
            let text = data.name, isChecked = markSelected == data.identifier
            let attributeText = MutAttrText(string: text, attributes: isChecked ? getAttribute(by: .linkHover) : getAttribute(by: .normal))
            if !isChecked, !query.isEmpty {
                calculateSubString(text, query).forEach { range in
                    if Utils.RichText.checkRangeValid(range, in: attributeText) {
                        attributeText.addAttribute(.foregroundColor, value: UIColor.ud.textLinkHover, range: range)
                    }
                }
            }
            return DetailTaskListPickerViewCellData(attributedText: attributeText, identifier: data.identifier, isChecked: markSelected == data.identifier)
        }
        if !query.isEmpty {
            let string = "\(createBtnText) "
            let attributeText = MutAttrText(string: string, attributes: getAttribute(by: .caption))
            attributeText.append(MutAttrText(string: query, attributes: getAttribute(by: .blod)))
            cellDatas.append(DetailTaskListPickerViewCellData(attributedText: attributeText, identifier: query, isAdd: true))
        }
    }

    private struct SimpleCellData {
        var name: String
        var identifier: String
    }

    private func makeTaskListCellData(_ source: [Rust.TaskContainer]?, selected: [Rust.TaskContainer]?, query: String) {
        let data = source?.map { container in
            return SimpleCellData(name: container.name, identifier: container.guid)
        }
        let selectedIds = selected?.map(\.guid)
        makeCellData(data, removeSelected: selectedIds, query: query)
    }

    private func calculateSubString(_ source: String, _ sub: String) -> [NSRange] {
        var rangeArray = [Range<String.Index>]()
        var searchedRange: Range<String.Index>
        guard let sr = source.range(of: source) else {
            return rangeArray.map { range in
                return NSRange(range, in: source)
            }
        }
        searchedRange = sr

        var resultRange = source.range(of: sub, options: .regularExpression, range: searchedRange, locale: nil)
        while let range = resultRange {
            rangeArray.append(range)
            searchedRange = Range(uncheckedBounds: (range.upperBound, searchedRange.upperBound))
            resultRange = source.range(of: sub, options: .regularExpression, range: searchedRange, locale: nil)
        }
        let ranges = rangeArray.map { range in
            return NSRange(range, in: source)
        }
        return ranges
    }

    private func fetchSections(taskLists: [Rust.TaskContainer]?, sectionRefRes: [String: Rust.SectionRefResult]?) {
        guard let taskLists = taskLists,
              let sectionRefRes = sectionRefRes,
              let sectionRef = sectionRefRes.values.first else {
            rxViewState.accept(.empty)
            onUpdate?()
            return
        }
        let taskListGuid = sectionRef.ref.containerGuid
        rxViewState.accept(.loading)
        listApi?.getContainerMetaData(by: taskListGuid, needSection: true)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] metaData in
                self?.rxViewState.accept(.data)
                var newSectionRef = sectionRef
                newSectionRef.sections = metaData.sections
                let selectedSection = metaData.sections.first(where: { $0.guid == sectionRef.ref.sectionGuid && $0.containerID == sectionRef.ref.containerGuid })
                if selectedSection == nil {
                    // 当前选中分组不存在，则回到默认分组
                    newSectionRef.ref.sectionGuid = metaData.sections.first(where: { $0.isDefault })?.guid ?? ""
                }
                self?.taskListTuple = (taskLists, [taskListGuid: newSectionRef])
                self?.makeSectionCellData(sectionRef: newSectionRef)
            }, onError: { [weak self] _ in
                self?.rxViewState.accept(.data)
                self?.taskListTuple = (taskLists, sectionRefRes)
                self?.makeSectionCellData(sectionRef: sectionRef)
            })
            .disposed(by: disposeBag)
    }

    private func makeSectionCellData(sectionRef: Rust.SectionRefResult) {
        let source = sectionRef.sections.map { section in
            return SimpleCellData(name: section.displayName, identifier: section.guid)
        }
        makeCellData(source, markSelected: sectionRef.ref.sectionGuid, query: "")
        originalCellDatas = cellDatas
        onUpdate?()
    }

    func queryTaskList(_ query: String, _ selected: [Rust.TaskContainer]?) {
        rxViewState.accept(.loading)
        listApi?.queryTaskList(by: query).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] (taskLists, sectionRefs) in
                guard let self = self else { return }
                self.taskListTuple = (taskLists, sectionRefs)
                self.makeTaskListCellData(taskLists, selected: selected, query: query)
                self.rxViewState.accept(self.cellDatas.isEmpty ? .empty : .data)
                self.onUpdate?()
            }, onError: { [weak self] _ in
                self?.makeTaskListCellData(nil, selected: nil, query: query)
                self?.rxViewState.accept(.data)
                self?.onUpdate?()
            })
            .disposed(by: disposeBag)
    }

    func queryData(_ query: String) {
        switch scene {
        case .taskList(let selected):
            queryTaskList(query, selected)
        case .sectionRefs, .ownedSections:
            filterCellData(by: query)
        }
    }

    private func filterCellData(by query: String) {
        if query.isEmpty {
            cellDatas = originalCellDatas
            onUpdate?()
            return
        }
        guard !originalCellDatas.isEmpty else {
            return
        }
        var markSelected: String?
        let datas = originalCellDatas
            .filter { cellData in
                return cellData.attributedText?.string.contains(query) ?? false
            }
            .map { cellData in
                if cellData.isChecked {
                    markSelected = cellData.identifier
                }
                return SimpleCellData(name: cellData.attributedText?.string ?? "", identifier: cellData.identifier ?? "")
            }
        makeCellData(datas, markSelected: markSelected, query: query)
        onUpdate?()
    }

}

// MARK: - Update

extension DetailTaskListPickerViewModel {

    func handleDefaultSelect(completion: ((DetailTaskListPicker) -> Void)?) {
        guard let selectedID = cellDatas.first(where: { $0.isChecked })?.identifier else { return }
        didSelectItem(with: selectedID, completion: completion)
    }

    func didCreateNew(with name: String?, completion: ((DetailTaskListCreate) -> Void)?) {
        switch scene {
        case .taskList:
            completion?(.taskList(name))
        case .ownedSections:
            completion?(.ownedSection(name))
        case .sectionRefs:
            guard let taskList = taskListTuple.0.first else {
                completion?(.none)
                return
            }
            completion?(.sectionRef(taskList, name))
        }
    }

    func didSelectItem(with id: String, completion: ((DetailTaskListPicker) -> Void)?) {
        switch scene {
        case .taskList:
            guard let taskList = taskListTuple.0.first(where: { $0.guid == id }),
                  let sectionRef = taskListTuple.1[id] else {
                completion?(.none)
                return
            }
            completion?(.taskList(taskList, [taskList.guid: sectionRef]))
        case .sectionRefs:
            guard let taskList = taskListTuple.0.first,
                  let sectionRef = taskListTuple.1.values.first,
                  let selectedSection = sectionRef.sections.first(where: { $0.guid == id }) else {
                completion?(.none)
                return
            }
            var newSectionRef = sectionRef
            newSectionRef.ref.sectionGuid = selectedSection.guid
            completion?(.sectionRef(taskList, [taskList.guid: newSectionRef], sectionRef.ref))
        case .ownedSections(let ownedSection, let sections):
            guard let section = sections.first(where: { $0.guid == id }) else {
                completion?(.none)
                return
            }
            completion?(.ownedSection(ownedSection, section))
        }
    }
}

// MARK: - TableVeiw

extension DetailTaskListPickerViewModel {

    func numberOfRows() -> Int { cellDatas.count }

    func cellData(indexPath: IndexPath) -> DetailTaskListPickerViewCellData? {
        guard let (_, row) = safeCheckIndexPath(indexPath) else { return nil }
        return cellDatas[row]
    }

    func safeCheckIndexPath(_ indexPath: IndexPath) -> (section: Int, row: Int)? {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && (cellDatas.isEmpty ? section == 0 : section < 1)
                && row >= 0
                && (cellDatas.isEmpty ? row == 0 : row < cellDatas.count)
        else {
            return nil
        }
        return (section, row)
    }

    var headerText: String {
        switch scene {
        case .sectionRefs, .ownedSections: return I18N.Todo_TaskSection_SelectASection_Title
        case .taskList: return I18N.Todo_AddTaskListInTaskDetails_Placeholder
        }
    }

    var subTitle: String? {
        switch scene {
        case .ownedSections: return I18N.Todo_New_OwnedByMe_TabTitle
        default: return nil
        }
    }

    var placeholder: String {
        return isTaskListScene ? I18N.Todo_ManageTaskList_SearchOrCreate_Placeholder : I18N.Todo_SearchSection_Placeholder
    }

    var createBtnText: String {
        return isTaskListScene ? I18N.Todo_ManageTaskList_CreateList_Button : I18N.Todo_CreateSectionName_Button
    }

    private func getAttribute(by scene: AttributeScene) -> [NSAttributedString.Key: Any] {
        var attrs = [NSAttributedString.Key: Any]()
        attrs[.font] = UDFont.systemFont(ofSize: 16)
        switch scene {
        case .caption:
            attrs[.foregroundColor] = UIColor.ud.textCaption
        case .linkHover:
            attrs[.foregroundColor] = UIColor.ud.textLinkHover
        case .normal:
            attrs[.foregroundColor] = UIColor.ud.textTitle
        case .blod:
            attrs[.font] = UDFont.systemFont(ofSize: 16, weight: .medium)
            attrs[.foregroundColor] = UIColor.ud.textTitle
        }
        return attrs
    }

}
