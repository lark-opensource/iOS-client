//
//  EventDetailTableMeetingNotesComponent.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/31.
//

import UIKit
import LarkContainer
import LarkFoundation
import LarkUIKit
import EENavigator
import CalendarFoundation
import UniverseDesignToast
import RxSwift
import LarkModel
import UniverseDesignActionPanel

final class EventDetailTableMeetingNotesComponent: UserContainerComponent {
    static let contentInset: UIEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 0)
    let viewModel: EventDetailTableMeetingNotesViewModel

    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy
    var calendarDependency: CalendarDependency?

    init(viewModel: EventDetailTableMeetingNotesViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(meetingNotesView)
        meetingNotesView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.trailing.equalToSuperview().inset(40 - 16)
        }

        meetingNotesView.meetingNotesView.meetingNotesCreateView.snp.makeConstraints {
            $0.trailing.equalTo(self.view).offset(-9)
        }

        bindViewModel()
    }

    private func bindViewModel() {
        meetingNotesView.viewData = viewModel.viewData.value
        viewModel.viewData
            .subscribeForUI(onNext: { [weak self] viewData in
                if case .hidden = viewData.viewStatus {
                    self?.view.isHidden = true
                } else {
                    self?.view.isHidden = false
                }
                self?.meetingNotesView.viewData = viewData
            }).disposed(by: disposeBag)
    }

    private lazy var meetingNotesView: EventDetailTableMeetingNotesView = {
        let view = EventDetailTableMeetingNotesView(
            userResolver: self.userResolver,
            bgColor: .clear,
            needGuideView: false,
            createViewType: .label
        )
        view.delegate = self
        view.iconSize = EventBasicCellLikeView.Style.iconSize
        view.contentInset = Self.contentInset
        return view
    }()
}

// View Action
extension EventDetailTableMeetingNotesComponent {
    /// 展示 Doc
    private func showDocComponent(url: URL, handlePushCompletion: ((UIViewController) -> Void)? = nil) {
        viewModel.loader.showDocComponent(from: viewController,
                                          url: url,
                                          delegate: self,
                                          handleShowCompletion: handlePushCompletion)
    }

    private func showFailureToast(_ message: String) {
        guard let viewController = self.viewController else { return }
        if Thread.isMainThread {
            UDToast.showFailure(with: message, on: viewController.view)
        } else {
            DispatchQueue.main.async {
                UDToast.showFailure(with: message, on: viewController.view)
            }
        }
    }

    private func showTips(_ message: String) {
        assert(Thread.current == Thread.main)
        guard let viewController = self.viewController else { return }
        UDToast.showTips(with: message, on: viewController.view)
    }

}

extension EventDetailTableMeetingNotesComponent: MeetingNotesViewDelegate {

    /// 创建水平模版列表view，详情页没有
    func createTemplateHorizontalListView(_ view: MeetingNotesView) -> CalendarTemplateHorizontalListViewProtocol? {
        return nil
    }

    /// 设置日程参与人文档权限
    func showPermissionSelectView(_ view: MeetingNotesPermissionView, onCompleted: @escaping ((CalendarNotesEventPermission) -> Void)) {
        guard let currentNotes = viewModel.currentNotes,
              let viewController = viewController else { return }

        let originalPermission = currentNotes.eventPermission
        let changeNotesEventPermission: (CalendarNotesEventPermission) -> Void = { [weak self] permission in
            guard let self = self, permission != originalPermission else {
                onCompleted(permission)
                return
            }
            UDToast.showLoading(with: I18n.Calendar_G_UpdatingChange_Toast, on: viewController.view)
            self.viewModel.changeNotesEventPermission(permission)
                .subscribeForUI(onNext: { _ in
                    onCompleted(permission)
                    let successText: [CalendarNotesEventPermission: String] = [
                        .canEdit: I18n.Calendar_G_NowCanEdit_Toast,
                        .canView: I18n.Calendar_G_NowCanView_Toast
                    ]

                    UDToast.showSuccess(with: successText[permission] ?? "", on: viewController.view)
                }, onError: { _ in
                    onCompleted(originalPermission)
                    UDToast.showFailure(with: I18n.Calendar_G_FailedUpdateChange_Toast, on: viewController.view)
                }).disposed(by: self.disposeBag)
        }

        let source = UDActionSheetSource(sourceView: view,
                                         sourceRect: view.bounds,
                                         arrowDirection: .up)
        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                popSource: source,
                dismissedByTapOutside: { onCompleted(originalPermission) }
            )
        )

        actionSheet.addDefaultItem(text: CalendarNotesEventPermission.canEdit.desc) {
            changeNotesEventPermission(.canEdit)
        }
        actionSheet.addDefaultItem(text: CalendarNotesEventPermission.canView.desc) {
            changeNotesEventPermission(.canView)
        }
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel) {
            onCompleted(originalPermission)
        }

        viewController.present(actionSheet, animated: true, completion: nil)
    }

    /// 通过 AI 创建 Doc
    func onCreateAIDoc(_ view: MeetingNotesView) {
        createMeetingNotes(withAI: true)
    }

    /// 进入 Permission 控制页面
    func onClickPermissionButton(_ view: MeetingNotesView) {
        guard let viewController = self.viewController,
              let url = viewModel.currentNotes?.url else { return }
        calendarDependency?.showDocAdjustExternalPanel(from: viewController, url: url) { [weak self] result in
            switch result {
            case .success: self?.viewModel.refreshMeetingNotes()
            case .failure: break
            }
        }
    }

    /// 点击重试 Label
    func onClickRetryButton(_ view: MeetingNotesView) {
        guard case let .failed(retryAction) = view.viewData else { return }
        retryAction()
    }

    /// 进入 DocComponent
    func onEnterDocComponent(_ view: MeetingNotesView) {
        guard let urlStr = viewModel.currentNotes?.url,
              let url = URL(string: urlStr) else { return }
        showDocComponent(url: url)
        let uid = viewModel.model.key
        CalendarTracerV2.EventDetail.traceClick(commonParam: commonParamData) {
            $0.click("meeting_notes")
            $0.uid = uid
        }
    }

    /// 创建 Doc
    func onCreateEmptyDoc(_ view: MeetingNotesView) {
        createMeetingNotes(withAI: false)
    }

    /// 不可用状态下点击操作
    func onDisableStatus(_ view: MeetingNotesView) {
        guard case .disabled(_, _, let reason) = view.viewData,
              let reason = reason else {
            return
        }
        self.showTips(reason)
    }

    /// 根据模版创建 Doc
    func templateOnItemSelected(_ viewController: UIViewController, item: CalendarTemplateItem) {
    }

    /// 点击模板回调
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, didClick templateId: String) -> Bool {
        return false
    }

    /// 创建文档回调
    /// - Parameters:
    ///   - result: 创建后的文档结果
    ///   - error: 错误信息
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onCreateDoc result: CalendarDocsTemplateCreateResult?, error: Error?) {
    }

    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onFailedStatus: Bool) {}

    /// 进入关联文档页面
    func onAssociateDoc(_ view: MeetingNotesView) {
        guard let viewController = self.viewController else { return }
        guard canCreateNotes() else {
            self.showTips(I18n.Calendar_G_OrgnizerForbidThis_Tooltip)
            return
        }
        if let vc = calendarDependency?.createAssociateDocPickController(pickerDelegate: self) {
            viewController.navigationController?.present(vc, animated: true)
        }
    }
}

extension EventDetailTableMeetingNotesComponent {

    func canCreateNotes() -> Bool {
        guard let event = viewModel.model.event,
              viewModel.loader.canCreateNotes(with: event) else { return false }
        return true
    }

    /// 创建文档
    private func createMeetingNotes(withAI: Bool) {
        assert(Thread.current == Thread.main)
        guard let viewController = self.viewController else { return }
        guard canCreateNotes() else {
            self.showTips(I18n.Calendar_G_OrgnizerForbidThis_Tooltip)
            return
        }
        /// 创建文档
        let toast = UDToast.showLoading(with: I18n.Calendar_Notes_CreatingDotDot, on: viewController.view)
        let onSuccess: (MeetingNotesModel, Bool) -> Void = {
            [weak self] (notes, isNewCreate) in
            toast.remove()
            if var url = URL(string: notes.url) {
                if isNewCreate, withAI {
                    /// 创建文档后，若启用AI，打开文档侧提供showAI=true后缀
                    let params: [String: String] = [
                        "showAI": "true"
                    ]
                    url = url.append(parameters: params)
                }
                self?.showDocComponent(url: url) { vc in
                    if !isNewCreate {
                        UDToast.showTips(with: I18n.Calendar_G_Notes_CreatedAlreadyOpenNow_Toast, on: vc.view)
                    }
                }
            }
        }
        let onError: (Error?) -> Void = { [weak self] error in
            let toastStr = I18n.Calendar_Notes_NoCreateTryLater
            if error?.errorType() == .createOrBindNotesAccessForbiddenErr {
                self?.showTips(I18n.Calendar_G_OrgnizerForbidThis_Tooltip)
                return
            }
            self?.showFailureToast(error?.getTitle(errorScene: .meetingNotes) ?? toastStr)
        }
        viewModel.createMeetingNotes()
            .subscribeForUI(onNext: { (notes, isNewCreate) in
                if let notes = notes {
                    onSuccess(notes, isNewCreate)
                }else {
                    onError(nil)
                }
            }, onError: { error in
               onError(error)
            }).disposed(by: disposeBag)

        let uid = viewModel.model.key
        CalendarTracerV2.EventDetail.traceClick(commonParam: commonParamData) {
            $0.click("create_meeting_notes")
            $0.uid = uid
        }
    }
}

extension EventDetailTableMeetingNotesComponent: CalendarDocComponentAPIDelegate {

    /// 文档即将关闭回调
    func willClose() {
        /// 销毁 docComponent
        self.viewModel.loader.docComponent = nil
        self.viewModel.refreshMeetingNotes()
    }

    func getSubScene() -> String {
        "calendar_detail"
    }

    func onInvoke(data: [String: Any]?, callback: CalendarDocComponentInvokeCallBack?) {
        guard let event = viewModel.model.event,
              let data = data,
              let command = data["command"] as? String,
              command == "GET_AI_INFO" else {
            return
        }
        let payload = [
            "params": [
                "content": event.summary,
                "promptId": viewModel.loader.aiConfig?["calendar_prompt_id"]
            ],
            "bizExtraData": [
                "event_duration": ((event.endTime - event.startTime) / 60).description,
                "attendee_num": event.attendeeInfo.totalNo.description,
                "source": "calendar",
                "event_calendar_id": event.calendarID,
                "event_original_time": event.originalTime.description,
                "event_uid": event.key,
                "instance_start_time": event.startTime.description,
            ]
        ]
        callback?(payload, nil)
    }

}

/// 埋点
extension EventDetailTableMeetingNotesComponent {
    var commonParamData: CommonParamData {
        .init(instance: viewModel.model.instance, event: viewModel.model.event)
    }
}


// MARK: Picker
extension EventDetailTableMeetingNotesComponent: SearchPickerDelegate {

    private func associateNotesInfo(docToken: String, docType: Int) {
        assert(Thread.current == Thread.main)

        let toast = UDToast.showLoading(with: I18n.Calendar_G_LoadingDocs_Desc, on: viewController.view)
        let onError: (Error?) -> Void = { [weak self] error in
            let toastStr = I18n.Calendar_G_CantLinkTryAgain_Toast
            if error?.errorType() == .createOrBindNotesAccessForbiddenErr {
                self?.showTips(I18n.Calendar_G_OrgnizerForbidThis_Tooltip)
                return
            }
            self?.showFailureToast(error?.getTitle(errorScene: .meetingNotes) ?? toastStr)
        }
        self.viewModel.associateNotesInfo(docToken: docToken, docType: docType)
            .subscribeForUI(onNext: { notes in
                toast.remove()
                if notes == nil {
                    onError(nil)
                }
            }, onError: { error in
                onError(error)
            }).disposed(by: disposeBag)
    }

    func pickerDidSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) {
        switch item.meta {
        case .doc(let docMeta):
            if let meta = docMeta.meta {
                self.associateNotesInfo(docToken: meta.id, docType: meta.type.rawValue)
            } else {
                EventEdit.logger.error("select doc picker item has not meta")
            }
        case .wiki(let wikiMeta):
            if let meta = wikiMeta.meta {
                self.associateNotesInfo(docToken: meta.id, docType: meta.type.rawValue)
            } else {
                EventEdit.logger.error("select wiki picker item has not meta")
            }
        default:
            EventEdit.logger.error("select picker item is not doc type")
            return
        }
    }
}
