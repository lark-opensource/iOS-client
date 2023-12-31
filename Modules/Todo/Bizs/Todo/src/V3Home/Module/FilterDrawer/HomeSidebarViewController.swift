//
//  HomeSidebarViewController.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/10.
//

import CTFoundation
import LarkContainer
import RxSwift
import RxCocoa
import AnimatedTabBar
import UniverseDesignActionPanel
import LarkUIKit
import UniverseDesignDialog

final class HomeSidebarViewController: V3HomeModuleController {

    private let viewModel: HomeSidebarViewModel
    private let disposeBag = DisposeBag()

    private lazy var headerView = FilterDrawerHeaderView()
    private lazy var collectionView = configCollectionView()
    // internal state
    private var isPopover: Bool { modalPresentationStyle == .popover }

    required init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.viewModel = HomeSidebarViewModel(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HomeSidebar.Track.view()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubview()
        bindViewState()
    }


    private func setupSubview() {
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(56)
        }

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // 分屏时 dismiss 掉自己
        NotificationCenter.default.rx
            .notification(AnimatedTabBarController.styleChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func bindViewState() {
        viewModel.rxListUpdate
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    self.collectionView.layoutIfNeeded()
                    self.collectionView.reloadData()
                })
            .disposed(by: disposeBag)
    }

}

extension HomeSidebarViewController {

    private func configCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = .zero
        layout.itemSize = .zero
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsVerticalScrollIndicator = true
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = UIColor.ud.bgBody
        cv.clipsToBounds = true
//        cv.dragInteractionEnabled = true
//        cv.dropDelegate = self
//        cv.dragDelegate = self
        cv.ctf.register(cellType: HomeSidebarCell.self)
        cv.ctf.register(headerViewType: HomeSidebarHeaderView.self)
        cv.ctf.register(footerViewType: HomeSidebarFooterView.self)
        return cv
    }

}

extension HomeSidebarViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let viewSections = viewModel.sections
        guard let (section, row) = Utils.safeCheckIndexPath(at: indexPath, with: viewSections) else { return .zero }
        let header = viewSections[section].header
        if header.isCollapsed { return .zero }
        let item = viewSections[section].items[row]
        return CGSize(width: collectionView.bounds.width - HomeSidebarItemData.Config.hPadding, height: item.preferredHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        let viewSections = viewModel.sections
        guard Utils.safeCheckSection(in: section, with: viewSections) != nil else { return .zero }
        let header = viewSections[section].header
        return CGSize(width: collectionView.bounds.width, height: header.preferredHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        let viewSections = viewModel.sections
        guard Utils.safeCheckSection(in: section, with: viewSections) != nil else { return .zero }
        let footer = viewSections[section].footer
        return CGSize(width: collectionView.bounds.width, height: footer.preferredHeight)
    }

}

extension HomeSidebarViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let viewSections = viewModel.sections
        guard Utils.safeCheckSection(in: section, with: viewSections) != nil else { return .zero }
        let header = viewSections[section].header
        if header.isCollapsed { return .zero }
        return viewSections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewSections = viewModel.sections
        guard let cell = collectionView.ctf.dequeueReusableCell(HomeSidebarCell.self, for: indexPath) else {
            return UICollectionViewCell()
        }
        guard let (section, row) = Utils.safeCheckIndexPath(at: indexPath, with: viewSections) else {
            let itemsCount = viewSections.reduce(0) { partialResult, section in
                return partialResult + section.items.count
            }
            viewModel.logger.error("index is \(indexPath), sections: \(viewSections.count), items = \(itemsCount)")
            return cell
        }
        let item = viewSections[section].items[row]
        cell.viewData = item
        let tuple = viewModel.needMaskItem(at: item)
        cell.lu.addCorner(corners: tuple.corners, cornerSize: tuple.cornerSize)
        cell.onTapAccessortyHandler = { [weak self] (sourceView, containerGuid, ref) in
            guard let self = self, let guid = containerGuid,
                  let container = self.viewModel.getContainer(by: guid) else {
                return
            }
            self.context.bus.post(.tasklistMoreAction(
                data: .init(container: container, ref: ref),
                sourceView: sourceView,
                sourceVC: self,
                scene: .drawer
            ))
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let viewSections = viewModel.sections
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = collectionView.ctf.dequeueReusableHeaderView(HomeSidebarHeaderView.self, for: indexPath),
                  let section = Utils.safeCheckSection(in: indexPath.section, with: viewSections) else {
                return UICollectionReusableView()
            }
            let headerData = viewSections[section].header
            header.viewData = headerData
            let tupe = viewModel.needMaskHeader(at: headerData, with: viewSections[section].items.isEmpty)
            header.backgroundView.lu.addCorner(corners: tupe.corners, cornerSize: tupe.cornerSize)
            header.onTapHeaderHandler = { [weak self] in
                self?.viewModel.doTapSectionHeader(at: indexPath, completion: { [weak self] category in
                    if let category = category, category.isAdd {
                        HomeSidebar.Track.createSection(true)
                        let newSection = self?.viewModel.getNewSection(from: self?.viewModel.getLastSection())
                        self?.showUpsertSectionDialog(section: newSection)
                    } else {
                        self?.dismiss(animated: true)
                    }
                })
            }
            header.onTapTailingViewHandler = { [weak self] (sourceView, category) in
                self?.showCreateActionSheet(from: sourceView, with: category)
            }
            return header
        case UICollectionView.elementKindSectionFooter:
            guard let footer = collectionView.ctf.dequeueReusableFooterView(HomeSidebarFooterView.self, for: indexPath),
                  Utils.safeCheckSection(in: indexPath.section, with: viewSections) != nil else {
                return UICollectionReusableView()
            }

            return footer
        default:
            V3Home.assertionFailure()
            return UICollectionReusableView()
        }
    }

    private func showCreateActionSheet(from sourceView: UIView, with category: HomeSidebarHeaderData.Category) {
        enum ActionType {
            case addTasklist
            case addSection(Rust.TaskListSection)
            case renameSection(Rust.TaskListSection)
            case addTaskListInSection(Rust.TaskListSection)
            case deleteSection(Rust.TaskListSection)

            var title: String? {
                switch self {
                case .addTasklist, .addTaskListInSection: return I18N.Todo_CreateNewList_Title
                case .addSection: return I18N.Todo_TaskList_NewSection_Title
                case .renameSection: return I18N.Todo_TaskListSection_Rename_DropDown_Button
                case .deleteSection: return I18N.Todo_TaskList_ection_Delete_DropDown_Button
                }
            }
        }
        let items: [ActionType] = {
            switch category {
            case .taskLists:
                var actions = [ActionType]()
                actions.append(.addTasklist)
                if let lastSection = viewModel.getLastSection() {
                    actions.append(.addSection(lastSection))
                }
                return actions
            case .section(let taskListSection):
                return [
                    .renameSection(taskListSection),
                    .addTaskListInSection(taskListSection),
                    .deleteSection(taskListSection)
                ]
            default: return []
            }
        }()

        guard !items.isEmpty else { return }
        let source = UDActionSheetSource(
            sourceView: sourceView,
            sourceRect: CGRect(
                x: sourceView.frame.width / 2,
                y: sourceView.frame.height / 2 + 2,
                width: 0, height: 0
            ),
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(popSource: source)
        let actionSheet = UDActionSheet(config: config)
        items.forEach { actionType in
            actionSheet.addDefaultItem(text: actionType.title ?? "") { [weak self] in
                switch actionType {
                case .addTasklist:
                    HomeSidebar.Track.willCreateTasklist(with: nil, and: true)
                    let defaultSection = self?.viewModel.getDefaultSection()
                    self?.showCreateTaskList(in: defaultSection)
                case .addSection(let lastSection):
                    HomeSidebar.Track.createSection(false)
                    let new = self?.viewModel.getNewSection(from: lastSection)
                    self?.showUpsertSectionDialog(section: new)
                case .renameSection(let taskListSection):
                    HomeSidebar.Track.renameSection()
                    self?.showUpsertSectionDialog(section: taskListSection)
                case .addTaskListInSection(let taskListSection):
                    HomeSidebar.Track.willCreateTasklist(with: nil, and: false)
                    self?.showCreateTaskList(in: taskListSection)
                case .deleteSection(let taskListSection):
                    HomeSidebar.Track.deleteSection()
                    self?.showDeleteSectionDialog(section: taskListSection)
                }
            }
        }
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true, completion: nil)
    }

    private func showCreateTaskList(in section: Rust.TaskListSection?) {
        context.bus.post(.createTasklist(section: section, from: self, callback: { [weak self] str in
            self?.viewModel.doCreateTaskList(with: str, in: section, completion: { [weak self] res in
                guard let self = self else { return }
                switch res {
                case .success:
                    self.dismiss(animated: true)
                case .failure(let err):
                    Utils.Toast.showWarning(with: err.message, on: self.view)
                }
            })
        }, completion: nil))
    }

    private func showUpsertSectionDialog(section: Rust.TaskListSection?) {
        guard let section = section else { return }
        let input = viewModel.getCreateSectionInput(section.name.isEmpty ? nil : section.name)
        PaddingTextField.showTextField(with: input, from: self) { [weak self] textFieldText in
            var newSection = section
            newSection.name = textFieldText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self?.viewModel.upsertSection(newSection, completion: { [weak self] res in
                self?.handleUserRes(res)
            })
        }
    }

    private func showDeleteSectionDialog(section: Rust.TaskListSection) {
        let dialog = UDDialog(config: UDDialogUIConfig())
        dialog.setTitle(text: I18N.Todo_TaskListSection_Delete_Popup_Title)
        dialog.setContent(text: I18N.Todo_TaskList_DeleteSectionPopup_Title)
        dialog.addCancelButton()
        dialog.addDestructiveButton(text: I18N.Todo_common_Delete, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            var newSection = section
            newSection.deleteMilliTime = Int64((NSDate().timeIntervalSince1970 * 1_000))
            self.viewModel.upsertSection(newSection, completion: { [weak self] res in
                self?.handleUserRes(res)
            })
        })
        present(dialog, animated: true)
    }

    private func handleUserRes(_ res: UserResponse<String?>) {
        switch res {
        case .success(let toast):
            if let toast = toast {
                Utils.Toast.showSuccess(with: toast, on: view)
            }
        case .failure(let err):
            Utils.Toast.showWarning(with: err.message, on: view)
        }
    }
}

extension HomeSidebarViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView.cellForItem(at: indexPath) != nil else { return }
        viewModel.doSelectItem(at: indexPath) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}
