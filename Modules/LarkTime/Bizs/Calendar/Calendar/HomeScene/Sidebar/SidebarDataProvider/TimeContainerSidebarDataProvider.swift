//
//  TimeContainerSidebarDataProvider.swift
//  Calendar
//
//  Created by huoyunjie on 2023/11/11.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import UniverseDesignIcon
import LarkUIKit
import UniverseDesignActionPanel
import UniverseDesignToast

struct TimeContainerSidebarModelData: SidebarModelData {
    var id: String { model.serverID }
    
    var sectionType: CalendarListSection {
        let title = FG.optimizeCalendar ? I18n.Calendar_Manage_Managing : I18n.Calendar_Common_MyCalendars
        return .larkMine(CalendarListSectionContent(sourceTitle: title))
    }
    
    var colorIndex: ColorIndex {
        model.colorIndex
    }
    
    var isVisible: Bool {
        get {
            model.isVisible
        }
        set {
            model.isVisible = newValue
        }
        
    }
    
    var displayName: String { model.displayName }
    
    let weight: Int32 = 1000
    let source: SidebarDataSource = .timeContainer
    let accountValid: Bool = true
    let accountExpiring: Bool = true
    let isResign: Bool = false
    let isInactive: Bool = false
    let isNeedApproval: Bool = false
    let isExternal: Bool = false
    let trailBtnImg: UIImage? = FG.optimizeCalendar ? UDIcon.getIconByKeyNoLimitSize(.moreBoldOutlined) : UDIcon.getIconByKeyNoLimitSize(.settingOutlined)
    let isLoading: Bool = false
    
    private(set) var model: TimeContainerModel
    
    init(from model: TimeContainerModel) {
        self.model = model
    }
}

class TimeContainerSidebarDataProvider: UserResolverWrapper, SidebarDataProvider {
    @ScopedInjectedLazy var timeDataService: TimeDataService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var rustPushService: RustPushService?
    
    let userResolver: UserResolver
    
    let source: SidebarDataSource = .timeContainer
    
    var modelData: [SidebarModelData] {
        data
    }
    
    private let queue = DispatchQueue(label: "lark.calendar.timeContainerSidebarDataProvider", qos: .userInteractive)
    
    private var data: [TimeContainerSidebarModelData] {
        get {
            queue.sync { [weak self] in
                return self?._data ?? []
            }
        }
        set {
            queue.async(group: nil, qos: .default, flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self._data = newValue
            }
        }
    }
    
    private var _data: [TimeContainerSidebarModelData] = []
    
    let dataChanged: BehaviorRelay<Void> = .init(value: ())
    
    private let disposeBag = DisposeBag()
    
    let rxRouter: PublishRelay<Route> = .init()
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.bindRxRoute()
        self.refreshData()
        self.fetchData()
        self.registerPushReceiver()
    }
    
    func updateVisibility(with uniqueId: String, from: UIViewController) {
        updateTimeContainerVisibility(with: uniqueId, from: from)
    }
    
    func clickTrailView(with uniqueId: String, from: UIViewController, _ popAnchor: UIView) {
        if FG.optimizeCalendar {
            enterMore(uniqueId: uniqueId, from: from, popAnchor)
        } else {
            enterSetting(uniqueId: uniqueId, from: from, popAnchor)
        }
    }
    
    func clickFooterView(with uniqueId: String, from: UIViewController) {}
    
    /// 触发 TimeDataService 的数据同步
    func fetchData() {
        guard let timeDataService = timeDataService else { return }
        let _ = timeDataService.fetchTimeContainers()
    }
    
    /// 刷新 data 信息，覆盖最新的 TimeDataService 数据
    func refreshData() {
        guard let timeDataService = timeDataService else { return }
        self.data = timeDataService.getTimeContainers()
            .map({ model in
                TimeContainerSidebarModelData(from: model)
            })
        self.dataChanged.accept(())
    }
    
    /// 监听 TimeDataService 的时间容器变更信号，收到信号进行数据刷新
    private func registerPushReceiver() {
        timeDataService?.timeContainerChanged
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refreshData()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - API
extension TimeContainerSidebarDataProvider {
    /// 更改容器可见性
    private func updateTimeContainerVisibility(with uniqueId: String, from: UIViewController) {
        guard let index = data.firstIndex(where: { $0.uniqueId == uniqueId })  else {
            return
        }
        guard var model = data[safeIndex: index] else {
            return
        }
       
        let preVisible = model.isVisible
               
        timeDataService?.updateTimeContainerInfo(id: model.id, isVisibile: !preVisible, colorIndex: nil)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onError: { [weak self] error in
                if error.errorType() == .exceedMaxVisibleCalNum {
                    UDToast.showFailure(with: I18n.Calendar_Detail_TooMuchViewReduce, on: from.currentWindow() ?? from.view)
                }
                CalendarList.logError("update time container \(model.id) isVisible to \(!preVisible) error!!!")
                /// 变更失败，重新刷新视图
                self?.dataChanged.accept(())
            }).disposed(by: disposeBag)
    }
    
    /// 更新容器颜色
    @discardableResult
    private func updateTimeContainerColor(with id: String, color: Int, from: UIViewController? = nil) -> Observable<Void> {
        guard let service = timeDataService, let colorIndex = ColorIndex(rawValue: color) else {
            return .empty()
        }
        // 颜色变态变更成功后，通过 timeDataService 发送信号的方式触发列表数据刷新
        from?.change(toastStatus: .loading(info: I18n.Calendar_Share_Modifying, disableUserInteraction: false, fromWindow: true))
        let observable = service.updateTimeContainerInfo(id: id, isVisibile: nil, colorIndex: colorIndex).share()
        observable
            .subscribeForUI(onNext: { _ in
                from?.change(toastStatus: .remove)
                from?.change(toastStatus: .success(I18n.Calendar_Share_Modified, fromWindow: true))
                CalendarList.logInfo("update time container color success")
            }, onError: { e in
                from?.change(toastStatus: .failure(I18n.Calendar_Bot_SomethingWrongToast, fromWindow: true))
                CalendarList.logInfo("update time container color error \(e)")
            })
            .disposed(by: disposeBag)
        return observable.map { _ in }
        
    }
    
    /// 仅勾选此时间容器
    private func specifyVisibleOnlyTimeContainer(with id: String) {
        guard let service = timeDataService else { return }
        // 通过 timeDataService 发送信号的方式触发列表数据刷新
        service.specifyVisibleOnlyTimeContainer(with: id)
            .subscribe(onNext: { _ in
                CalendarList.logInfo("specify visible this time container success")
            }, onError: { e in
                CalendarList.logInfo("specify visible this time container error \(e)")
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - View Action
extension TimeContainerSidebarDataProvider {
    /// 进入 more 页面
    func enterMore(uniqueId: String, from: UIViewController, _ popAnchor: UIView) {
        guard let data = self.data.first(where: { $0.uniqueId == uniqueId }) else {
            return
        }
        let showThisOnly: ActionSheetAction = { [weak self] in
            self?.specifyVisibleOnlyTimeContainer(with: data.id)
        }
        
        let changeColor: ActionSheetAction = { [weak self] in
            guard let self = self else { return }
            let index = data.colorIndex.rawValue
            let pickerVC = ColorEditActionPanel(selectedIndex: index)
            pickerVC.colorSelectedHandler = { [weak self, weak pickerVC] newIndex in
                guard let self = self, let pickerVC = pickerVC else { return }
                pickerVC.dismiss(animated: true)
                if index != newIndex {
                    self.updateTimeContainerColor(with: data.id, color: newIndex, from: from)
                }
            }
            self.rxRouter.accept(.actionPanel(pickerVC, popAnchor: popAnchor, from: from))
        }
        
        let popSource = UDActionSheetSource(sourceView: popAnchor,
                                            sourceRect: popAnchor.bounds,
                                            arrowDirection: .right)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: popSource))
        actionSheet.addItem(.init(title: I18n.Calendar_G_ShowThisCalendarOnly_Click, action: showThisOnly))
        actionSheet.addItem(.init(title: I18n.Calendar_G_ChangeColor_Click, action: changeColor))
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
        self.rxRouter.accept(.actionSheet(actionSheet, from: from))
    }
    
    /// 进入设置页
    func enterSetting(uniqueId: String, from: UIViewController, _ popAnchor: UIView) {
        guard let data = self.data.first(where: { $0.uniqueId == uniqueId }) else {
            return
        }
        let vc = TimeContainerManagerViewController(container: data.model)
        vc.delegate = self
        let nav = LkNavigationController(rootViewController: vc)
        nav.update(style: .default)
        nav.modalPresentationStyle = .fullScreen
        if Display.pad {
            vc.modalPresentationStyle = .formSheet
        }
        from.present(nav, animated: true, completion: nil)
    }
}

// MARK: - Route
extension TimeContainerSidebarDataProvider {
    typealias ActionSheetAction = () -> Void
    
    enum Route {
        // 弹出actionSheet
        case actionSheet(_ targetVC: UIViewController, from: UIViewController)
        // 弹出 actionPanel
        case actionPanel(_ targetVC: UIViewController, popAnchor: UIView?, from: UIViewController)
    }
    
    func bindRxRoute() {
        self.rxRouter
            .subscribeForUI(onNext: { route in
                switch route {
                case .actionSheet(let vc, let from):
                    from.present(vc, animated: true, completion: nil)
                case .actionPanel(let vc, let anchor, let from):
                    if let anchor = anchor, Display.pad {
                        vc.preferredContentSize = .init(width: 375, height: 128)
                        vc.modalPresentationStyle = .popover
                        vc.popoverPresentationController?.sourceView = anchor
                        vc.popoverPresentationController?.permittedArrowDirections = [.right]
                        vc.popoverPresentationController?.delegate = from as? UIPopoverPresentationControllerDelegate
                        from.present(vc, animated: true)
                    } else {
                        // header + margin(16+8) + panelHeight(12*2+48*3+8*2)
                        let panelHeight = 48 + 24 + 184 + from.view.safeAreaInsets.bottom
                        let actionPanel = UDActionPanel(
                            customViewController: vc,
                            config: UDActionPanelUIConfig(
                                originY: Display.height - panelHeight,
                                canBeDragged: false,
                                backgroundColor: UIColor.ud.bgFloatBase
                            )
                        )
                        from.present(actionPanel, animated: true, completion: nil)
                    }
                }
            }).disposed(by: disposeBag)
    }
}

extension TimeContainerSidebarDataProvider: TimeContainerManagerViewControllerDelegate {
    
    func onCancel(_ vc: TimeContainerManagerViewController) {
        if vc.originalContainer == vc.currentContainer {
            vc.presentingViewController?.dismiss(animated: true)
        } else {
            EventAlert.showDismissModifiedCalendarAlert(controller: vc, confirmAction: {
                vc.presentingViewController?.dismiss(animated: true)
            })
        }
    }
    
    func onSave(_ vc: TimeContainerManagerViewController) {
        guard vc.originalContainer.colorIndex != vc.currentContainer.colorIndex else {
            vc.presentingViewController?.dismiss(animated: true)
            return
        }
        let colorIndex = vc.currentContainer.colorIndex
        updateTimeContainerColor(with: vc.currentContainer.serverID, color: colorIndex.rawValue, from: vc)
            .subscribeForUI(onNext: { _ in
                vc.presentingViewController?.dismiss(animated: true)
            }).disposed(by: disposeBag)
        
    }
}

fileprivate func == (lhs: TimeContainerModel, rhs: TimeContainerModel) -> Bool {
    return lhs.colorIndex == rhs.colorIndex
}
