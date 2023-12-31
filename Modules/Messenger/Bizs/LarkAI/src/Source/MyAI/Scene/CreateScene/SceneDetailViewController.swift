//
//  SceneDetailView.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/8.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import FigmaKit
import LarkContainer
import ServerPB
import RxSwift
import UniverseDesignDialog

protocol BaseSceneDetailViewCell: UITableViewCell {
    var param: SceneDetailParamType { get }
}

public class SceneDetailViewController: UIViewController {
    private let viewModel: SceneDetailViewModel

    public init(viewModel: SceneDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 13, *) {
            self.isModalInPresentation = true
        }
    }

    private var containerView = UIView()
    internal lazy var sceneDetailView: UITableView = {
        let tableView = InsetTableView()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var loadingView = SceneListLoadingView()
    private lazy var errorView = SceneListErrorView()

    private lazy var customNavigationBar = SceneDetailNavBar(title: viewModel.navTitle,
                                                             confirmText: viewModel.confirmTitle,
                                                             confirmAction: { [weak self] in
                                                                guard let self = self else { return }
                                                                self.viewModel.sendRequest(from: self)
                                                             },
                                                             cancelAction: {[weak self] in
                                                                self?.dismissBeforeConfirm()
                                                             })

    private var vcState: SceneDetailViewModel.State? = .none

    private func dismissBeforeConfirm() {
        if self.vcState != .success {
            self.dismiss()
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkAI.MyAI_Scenario_EditsNotSaved_Popoup_Title)
        dialog.addSecondaryButton(text: BundleI18n.LarkAI.MyAI_Scenario_EditsNotSaved_Popoup_NotNow_Button)
        dialog.addPrimaryButton(text: BundleI18n.LarkAI.MyAI_Scenario_EditsNotSaved_Popoup_Exit_Button, dismissCompletion: { [weak self] in
            self?.dismiss()
        })
        self.present(dialog, animated: true)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgFloatBase
        view.addSubview(customNavigationBar)
        customNavigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(60)
            make.left.right.equalToSuperview()
        }
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        registerCells()
        self.viewModel.listApi = self
        updateState()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc
    private func tapHandler(_ gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    var targetkeyboardHeight: CGFloat = 0
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[Self.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let duration = notification.userInfo?[Self.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            let originBottom = self.view.safeAreaLayoutGuide.layoutFrame.maxY + self.additionalSafeAreaInsets.bottom + 20
            let keyboardFrame = self.view.convert(keyboardFrame, from: nil)
            self.additionalSafeAreaInsets.bottom = max(originBottom - keyboardFrame.minY, 0)
            self.view.layoutIfNeeded()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/* extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        for subview in subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        return nil
    }
} */

extension SceneDetailViewController: UITableViewDataSource, SceneDetailCellReusable {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section <= viewModel.dataSource.sections.count else { return 0 }
        return viewModel.dataSource.sections[section].cellVMs.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section <= viewModel.dataSource.sections.count,
              indexPath.row <= viewModel.dataSource.sections[indexPath.section].cellVMs.count else { return UITableViewCell() }
        let cellVM = viewModel.dataSource.sections[indexPath.section].cellVMs[indexPath.row]
        return Self.getCell(tableView, cellVM: cellVM)
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section <= viewModel.dataSource.sections.count else { return .leastNonzeroMagnitude }
        guard viewModel.dataSource.sections[section].title != nil else {
            if section > 0, !viewModel.dataSource.sections[section - 1].cellVMs.isEmpty {
                return 12
            } else {
                return .leastNonzeroMagnitude
            }
        }
        return 45
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0001
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section <= viewModel.dataSource.sections.count else { return nil }
        guard let title = viewModel.dataSource.sections[section].title else { return nil }
        let isRequired = viewModel.dataSource.sections[section].isRequired
        let headerView = SceneDetailScetionHeader()
        headerView.setHeader(text: title, isRequired: isRequired)
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width - 8, height: 20)
        return headerView
    }
}

extension SceneDetailViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section <= viewModel.dataSource.sections.count,
              indexPath.row <= viewModel.dataSource.sections[indexPath.section].cellVMs.count else { return 0 }
        return viewModel.dataSource.sections[indexPath.section].cellVMs[indexPath.row].rowHeight
    }
}

extension SceneDetailViewController: SceneDetailListApi {
    var userResolver: UserResolver { self.viewModel.userResolver }
    var _tableView: UITableView { self.sceneDetailView }

    func dismiss() {
        self.dismiss(animated: true)
    }
    func removeCell(cellVM: SceneDetailCellViewModel) {
        guard let indexPath = viewModel.removeCellVM(cellVM: cellVM) else { return }
        sceneDetailView.deleteRows(at: [indexPath], with: .automatic)
    }
    func reloadCell(cellVM: SceneDetailCellViewModel) {
        guard let indexPath = viewModel.getIndexPath(cellVM: cellVM) else { return }
        sceneDetailView.reloadRows(at: [indexPath], with: .none)
    }
    func reloadTable() {
        sceneDetailView.reloadData()
    }
    func addCellIn(section: Int, cellVM: any SceneDetailCellViewModel) {
        guard section <= viewModel.dataSource.sections.count else { return }
        viewModel.dataSource.sections[section].cellVMs.append(cellVM)
    }

    func updateState() {
        guard vcState != viewModel.state else { return }
        DispatchQueue.main.async { [weak self] in
            self?.containerView.subviews.forEach { $0.removeFromSuperview() }
        }
        self.vcState = viewModel.state
        switch viewModel.state {
        case .blank:
            break
        case .success:
            DispatchQueue.main.async { [weak self] in
                self?.showSceneDetailView()
                self?.sceneDetailView.reloadData()
            }
        case .failed:
            DispatchQueue.main.async { [weak self] in
                self?.showErrorView()
            }
        case .loading:
            DispatchQueue.main.async { [weak self] in
                self?.showLoadingView()
            }
        }
    }

    func scrollToCellAtTop(indexPath: IndexPath, endAction: (() -> Void)?) {
        let cellRect = sceneDetailView.rectForRow(at: indexPath)
        let tableViewHeight = sceneDetailView.bounds.height

        if cellRect.minY < sceneDetailView.contentOffset.y || cellRect.maxY > sceneDetailView.contentOffset.y + tableViewHeight {
            let maxOffsetY = sceneDetailView.contentSize.height - tableViewHeight + sceneDetailView.contentInset.bottom
            let offsetY = min(cellRect.minY - sceneDetailView.contentInset.top, maxOffsetY)
            UIView.animate(withDuration: 0.15, animations: {
                self.sceneDetailView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
            }, completion: { isFinished in
                if isFinished {
                    endAction?()
                }
            })
        } else {
            endAction?()
        }
    }

    private func showLoadingView() {
        containerView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func showErrorView() {
        containerView.addSubview(errorView)
        errorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func showSceneDetailView() {
        containerView.addSubview(sceneDetailView)
        sceneDetailView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
