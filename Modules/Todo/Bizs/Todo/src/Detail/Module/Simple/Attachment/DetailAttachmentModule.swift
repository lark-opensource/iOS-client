//
//  DetailAttachmentModule.swift
//  Todo
//
//  Created by baiyantao on 2022/12/21.
//

import Foundation
import LarkContainer
import TodoInterface
import RxSwift
import RxCocoa
import UniverseDesignDialog

// nolint: magic number
final class DetailAttachmentModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailAttachmentViewModel

    @ScopedInjectedLazy private var driveDependency: DriveDependency?
    @ScopedInjectedLazy private var attachmentService: AttachmentService?
    private let disposeBag = DisposeBag()

    private lazy var rootView = initRootView()
    private var contentView: DetailAttachmentContentView { rootView.contentView }
    private var emptyView: DetailEmptyView { rootView.emptyView }
    private var tableView: UITableView { rootView.contentView.tableView }
    private var headerView: DetailAttachmentHeaderView { rootView.contentView.headerView }
    private var footerView: DetailAttachmentFooterView { rootView.contentView.footerView }

    private var needScrollToBottom = false
    // 用于附件，某些正在本地处理中的任务，比如选择一个很大的图片作为附件
    private var processingFileIds = Set<String>()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.setup()
        bindViewData()
        bindViewAction()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func initRootView() -> DetailAttachmentView {
        let view = DetailAttachmentView()
        view.contentView.actionDelegate = self
        return view
    }
}

// MARK: - View Data

extension DetailAttachmentModule {
    private func bindViewData() {
        viewModel.rxViewState.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                self.rootView.isHidden = false
                switch state {
                case .empty:
                    self.rootView.iconAlignment = .centerVertically
                    self.rootView.content = .customView(self.emptyView)
                case .content:
                    self.rootView.iconAlignment = .topByOffset(16)
                    self.rootView.content = .customView(self.contentView)
                case .hidden:
                    self.rootView.isHidden = true
                }
            })
            .disposed(by: disposeBag)
        viewModel.rxHeaderData.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.rootView.contentView.headerData = data
            })
            .disposed(by: disposeBag)
        viewModel.rxFooterData.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.rootView.contentView.footerData = data
            })
            .disposed(by: disposeBag)
        viewModel.reloadNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.rootView.contentView.cellDatas = self.viewModel.cellDatas
                if self.needScrollToBottom {
                    self.needScrollToBottom = false
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, let superView = self.tableView.superview,
                              let containerTableView = self.context.tableView else {
                            return
                        }
                        let frame = containerTableView.convert(self.tableView.frame, from: superView)
                        let bottomFrame = CGRect(x: frame.minX, y: frame.maxY - 1, width: frame.width, height: 1)
                        containerTableView.scrollRectToVisible(bottomFrame, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
        viewModel.rxContentHeight
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] height in
                guard let self = self else { return }
                self.rootView.contentHeight = height
                self.rootView.invalidateIntrinsicContentSize()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - View Action

extension DetailAttachmentModule {
    private func bindViewAction() {
        emptyView.onTapHandler = { [weak self] in
            guard let self = self else { return }
            guard self.viewModel.hasEditPermission() else {
                self.showNoEditPermissionToast()
                return
            }
            self.doAddAttachment(sourceView: self.emptyView.titleLabel)
        }
        footerView.addAttachmentClickHandler = { [weak self] (sourceView) in
            guard let self = self else { return }
            guard self.viewModel.hasEditPermission() else {
                self.showNoEditPermissionToast()
                return
            }
            self.doAddAttachment(sourceView: sourceView)
        }
        footerView.expandMoreClickHandler = { [weak self] in
            self?.viewModel.doExpandMore()
        }
    }

    private func showNoEditPermissionToast() {
        if let window = self.view.window {
            Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
        }
    }

    private func doAddAttachment(sourceView: UIView) {
        guard let vc = context.viewController as? BaseViewController else { return }
        let remainingCount = viewModel.getRemainingCount() - processingFileIds.count
        DetailAttachment.logger.info("task select. rc: \(remainingCount), sc: \(processingFileIds.count)")
        if remainingCount <= 0 {
            if let window = context.viewController?.view.window {
                Utils.Toast.showWarning(
                    with: I18N.Todo_Task_FileExceeds100NumberToast(DetailAttachment.TaskLimit),
                    on: window
                )
            }
        } else {
            let callbacks = SelectLocalFilesCallbacks(
                selectCallback: { [weak self] ids in
                    guard let self = self else { return }
                    DetailAttachment.logger.info("task select. select ids: \(ids)")
                    self.processingFileIds = self.processingFileIds.union(ids)
                },
                finishCallback: { [weak self] tuples in
                    guard let self = self else { return }
                    let ids = tuples.map { $0.0 }
                    DetailAttachment.logger.info("task select. finish ids: \(ids)")
                    self.processingFileIds = self.processingFileIds.subtracting(ids)
                    self.viewModel.doSelectedFiles(tuples.compactMap { $0.1 })
                    self.needScrollToBottom = true
                },
                cancelCallback: nil
            )
            attachmentService?.selectLocalFiles(
                vc: vc,
                sourceView: sourceView,
                sourceRect: CGRect(x: sourceView.frame.width / 2, y: sourceView.frame.height / 2, width: 0, height: 0),
                enableCount: remainingCount,
                callbacks: callbacks
            )
        }
    }
}

// MARK: - Cell Action

extension DetailAttachmentModule: DetailAttachmentContentCellDelegate {
    func onClick(_ cell: DetailAttachmentContentCell) {
        guard let vc = context.viewController,
              let fileToken = cell.viewData?.fileToken,
              !fileToken.isEmpty else {
            return
        }
        // 和 Drive 同学沟通，预览界面的手势和创建页的 present 手势会有冲突
        // 因此参考日历的实现，在创建页使用全屏 present 的方式来预览
        if context.scene.isForCreating {
            driveDependency?.previewFileInPresent(from: vc, fileToken: fileToken)
        } else {
            driveDependency?.previewFile(from: vc, fileToken: fileToken)
        }
    }

    func onRetryBtnClick(_ cell: DetailAttachmentContentCell) {
        guard case .attachmentService(let info) = cell.viewData?.source,
              let uploadKey = info.uploadInfo.uploadKey else {
            return
        }
        attachmentService?.resumeUpload(scene: viewModel.attachmentScene, key: uploadKey)
    }

    func onDeleteBtnClick(_ cell: DetailAttachmentContentCell) {
        guard let data = cell.viewData, let vc = context.viewController else { return }
        if context.scene.isForEditing {
            let dialog = UDDialog()
            dialog.setContent(text: I18N.Todo_RemoveAttachmentConfirmation_Title(data.nameText ?? ""))
            dialog.addCancelButton()
            dialog.addDestructiveButton(text: I18N.Todo_RemoveAttachmentConfirmation_Remove_Button) { [weak self] in
                self?.viewModel.doDelete(with: data)
            }
            vc.present(dialog, animated: true)
        } else {
            viewModel.doDelete(with: data)
        }
    }
}
