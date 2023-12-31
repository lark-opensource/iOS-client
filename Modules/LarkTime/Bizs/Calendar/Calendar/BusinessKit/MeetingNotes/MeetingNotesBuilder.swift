//
//  MeetingNotesBuilder.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/26.
//

import Foundation
import LarkContainer
import CalendarFoundation
import RxSwift
import RxCocoa
import RustPB
import ServerPB
import LarkTimeFormatUtils
import LarkLocalizations
import LarkSetting

class MeetingNotesLoader: UserResolverWrapper {

    let userResolver: UserResolver

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var dependency: CalendarDependency?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    @LarkSetting.Setting(key: UserSettingKey.make(userKeyLiteral: "notes_ai_config"))
    var aiConfig: [String: String]?

    var docComponent: CalendarDocComponentAPIProtocol?

    private let disposeBag = DisposeBag()

    lazy var accessDataScheduler: SerialDispatchQueueScheduler = {
        .init(queue: accessDataQueue, internalSerialQueueName: accessDataQueue.label)
    }()

    lazy var accessDataQueue = {
        DispatchQueue(label: "lark.calendar.meeting_notes.accessData")
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 是否可以创建/关联纪要
    func canCreateNotes(with event: Rust.Event) -> Bool {
        let permission = event.meetingNotesConfig.createNotesPermissionRealValue()
        if permission == .all { return true }
        if permission == .organizer,
           let calendar = calendarManager?.calendar(with: event.organizerCalendarID),
           calendar.isOwnerOrWriter(),
           event.calendarID == event.organizerCalendarID {
            return true
        }
        return false
    }

    /// 获取 instance 绑定的 notesInfo 信息
    func getInstanceRelatedInfo(calendarID: String, key: String, originalTime: Int64, instanceStartTime: Int64) -> Observable<(MeetingNotesModel?, Bool)> {
        guard let api = api else { return .empty() }
        let fourTuple = CalendarRustAPI.InstanceFourTupleRequest(
            calendarID: calendarID,
            key: key,
            originalTime: originalTime,
            instanceStartTime: instanceStartTime
        )
        return api.getInstanceRelatedInfo(fourTuple: fourTuple).map { [weak self] res -> (MeetingNotesModel?, Bool) in
            var model: MeetingNotesModel? = MeetingNotesModel(fromRust: res.notesInfo)
            guard res.notesInfo.hasMeta else { return (nil, res.inNotesFg) }
            if var thumbnail = model?.thumbnail {
                thumbnail.rxImage = self?.getThumbnailImage(with: thumbnail, fileType: model?.type ?? 8)
                model?.thumbnail = thumbnail
            }
            return (model, res.inNotesFg)
        }
    }

    /// 根据 token、type 获取文档信息
    func getNotesInfo(
        with docToken: String,
        docType: Int,
        needNotesInfoType: [ServerPB_Calendar_entities_NotesInfoType] = ServerPB_Calendar_entities_NotesInfoType.allCases
    ) -> Observable<MeetingNotesModel?> {
        guard let api = api else { return .empty() }
        let request = CalendarRustAPI.InstanceNotesInfoRequest(docToken: docToken, docType: docType)
        return api.getNotesInfo(notes: request, needNotesInfoType: needNotesInfoType).map { [weak self] res -> MeetingNotesModel? in
            guard res.notesInfo.hasMeta else { return nil }
            var model: MeetingNotesModel? = MeetingNotesModel(fromServer: res.notesInfo)
            if var thumbnail = model?.thumbnail {
                thumbnail.rxImage = self?.getThumbnailImage(with: thumbnail, fileType: model?.type ?? 8)
                model?.thumbnail = thumbnail
            }
            return model
        }
    }

    /// 获取文档缩略图
    func getThumbnailImage(with thumbnail: MeetingNotesModel.Thumbnail, fileType: Int = 8) -> Observable<UIImage> {
        guard let dependency = dependency else { return .empty() }
        let thumbnailInfo: [String : Any] = [
            "url": thumbnail.thumbnailURL,
            "secret": thumbnail.decryptKey,
            "type": Int(thumbnail.cipherType)
        ]
        return dependency.getThumbnail(
            url: thumbnail.url,
            fileType: fileType,
            thumbnailInfo: thumbnailInfo,
            imageViewSize: CGSize(width: 272, height: 153)
        )
    }

    /// 同步文档最新缩略图
    func syncThumbnailImage(notes: MeetingNotesModel, completion: @escaping (Observable<UIImage>) -> Void)  {
        DispatchQueue.main.async {
            self.dependency?.syncThumbnail(
                fileToken: notes.token,
                fileType: notes.type
            ) { [weak self] _ in
                guard let self = self,
                      let thumbnail = notes.thumbnail else {
                    return
                }
                let rxImage = self.getThumbnailImage(with: thumbnail)
                completion(rxImage)
            }
        }
    }

    /// 1. 校验是否已有文档
    /// 2. 通过模版创建文档
    /// 3. 返回文档的详细信息（包含缩略图）
    /// - Parameters:
    ///   - templateItem: 模版参数信息
    ///   - title: 文档标题信息
    ///   - fourTuple: 日程四元组信息
    ///   - originalToken: 本地记录的日程有效会议 token
    /// - Returns: （文档信息，是否是新建的文档）
    func createNotes(by templateItem: CalendarTemplateItem?,
                     title: Server.NotesTitleForm,
                     fourTuple: CalendarRustAPI.InstanceFourTupleRequest? = nil,
                     originalToken: String? = nil) -> Observable<(MeetingNotesModel?, Bool)> {
        var checkMeetingNotesExit: Observable<MeetingNotesModel?> = .just(nil)
        if let fourTuple = fourTuple {
            /// 检验是否已有文档
            checkMeetingNotesExit = self.getInstanceRelatedInfo(
                calendarID: fourTuple.calendarID,
                key: fourTuple.key,
                originalTime: fourTuple.originalTime,
                instanceStartTime: fourTuple.instanceStartTime
            ).map(\.0)
        }
        return
        checkMeetingNotesExit
            .flatMap { [weak self] model -> Observable<(MeetingNotesModel?, Bool)> in
                guard let self = self, let api = self.api else { return .empty() }
                /// 此处情况：
                /// 1. 有 originalToken，有 model，场景：编辑已有notes日程，其他端换绑（token不相等），本端不可新建（不可新建，即使用其他端创建的文档）
                /// 2. 有 originalToken，无 model，场景：编辑已有notes日程，其他端删除，本端可新建
                /// 3. 无 originalToken，有 model，场景：编辑无 notes 日程，其他端新建，本端不可新建
                /// 4. 无 originalToken，无 model，场景：编辑无 notes 日程，本端可新建
                guard model == nil || model?.token == originalToken else {
                    /// 已有文档，且文档token与原先的不一致，直接返回该文档
                    return .just((model, false))
                }
                return api.createMeetingNotes(fourTuple: fourTuple,
                                              templateToken: templateItem?.objToken,
                                              templateType: templateItem?.objType,
                                              templateId: templateItem?.id,
                                              docTitle: title)
                .flatMap { [weak self] createRes -> Observable<(MeetingNotesModel?, Bool)> in
                    guard let self = self else { return .empty() }
                    return self.getNotesInfo(with: createRes.docToken, docType: createRes.docType.rawValue)
                        .map { model -> (MeetingNotesModel?, Bool) in
                            var model = model
                            /// 创建 Notes 部分字段设置默认值
                            model?.notesType = .createNotes
                            model?.docBotId = createRes.docBotID
                            model?.docOwnerId = createRes.docOwnerID
                            model?.showEventPermission = true
                            model?.eventPermission = CalendarNotesEventPermission.defaultValue()
                            return (model, true)
                        }
                }
            }

    }

    func deleteMeetingNotes(_ notes: MeetingNotesModel?, with tuple: CalendarRustAPI.InstanceFourTupleRequest? = nil) -> Observable<Void> {
        guard let notes = notes,
              case .createNotes = notes.notesType,
              let api = api else { return .empty() }
        let observable = api.deleteMeetingNotes(fourTuple: tuple,
                                                notes: .init(
                                                    docToken: notes.token,
                                                    docType: notes.type,
                                                    docOwnerId: notes.docOwnerId,
                                                    docBotId: notes.docBotId)
        ).share()
        observable.subscribe().disposed(by: disposeBag)
        return observable.map { _ in () }
    }

    /// 拉取有效会议模版列表
    /// 已废弃，后续下掉
    func fetchTemplateList() -> Observable<CalendarTemplateItem?> {
        guard let categoryId = SettingService.shared().settingExtension.vcCalendarMeeting,
              let dependency = dependency else {
            return .just(nil)
        }
        return dependency.fetchMeetingNotesTemplates(
            categoryId: String(categoryId),
            pageIndex: 1,
            pageSize: 1
        ).map { templates -> CalendarTemplateItem? in
            return templates.first
        }
    }


    /// 绑定 meetingNotes 到 instance
    func bindMeetingNotesToInstance(fourTuple: CalendarRustAPI.InstanceFourTupleRequest,
                                    model: MeetingNotesModel,
                                    originalDocToken: String?) -> Observable<ServerPB_Calendarevents_SaveInstanceNotesResponse> {
        guard let api = api else { return .empty() }
        return api.saveInstanceNotes(fourTuple: fourTuple, model: model, originalDocToken: originalDocToken)
    }

    /// 获取关联文档信息
    func getAssociateNotesInfo(
        docToken: String,
        docType: Int,
        needNotesInfoType: [ServerPB_Calendar_entities_NotesInfoType] = ServerPB_Calendar_entities_NotesInfoType.allCases
    ) -> Observable<MeetingNotesModel?> {
        self.getNotesInfo(with: docToken, docType: docType, needNotesInfoType: needNotesInfoType)
            .map { model -> MeetingNotesModel? in
                /// 关联 Notes 部分字段设置默认值
                var model = model
                model?.notesType = .bindNotes
                model?.showEventPermission = true
                model?.eventPermission = CalendarNotesEventPermission.defaultValue()
                return model
            }

    }
}

extension MeetingNotesLoader {
    static func makeDocTitle(templateTitle: String,
                             eventSummary: String,
                             date: Date,
                             timeZone: TimeZone) -> Server.NotesTitleForm {
        var title = Server.NotesTitleForm()
        title.eventSummary = eventSummary
        title.startTime = Int64(date.timeIntervalSince1970)
        title.startTimezone = timeZone.identifier
        return title
    }
}

extension MeetingNotesLoader {
    func showDocComponent(from vc: UIViewController,
                          url: URL,
                          delegate: CalendarDocComponentAPIDelegate?,
                          handleShowCompletion: ((UIViewController) -> Void)?) {
        guard let dependency = dependency,
              let docComponent = dependency.getDocComponentVC(url: url, delegate: delegate) else {
            assertionFailure("show doc vc failed")
            return
        }
        self.docComponent = docComponent
        vc.navigationController?.pushViewController(docComponent.docVC, animated: true)
        handleShowCompletion?(docComponent.docVC)
    }
}
