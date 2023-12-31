//
//  EventEditViewController+MeetingNotes.swift
//  Calendar
//
//  Created by huoyunjie on 2023/6/8.
//

import Foundation
import UniverseDesignToast
import CalendarFoundation
import LarkModel
import UniverseDesignActionPanel
import UniverseDesignIcon

extension EventEditViewController: MeetingNotesViewDelegate {
    /// 日程埋点通参
    var commonParamData: CommonParamData {
        .init(event: self.viewModel.eventModel?.rxModel?.value.getPBModel())
    }

    var loader: MeetingNotesLoader? {
        self.viewModel.meetingNotesModel?.loader
    }

    func createTemplateHorizontalListView(_ view: MeetingNotesView) -> CalendarTemplateHorizontalListViewProtocol? {
        let categoryId = SettingService.shared().settingExtension.vcCalendarMeeting ?? -1
        return calendarDependency?.createTemplateHorizontalListView(frame: .zero,
                                                           params: CalendarHorizontalTemplateParams(itemHeight: 147, pageSize: 3, categoryId: String(categoryId), createDocParams: .init()),
                                                                    delegate: view)
    }

    /// 进入 Permission 控制页面
    func onClickPermissionButton(_ view: MeetingNotesView) {
        guard case .viewData = view.viewData,
              let model = viewModel.meetingNotesModel?.currentNotes else { return }
        calendarDependency?.showDocAdjustExternalPanel(from: self, url: model.url) { [weak self] result in
            switch result {
            case .success: self?.viewModel.meetingNotesModel?.refreshCurrentNotes()
            case .failure: break
            }
        }
        CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParamData) {
            $0.click("meeting_notes_share_settings")
        }
    }

    /// 点击重试 Label
    func onClickRetryButton(_ view: MeetingNotesView) {
        guard case let .failed(retry) = view.viewData else { return }
        retry()
    }

    /// 进入 DocComponent
    func onEnterDocComponent(_ view: MeetingNotesView) {
        guard case .viewData = view.viewData,
              let model = viewModel.meetingNotesModel?.currentNotes,
              let url = URL(string: model.url) else { return
        }
        showDocComponent(url: url)
        CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParamData) {
            $0.click("meeting_notes")
        }
    }

    /// 创建空白 Doc
    func onCreateEmptyDoc(_ view: MeetingNotesView) {
        guard canCreateMeetingNotes() else {
            UDToast.showTips(with: I18n.Calendar_G_OrgnizerForbidThis_Tooltip, on: self.view)
            return
        }
        CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParamData) {
            $0.click("meeting_notes_button")
            $0.have_ai = "false"
        }
        self.createMeetingNotes(by: nil, in: self)
    }

    /// 不可用状态下点击操作
    func onDisableStatus(_ view: MeetingNotesView) {
        guard case .disabled(_, _, let reason) = view.viewData,
              let reason = reason else {
            return
        }
        UDToast.showTips(with: reason, on: self.view)
    }

    /// 根据模版创建 Doc
    func templateOnItemSelected(_ viewController: UIViewController, item: CalendarTemplateItem) {
        self.createMeetingNotes(by: item, in: viewController)
    }

    /// 点击模板回调，false 表示不拦截，由ccm处理，true 表示拦截，由也无妨处理
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, didClick templateId: String) -> Bool {
        return false
    }

    /// 模版View创建文档回调
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onCreateDoc result: CalendarDocsTemplateCreateResult?, error: Error?) {
    }

    /// 模版View加载失败
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onFailedStatus: Bool) {
        self.viewModel.meetingNotesModel?.rxModel?.accept(.createEmpty)
    }

    /// 进入关联文档页面
    func onAssociateDoc(_ view: MeetingNotesView) {
        guard canCreateMeetingNotes() else {
            UDToast.showTips(with: I18n.Calendar_G_OrgnizerForbidThis_Tooltip, on: self.view)
            return
        }
        onEnterAssociateDoc()
    }

    func onEnterAssociateDoc() {
        if let vc = self.calendarDependency?.createAssociateDocPickController(pickerDelegate: self) {
            self.navigationController?.present(vc, animated: true)
        }
    }

    /// 通过 AI 创建 Doc
    func onCreateAIDoc(_ view: MeetingNotesView) {
        guard canCreateMeetingNotes() else {
            UDToast.showTips(with: I18n.Calendar_G_OrgnizerForbidThis_Tooltip, on: self.view)
            return
        }
        CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParamData) {
            $0.click("meeting_notes_button")
            $0.have_ai = "true"
        }
        self.createMeetingNotes(by: nil, in: self, withAI: true)
    }

    /// 设置日程参与者对文档的权限
    func showPermissionSelectView(_ view: MeetingNotesPermissionView, onCompleted: @escaping ((CalendarNotesEventPermission) -> Void)) {
        guard let notes = viewModel.meetingNotesModel?.currentNotes else { return }
        let originalPermission = notes.eventPermission
        let changeNotesEventPermission: (CalendarNotesEventPermission) -> Void = { [weak self] permission in
            guard let self = self, permission != originalPermission else {
                onCompleted(originalPermission)
                return
            }
            self.viewModel.meetingNotesModel?.changeNotesEventPermission(permission)
            onCompleted(permission)
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

        self.present(actionSheet, animated: true, completion: nil)

    }
}

extension EventEditViewController: CalendarDocComponentAPIDelegate {
    /// 打开文档
    private func showDocComponent(url :URL, handlePushCompletion: ((UIViewController) -> Void)? = nil) {
        loader?.showDocComponent(from: self, url: url, delegate: self, handleShowCompletion: handlePushCompletion)
    }

    /// 文档即将关闭回调
    func willClose() {
        /// 销毁 docComponent
        self.loader?.docComponent = nil
        self.viewModel.meetingNotesModel?.refreshCurrentNotes()
    }

    func getSubScene() -> String {
        "calendar_create"
    }

    func onInvoke(data: [String: Any]?, callback: CalendarDocComponentInvokeCallBack?) {
        guard let event = self.viewModel.eventModel?.rxModel?.value.getPBModel(),
              let data = data,
              let command = data["command"] as? String,
              command == "GET_AI_INFO" else {
            return
        }
        let payload = [
            "params": [
                "content": event.summary,
                "promptId": loader?.aiConfig?["calendar_prompt_id"]
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

extension EventEditViewController {

    private func canCreateMeetingNotes() -> Bool {
        return viewModel.meetingNotesModel?.canBindNotes() ?? false
    }
    /// 创建文档
    private func createMeetingNotes(by template: CalendarTemplateItem?,
                                    in viewController: UIViewController,
                                    withAI: Bool = false) {
        assert(Thread.current == Thread.main)
        let removeToEventEditVC: ((UIViewController) -> Void) = { [weak self] vc in
            guard let self = self else { return }
            let childVC = self.navigationController?.children
            if var childVC = childVC,
               let currentIndex = childVC.firstIndex(of: vc),
               let eventEditIndex = childVC.firstIndex(of: self),
               eventEditIndex + 1 <= currentIndex{
                let range = (eventEditIndex + 1)...currentIndex
                childVC.removeSubrange(range)
                self.navigationController?.setViewControllers(childVC, animated: false)
            }
        }

        let toast = UDToast.showLoading(with: I18n.Calendar_Notes_CreatingDotDot, on: viewController.view, disableUserInteraction: true)
        self.viewModel.createMeetingNotes(by: template)
            .subscribeForUI(onNext: { [weak self] (model, isNewCreate) in
                guard let self = self else { return }
                toast.remove()
                if let model = model,
                   var url = URL(string: model.url) {
                    CalendarTracerV2.EventFullCreate.traceClick(commonParam: self.commonParamData) {
                        $0.click("create_meeting_notes")
                        $0.template_id = template?.id ?? "none"
                        $0.have_ai = withAI.description
                    }
                    if isNewCreate, withAI {
                        /// 创建文档后，若启用AI，打开文档侧提供showAI=true后缀
                        let params: [String: String] = [
                            "showAI": "true"
                        ]
                        url = url.append(parameters: params)
                    }
                    self.showDocComponent(url: url) { vc in
                        if !isNewCreate {
                            UDToast.showTips(with: I18n.Calendar_G_Notes_CreatedAlreadyOpenNow_Toast, on: vc.view)
                        }
                    }
                    removeToEventEditVC(viewController)
                } else {
                    UDToast.showFailure(with: I18n.Calendar_Notes_NoCreateTryLater, on: viewController.view)
                }
            }, onError: { error in
                let toastStr = I18n.Calendar_Notes_NoCreateTryLater
                if error.errorType() == .createOrBindNotesAccessForbiddenErr {
                    UDToast.showTips(with: I18n.Calendar_G_OrgnizerForbidThis_Tooltip, on: viewController.view)
                    return
                }
                UDToast.showFailure(with: error.getTitle(errorScene: .meetingNotes) ?? toastStr, on: viewController.view)
            }).disposed(by: disposeBag)
    }

    /// 关联文档
    func associateNotes(token: String, type: Int) {
        let toast = UDToast.showLoading(with: I18n.Calendar_G_LoadingDocs_Desc, on: self.view, disableUserInteraction: true)
        self.viewModel.associateMeetingNotes(
            token: token,
            type: type
        ).subscribeForUI(onNext: { [weak self] model in
            guard let self = self else { return }
            toast.remove()
            if model == nil {
                UDToast.showFailure(with: I18n.Calendar_G_CantLinkTryAgain_Toast, on: self.view)
            }
        }, onError: { [weak self] _ in
            guard let self = self else { return }
            UDToast.showFailure(with: I18n.Calendar_G_CantLinkTryAgain_Toast, on: self.view)
        }).disposed(by: disposeBag)
    }
}

extension EventEditViewController: SearchPickerDelegate {

    func pickerDidSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) {
        switch item.meta {
        case .doc(let docMeta):
            if let meta = docMeta.meta {
                self.associateNotes(token: meta.id, type: meta.type.rawValue)
            } else {
                EventEdit.logger.error("select doc picker item has not meta")
            }
        case .wiki(let wikiMeta):
            if let meta = wikiMeta.meta {
                self.associateNotes(token: meta.id, type: meta.type.rawValue)
            } else {
                EventEdit.logger.error("select wiki picker item has not meta")
            }
        default:
            EventEdit.logger.error("select picker item is not correct type")
            return
        }
    }
}
