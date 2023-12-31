//
//  SceneListViewController.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/7.
//

import Foundation
import LarkCore // IMTracker
import LarkUIKit // BaseUIViewController
import UniverseDesignColor // UIColor.ud.
import RxSwift // DisposeBag
import ServerPB // ServerPB
import UniverseDesignActionPanel // UDActionSheet
import UniverseDesignToast // UDToast
import UniverseDesignDialog // UDDialog
import LarkSDKInterface // APIError

/// 我的场景页面：https://bytedance.feishu.cn/wiki/UcnQwNROJiOYlhkzN9pclEIknrc
final class SceneListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let viewModel: SceneListViewModel
    private lazy var tableView = SceneListTableView(frame: .zero, style: .plain)

    // MARK: - 生命周期
    init(viewModel: SceneListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloatBase & UIColor.ud.bgBase
        // 隐藏自带的导航栏
        self.isNavigationBarHidden = true
        // 配置下滑返回指示条
        self.setupTopLineView()
        // 配置导航头部视图
        SceneListNavigationBar(frame: .zero).addTo(viewController: self)
        // 配置表格视图
        self.tableView.addTo(viewController: self)
        // 配置创建场景按钮
        SceneListCreateSceneButton(frame: .zero).addTo(viewController: self)

        // 开始拉取首屏消息
        self.loadFirstPage()
        /// 监听信号
        self.observeViewModel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 退出页面时，内存缓存中存储一份首屏场景数据
        self.viewModel.saveSceneListToCache()
    }

    // MARK: - 私有方法
    /// 配置下滑返回指示条
    private func setupTopLineView() {
        let lineView = UIView()
        lineView.layer.masksToBounds = true
        lineView.layer.cornerRadius = 2
        lineView.backgroundColor = UIColor.ud.lineBorderCard
        self.view.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(4)
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.viewTopConstraint).offset(8)
        }
    }

    /// 添加或者删除上拉加载
    private func removeOrAddLoadMoreIfNeeded() {
        // 添加上拉加载；如果已经有则不再添加，否则会导致渲染到很下面
        if self.viewModel.hasMore, self.tableView.footer == nil {
            self.tableView.es.addInfiniteScrolling(animator: RefreshAnimationView()) { [weak self] in
                guard let `self` = self else { return }
                self.fetchSceneList(self.tableView, firstPage: false)
            }
        } else if !self.viewModel.hasMore {
            // 如果没有更多数据了，则移除上拉加载更多
            self.tableView.es.removeRefreshFooter()
            // 应该是个bug，contentInset没有恢复为0，导致底部有一段空白
            if self.tableView.contentInset.bottom != 0 { self.tableView.contentInset = .zero }
        }
    }

    /// 添加下拉刷新
    private func addPullToRefreshIfNeeded() {
        if self.tableView.header == nil {
            self.tableView.es.addPullToRefresh(animator: RefreshAnimationView()) { [weak self] in
                guard let `self` = self else { return }
                self.fetchSceneList(self.tableView, firstPage: true)
            }
        }
    }

    /// 监听信号
    private func observeViewModel() {
        // 监听编辑场景
        self.viewModel.sceneService?.editSceneSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] scene in
            guard let `self` = self else { return }
            // 如果删除，则从数据源删除
            if scene.status == .delete {
                self.viewModel.dataSource.removeAll(where: { $0.sceneID == scene.sceneID })
                // 如果数据为空，则展示空态图
                if self.viewModel.dataSource.isEmpty { self.tableView.emptyView.addTo(view: self.tableView) }
                self.tableView.reloadData()
                return
            }
            // 其他情况，更新对应数据源
            if let index = self.viewModel.dataSource.firstIndex(where: { $0.sceneID == scene.sceneID }) {
                self.viewModel.dataSource[index] = scene
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                return
            }
        }).disposed(by: self.viewModel.disposeBag)
        // 监听创建场景
        self.viewModel.sceneService?.createSceneSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] scene in
            guard let `self` = self else { return }
            // 如果数据源是空
            if self.viewModel.dataSource.isEmpty {
                // 删除空态图、错误图；处理数据由 无->有 的情况
                self.tableView.emptyView.removeFromSuperview()
                self.tableView.errorView.removeFromSuperview()
                // 直接添加数据
                self.viewModel.dataSource.append(scene)
                self.tableView.reloadData()
                return
            }
            // 把场景加到预制场景后面
            let index = self.viewModel.dataSource.firstIndex(where: { !$0.isPreset }) ?? self.viewModel.dataSource.count
            self.viewModel.dataSource.insert(scene, at: index)
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: false)
        }).disposed(by: self.viewModel.disposeBag)
    }

    /// 进群时，加载首屏数据
    private func loadFirstPage() {
        // 如果当前页面已经有缓存数据了，则直接触发下拉刷新即可
        if !self.viewModel.dataSource.isEmpty {
            self.addPullToRefreshIfNeeded()
            self.tableView.es.startPullToRefresh()
            return
        }
        // 如果当前页面没有数据，则全屏覆盖loading图
        self.tableView.loadingView.addTo(view: self.tableView)
        self.viewModel.fetchSceneList(firstPage: true) { [weak self] in
            guard let `self` = self else { return }
            // 埋点
            IMTracker.Scene.View.sceneList(self.viewModel.chat, sceneIds: self.viewModel.dataSource.map({ $0.sceneID }))
            self.didTrackSceneList = true
            // 删除loading
            self.tableView.loadingView.removeFromSuperview()
            self.tableView.reloadData()
            // 添加下拉刷新
            self.addPullToRefreshIfNeeded()
            // 如果数据为空，则展示空态图
            if self.viewModel.dataSource.isEmpty { self.tableView.emptyView.addTo(view: self.tableView) }
            // 添加上拉加载
            self.removeOrAddLoadMoreIfNeeded()
        } onError: { [weak self] _ in
            guard let `self` = self else { return }
            // 埋点
            IMTracker.Scene.View.sceneList(self.viewModel.chat, sceneIds: self.viewModel.dataSource.map({ $0.sceneID }))
            self.didTrackSceneList = true
            // 删除loading
            self.tableView.loadingView.removeFromSuperview()
            // 添加下拉刷新
            self.addPullToRefreshIfNeeded()
            // 添加错误图
            self.tableView.errorView.addTo(view: self.tableView)
        }
    }

    /// 进首屏后第一次拉取到数据时，需要上报埋点
    private var didTrackSceneList: Bool = false

    /// 触发下拉刷新、上拉加载，firstPage传true表示下拉刷新，否则表示上拉加载
    private func fetchSceneList(_ tableView: SceneListTableView, firstPage: Bool) {
        self.viewModel.fetchSceneList(firstPage: firstPage) { [weak self] in
            guard let `self` = self else { return }
            // 埋点
            if !self.didTrackSceneList, firstPage {
                IMTracker.Scene.View.sceneList(self.viewModel.chat, sceneIds: self.viewModel.dataSource.map({ $0.sceneID }))
                self.didTrackSceneList = true
            }
            // 删除空态图、错误图
            self.tableView.emptyView.removeFromSuperview()
            self.tableView.errorView.removeFromSuperview()
            self.tableView.reloadData()
            // 停止下拉刷新、上拉加载
            self.tableView.es.stopPullToRefresh()
            self.tableView.es.stopLoadingMore()
            // 如果数据是空，则展示空态图
            if self.viewModel.dataSource.isEmpty { self.tableView.emptyView.addTo(view: self.tableView) }
            // 添加上拉加载
            self.removeOrAddLoadMoreIfNeeded()
        } onError: { [weak self] error in
            guard let `self` = self else { return }
            // 埋点
            if !self.didTrackSceneList, firstPage {
                IMTracker.Scene.View.sceneList(self.viewModel.chat, sceneIds: self.viewModel.dataSource.map({ $0.sceneID }))
                self.didTrackSceneList = true
            }
            // 删除空态图、错误图
            self.tableView.emptyView.removeFromSuperview()
            self.tableView.errorView.removeFromSuperview()
            self.tableView.reloadData()
            // 停止下拉刷新、上拉加载
            self.tableView.es.stopPullToRefresh()
            self.tableView.es.stopLoadingMore()
            // 如果当前页面数据是空，则把空态图替换为错误图
            if self.viewModel.dataSource.isEmpty {
                self.tableView.errorView.addTo(view: self.tableView)
            } else {
                // 否则此时界面上有数据，则进行toast提示即可
                if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
                }
            }
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.row < self.viewModel.dataSource.count else { return }

        let scene = self.viewModel.dataSource[indexPath.row]
        // 删除场景，不进行任何操作
        if scene.status == .delete { return }
        // 禁用场景，则弹Toast提示
        if scene.status == .stop {
            UDToast.showTips(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_ScenarioDeactivatedCantSelect_Toast, on: self.view)
            return
        }

        IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "scene_chat_detail", "scene_chat_id": "[\(scene.sceneID)]"])
        self.viewModel.selected(scene.sceneID)
        self.dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 最后一行没有下padding 12
        return (self.viewModel.dataSource.count == indexPath.row + 1) ? 98 : 110
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.lu.dequeueReusableCell(withClass: SceneListTableViewCell.self, for: indexPath)
        tableViewCell.delegate = self
        if indexPath.row < self.viewModel.dataSource.count {
            tableViewCell.configScene(scene: self.viewModel.dataSource[indexPath.row])
        }
        return tableViewCell
    }
}

extension SceneListViewController: SceneListNavigationBarDelegate {
    func didClickExit(button: UIButton) {
        self.dismiss(animated: true)
    }
}

extension SceneListViewController: SceneListCellDelegate {
    func didClickMore(button: UIButton, scene: ServerPB_Office_ai_MyAIScene) {
        // 如果场景是删除状态，应该是出错了，此时需要把这个场景从列表中删除
        if scene.status == .delete {
            self.viewModel.sceneService?.editSceneSubject.onNext(scene)
            return
        }
        // 官方预制，不应该有more按钮
        if scene.isPreset {
            return
        }

        let config = UDActionSheetUIConfig(isShowTitle: false, popSource: UDActionSheetSource(sourceView: button, sourceRect: button.bounds, arrowDirection: .up))
        let actionsheet = UDActionSheet(config: config)
        // 如果我是场景的创建者
        if "\(scene.owner.id)" == (self.viewModel.userService?.user.userID ?? "") {
            // 场景启用
            if scene.status == .valid {
                self.addEditSheetItem(to: actionsheet, scene: scene)
                self.addShareSheetItem(to: actionsheet, scene: scene)
                self.addStopSheetItem(to: actionsheet, scene: scene)
            }
            // 场景停用
            else if scene.status == .stop {
                self.addActiveSheetItem(to: actionsheet, scene: scene)
                self.addRemoveSheetItem(to: actionsheet, scene: scene)
            }
        }
        // 如果是场景使用者
        else {
            // 场景启用
            if scene.status == .valid {
                self.addShareSheetItem(to: actionsheet, scene: scene)
                self.addRemoveSheetItem(to: actionsheet, scene: scene)
            }
            // 场景停用
            else if scene.status == .stop {
                self.addRemoveSheetItem(to: actionsheet, scene: scene)
            }
        }
        // 底部添加取消
        actionsheet.setCancelItem(text: BundleI18n.LarkAI.MyAI_Onboarding_EditAvatar_Cancel_Button)
        self.present(actionsheet, animated: true)
    }

    /// 添加编辑场景ActionItem
    private func addEditSheetItem(to actionSheet: UDActionSheet, scene: ServerPB_Office_ai_MyAIScene) {
        actionSheet.addDefaultItem(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Edit_Button) { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "edit_scene"])
            self.viewModel.sceneService?.openEditScene(from: self, chat: self.viewModel.chat, scene: scene)
            IMTracker.Scene.View.editScene(self.viewModel.chat, params: ["scene_chat_id": "[\(scene.sceneID)]"])
        }
    }

    /// 添加分享场景ActionItem
    private func addShareSheetItem(to actionSheet: UDActionSheet, scene: ServerPB_Office_ai_MyAIScene) {
        actionSheet.addDefaultItem(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Share_Button) { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "share_scene"])
            self.viewModel.shareScene(sceneId: scene.sceneID) { [weak self] in
                guard let `self` = self else { return }
                UDToast.showSuccess(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_LinkCopied_Toast, on: self.view)
            } onError: { [weak self] error in
                guard let `self` = self else { return }
                if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
                }
            }
        }
    }

    /// 添加停用场景ActionItem
    private func addStopSheetItem(to actionSheet: UDActionSheet, scene: ServerPB_Office_ai_MyAIScene) {
        actionSheet.addDestructiveItem(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Deactivate_Button) { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "stop_scene"])
            self.alertForStopScene(scene: scene)
        }
    }

    /// 添加启用场景ActionItem
    private func addActiveSheetItem(to actionSheet: UDActionSheet, scene: ServerPB_Office_ai_MyAIScene) {
        actionSheet.addDefaultItem(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Activate_Button) { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "start_scene"])
            self.viewModel.switchScene(sceneId: scene.sceneID, active: true) { [weak self] in
                guard let `self` = self else { return }
                UDToast.showTips(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Activated_Toast, on: self.view)
            } onError: { [weak self] error in
                guard let `self` = self else { return }
                if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
                }
            }
        }
    }

    /// 添加移除场景ActionItem
    private func addRemoveSheetItem(to actionSheet: UDActionSheet, scene: ServerPB_Office_ai_MyAIScene) {
        actionSheet.addDestructiveItem(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Remove_Button) { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "delete_scene"])
            self.alertForRemoveScene(scene: scene)
        }
    }

    /// 弹窗提示停用场景
    private func alertForStopScene(scene: ServerPB_Office_ai_MyAIScene) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Deactivate_Popup_Title(scene.sceneName))
        dialog.setContent(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Deactivate_Popup_Desc)
        dialog.addSecondaryButton(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Deactivate_Popup_Cancel_Button, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.confirm(self.viewModel.chat, params: ["view_type": "stop_scene", "click": "cancel"])
        })
        dialog.addDestructiveButton(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Deactivate_Popup_Suspend_Button, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.confirm(self.viewModel.chat, params: ["view_type": "stop_scene", "click": "confirm"])
            self.viewModel.switchScene(sceneId: scene.sceneID, active: false) { [weak self] in
                guard let `self` = self else { return }
                UDToast.showTips(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Deactivated_Toast, on: self.view)
            } onError: { [weak self] error in
                guard let `self` = self else { return }
                if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
                }
            }
        })
        self.present(dialog, animated: true)
        IMTracker.Scene.View.confirm(self.viewModel.chat, params: ["view_type": "stop_scene"])
    }

    /// 弹窗提示移除场景
    private func alertForRemoveScene(scene: ServerPB_Office_ai_MyAIScene) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Remove_Popup_Title(scene.sceneName))
        dialog.setContent(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Remove_Popup_Desc)
        dialog.addSecondaryButton(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Remove_Popup_Cancel_Button, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.confirm(self.viewModel.chat, params: ["view_type": "delete_scene", "click": "cancel"])
        })
        dialog.addDestructiveButton(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Remove_Popup_Remove_Button, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.confirm(self.viewModel.chat, params: ["view_type": "delete_scene", "click": "confirm"])
            self.viewModel.removeScene(sceneId: scene.sceneID) {} onError: { [weak self] error in
                guard let `self` = self else { return }
                if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: error)
                }
            }
        })
        self.present(dialog, animated: true)
        IMTracker.Scene.View.confirm(self.viewModel.chat, params: ["view_type": "delete_scene"])
    }
}

extension SceneListViewController: SceneListCreateButtonDelegate {
    func didClickCreate(button: UIButton) {
        self.viewModel.sceneService?.openCreateScene(from: self, chat: self.viewModel.chat)
        IMTracker.Scene.Click.sceneList(self.viewModel.chat, params: ["click": "new_create_scene"])
        IMTracker.Scene.View.newScene(self.viewModel.chat)
    }
}
