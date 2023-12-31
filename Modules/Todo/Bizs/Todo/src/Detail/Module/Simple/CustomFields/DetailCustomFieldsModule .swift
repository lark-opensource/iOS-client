//
//  DetailCustomFieldsModule .swift
//  Todo
//
//  Created by baiyantao on 2023/4/18.
//

import Foundation
import RxSwift
import LarkContainer
import UniverseDesignActionPanel
import LarkUIKit
import UniverseDesignDatePicker
import TodoInterface

// nolint: magic number
final class DetailCustomFieldsModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailCustomFieldsViewModel
    let containerView: DetailCustomFieldsView

    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    private let disposeBag = DisposeBag()

    private lazy var rootView = initRootView()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        self.containerView = DetailCustomFieldsView(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        bindViewData()
        bindViewAction()
        viewModel.maxContentViewWidth = context.viewController?.view.frame.width ?? 0
        viewModel.setup()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func initRootView() -> DetailCustomFieldsView {
        containerView.actionDelegate = self
        return containerView
    }
}

// MARK: - View Data
extension DetailCustomFieldsModule {
    private func bindViewData() {
        viewModel.rxViewState
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .content:
                    self.rootView.isHidden = false
                case .hidden:
                    self.rootView.isHidden = true
                }
            })
            .disposed(by: disposeBag)
        viewModel.rxHeaderData.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.rootView.headerData = data
            })
            .disposed(by: disposeBag)
        viewModel.rxFooterData.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.rootView.footerData = data
            })
            .disposed(by: disposeBag)
        viewModel.rxCellDatas.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] datas in
                guard let self = self else { return }
                self.rootView.cellDatas = datas
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - View Action

extension DetailCustomFieldsModule {
    private func bindViewAction() {
        rootView.headerView.clickHandler = { [weak self] in
            self?.viewModel.doToggleTopCollapsed()
        }
        rootView.footerView.clickHandler = { [weak self] in
            self?.viewModel.doExpandMore()
        }
    }
}

extension DetailCustomFieldsModule: DetailCustomFieldsContentCellDelegate {

    func onClickMore(_ cell: DetailCustomFieldsContentCell) {
        guard rootView.tableView.indexPath(for: cell) != nil else { return }
        viewModel.doExpandContent(cell.viewData)
    }

    func onClick(_ cell: DetailCustomFieldsContentCell) {
        rootView.endEditing(true)
        guard let data = cell.viewData else { return }

        if !context.store.state.permissions.customFields.isEditable {
            switch data.customType {
            case .member:
                break // member 的权限判断下放至 doSelectMember
            default:
                showNoAuthToast()
                return
            }
        }

        switch data.customType {
        case .time: doSelectTime(cell, data)
        case .member: doSelectMember(data)
        case .number: break
        case .tag: doSelectTags(data)
        case .text: showRichTextVC(data)
        }
    }

    func onClearMember(_ cell: DetailCustomFieldsContentCell) {
        guard let data = cell.viewData else { return }
        viewModel.doClearFieldVal(data)
    }

    func numberFieldShouldBeginEditing(_ cell: DetailCustomFieldsContentCell) -> Bool {
        let isEditable = context.store.state.permissions.customFields.isEditable
        if !isEditable {
            showNoAuthToast()
        }
        return isEditable
    }

    func onNumberFieldBeginEditing(_ cell: DetailCustomFieldsContentCell) {
        context.registerBottomInsetRelay(context.rxKeyboardHeight, forKey: "customFields.number.input")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if let globalFrame = self.context.tableView?.convert(cell.frame, from: self.rootView.tableView) {
                self.context.tableView?.scrollRectToVisible(globalFrame, animated: true)
            }
        }
    }

    func onNumberFieldEndEditing(content: String?, data: DetailCustomFieldsContentCellData?) {
        context.unregisterBottomInsetRelay(forKey: "customFields.number.input")
        if let content = content, let data = data {
            viewModel.doUpdateNumber(content, data)
        }
    }

    private func showNoAuthToast() {
        if let window = self.view.window {
            Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
        }
    }

    private func doSelectTime(
        _ cell: DetailCustomFieldsContentCell,
        _ cellData: DetailCustomFieldsContentCellData
    ) {
        guard let fromVC = context.viewController,
            case .time(let date, _) = cellData.customType else {
            return
        }
        let config = UDWheelsStyleConfig(mode: .yearMonthDayWeek, maxDisplayRows: 5)
        let vc = DCWheelPickerViewController(
            customTitle: cellData.titleText,
            date: date,
            timeZone: timeService?.rxTimeZone.value ?? .current,
            wheelConfig: config
        )
        vc.confirm = { [weak self, weak vc] (date) in
            self?.viewModel.doUpdateTime(date, cellData)
            vc?.dismiss(animated: true)
        }
        vc.onClear = { [weak self] in
            self?.viewModel.doClearFieldVal(cellData)
        }

        if fromVC.rootSizeClassIsRegular {
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = cell
            vc.preferredContentSize = CGSize(width: 375, height: vc.intrinsicHeight)
            let sourceRect = CGRect(
                x: cell.frame.width / 2,
                y: cell.frame.height / 2,
                width: 0, height: 0
            )
            vc.popoverPresentationController?.sourceRect = sourceRect
            vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            fromVC.present(vc, animated: true, completion: nil)
        } else {
            let panel = UDActionPanel(
                customViewController: vc,
                config: UDActionPanelUIConfig(
                    originY: UIScreen.main.bounds.height - vc.intrinsicHeight,
                    canBeDragged: false
                )
            )
            fromVC.present(panel, animated: true, completion: nil)
        }
    }

    private func doSelectMember(_ cellData: DetailCustomFieldsContentCellData) {
        guard case .memberFieldSettings(let settings) = cellData.assoc.taskField.settings.setting,
              case .member(let users, _) = cellData.customType else {
            assertionFailure()
            return
        }

        let isEditable = context.store.state.permissions.customFields.isEditable
        if settings.multiple {
            if users.isEmpty {
                guard isEditable else {
                    showNoAuthToast()
                    return
                }
                showMultiMemberPicker(cellData)
            } else {
                showMemberList(cellData)
            }
        } else {
            guard isEditable else {
                showNoAuthToast()
                return
            }
            showSingleMemberPicker(cellData)
        }
    }

    private func showMultiMemberPicker(_ cellData: DetailCustomFieldsContentCellData) {
        guard let fromVC = context.viewController else { return }
        var routeParams = RouteParams(from: fromVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showChatterPicker(
            title: cellData.titleText,
            chatId: nil,
            isAssignee: false,
            selectedChatterIds: [],
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)
                self?.viewModel.doUpdateMembers(chatterIds, cellData)
            },
            params: routeParams
        )
    }

    private func showMemberList(_ cellData: DetailCustomFieldsContentCellData) {
        guard let fromVC = context.viewController,
              let (input, dependency) = viewModel.listMembersContext(cellData) else {
            return
        }
        let vm = MemberListViewModel(resolver: userResolver, input: input, dependency: dependency)
        let vc = MemberListViewController(resolver: userResolver, viewModel: vm)
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func showSingleMemberPicker(_ cellData: DetailCustomFieldsContentCellData) {
        guard let fromVC = context.viewController else { return }
        var routeParams = RouteParams(from: fromVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showOwnerPicker(
            title: cellData.titleText,
            chatId: nil,
            selectedChatterIds: [],
            supportbatchAdd: false,
            disableBatchAdd: false,
            batchHandler: nil,
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)
                self?.viewModel.doUpdateMembers(chatterIds, cellData)
            },
            params: routeParams
        )
    }

    private func doSelectTags(_ cellData: DetailCustomFieldsContentCellData) {
        guard let fromVC = context.viewController else { return }
        let tagOptions: [Rust.SelectFieldOption]
        let selection: CustomFieldsTagsPanelViewModel.Selection

        switch cellData.assoc.taskField.settings.setting {
        case .singleSelectFieldSettings(let setting):
            tagOptions = setting.options
            guard case .singleSelectFieldValue(let val) = cellData.fieldVal?.value else {
                selection = .single(selectGuid: nil)
                break
            }
            selection = .single(selectGuid: val.value)
        case .multiSelectFieldSettings(let setting):
            tagOptions = setting.options
            guard case .multiSelectFieldValue(let val) = cellData.fieldVal?.value else {
                selection = .multi(selectGuids: [])
                break
            }
            selection = .multi(selectGuids: val.value)
        @unknown default:
            assertionFailure()
            return
        }

        let vm = CustomFieldsTagsPanelViewModel(tagOptions: tagOptions, selection: selection)
        let vc = CustomFieldsTagsPanelViewController(viewModel: vm, title: cellData.titleText)
        vm.updateHandler = { [weak self] selection in
            self?.viewModel.doUpdateTags(selection, cellData)
        }
        let config = UDActionPanelUIConfig(
            originY: UIScreen.main.bounds.height - vm.getContentHeight(),
            canBeDragged: false
        )
        let panel = UDActionPanel(customViewController: vc, config: config)
        fromVC.present(panel, animated: true, completion: nil)
    }

    private func showRichTextVC(_ cellData: DetailCustomFieldsContentCellData) {
        let richContent = cellData.fieldVal?.textFieldValue.value ?? .init()
        guard let fromVC = context.viewController else { return }
        let vc = DetailNotesViewController(
            resolver: userResolver,
            richContent: richContent,
            isEditable: true,
            inputController: viewModel.inputController
        )
        vc.naviTitle = cellData.titleText
        vc.scene = .customFiled
        vc.onSave = { [weak self] data in
            self?.viewModel.updateTextValue(data, cellData)
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }
}
