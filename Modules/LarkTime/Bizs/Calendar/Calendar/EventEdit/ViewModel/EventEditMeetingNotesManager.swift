//
//  EventEditMeetingNotesManager.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/31.
//

import Foundation
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkContainer

protocol EventEditMeetingNotesManagerDelegate: AnyObject, EventEditModelGetterProtocol {
    func editSpanType() -> Span
}

class EventEditMeetingNotesMananger: EventEditModelManager<MeetingNotesViewStatus> {

    lazy var loader: MeetingNotesLoader = {
        MeetingNotesLoader(userResolver: self.userResolver)
    }()

    let input: EventEditInput

    let rxViewStatus: BehaviorRelay<MeetingNotesViewStatus> = .init(value: .hidden)

    typealias Notes = MeetingNotesModel
    
    private(set) var originalNotes: Notes?

    private(set) var currentNotes: Notes?

    weak var delegate: EventEditMeetingNotesManagerDelegate?

    var docComponent: CalendarDocComponentAPIProtocol?

    var inMeetingNotesFG: Bool {
        if input.isFromCreating {
            return FG.meetingNotes
        } else if case .hidden = rxViewStatus.value {
            /// hidden 场景：不在fg、拉取失败
            return false
        } else {
            return true
        }
    }

    var notesHasEdit: Bool {
        // 当都为 nil 时，可能为新增又删除的场景
        currentNotes != originalNotes || currentNotes?.eventPermission != originalNotes?.eventPermission
    }

    let disposeBag = DisposeBag()

    init(userResolver: UserResolver, input: EventEditInput, identifier: String) {
        self.input = input
        super.init(userResolver: userResolver, identifier: EventEditModelType.meetingNotes.rawValue, rxModel: rxViewStatus)
        switch input {
        case .createWithContext, .copyWithEvent:
            bindToViewStatus(FG.meetingNotes ? .createMeetingNotes : .hidden)
        case .editFrom:
            fetchInstanceRelatedInfo()
        case .editFromLocal, .createWebinar, .editWebinar:
            bindToViewStatus(.hidden)
        }
    }

    /// 原日程四元组
    var originalFourTuple: CalendarRustAPI.InstanceFourTupleRequest? {
        switch input {
        case .editFrom(let event, let instance):
            return CalendarRustAPI.InstanceFourTupleRequest(
                calendarID: event.calendarID,
                key: event.key,
                originalTime: event.originalTime,
                instanceStartTime: instance.startTime)
        default:
            return nil
        }
    }

    /// 获取 instance 绑定的 notes 信息
    func fetchInstanceRelatedInfo() {
        switch input {
        case .editFrom(let event, let instance):
            loader.getInstanceRelatedInfo(calendarID: event.calendarID,
                                          key: event.key,
                                          originalTime: event.originalTime,
                                          instanceStartTime: instance.startTime)
            .observeOn(loader.accessDataScheduler)
            .map { [weak self] (notesInfo, inNotesFG) -> MeetingNotesViewStatus in
                guard inNotesFG else { return .hidden }
                guard let self = self, let notes = notesInfo else {
                    // 没有绑定 notesInfo
                    return .createMeetingNotes
                }
                self.originalNotes = notes
                self.currentNotes = notes
                let meetingNotesViewData = notes.transformToViewData()
                return .viewData(meetingNotesViewData)
            }.subscribe(onNext: { [weak self] viewStatus in
                self?.bindToViewStatus(viewStatus)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error.errorType() == .instanceInfoErrorInMeetingNotesFG {
                    self.bindToViewStatus(.failed(retryAction: self.fetchInstanceRelatedInfo))
                } else if error.errorType() == .getNotesInstanceNotFound {
                    let isThisSpan = (self.delegate?.editSpanType() ?? .thisEvent) == .thisEvent
                    self.bindToViewStatus(isThisSpan ? .hidden : .createMeetingNotes)
                } else {
                    self.bindToViewStatus(.hidden)
                }
            }).disposed(by: disposeBag)
        default:
            return
        }
    }

    /// 删除场景
    enum DeleteScene {
        /// 取消编辑场景，如果 currentNotes != originalNotes，删除新创建的 Notes
        case cancelEdit
        /// 保存场景，如果 currentNotes != originalNotes，删除原来的Notes
        case save
        /// 如果是新建的 Notes，则立即删除，如果是 originalNotes 则在保存时删除，防止用户取消编辑
        case currentNotes
    }

    /// 删除文档
    @discardableResult
    func deleteMeetingNotes(_ scene: DeleteScene) -> Observable<Void> {
        var observable: Observable<Void> = .just(())
        switch scene {
        case .currentNotes:
            if currentNotes != originalNotes {
                observable = loader.deleteMeetingNotes(currentNotes)
            }
            loader.accessDataQueue.async {
                self.currentNotes = nil
                self.bindToViewStatus(.createMeetingNotes)
            }
        case .cancelEdit:
            if currentNotes != originalNotes,
               currentNotes?.notesType == .createNotes {
                observable = loader.deleteMeetingNotes(currentNotes, with: originalFourTuple)
            }
        case .save:
            if currentNotes != originalNotes {
                observable = loader.deleteMeetingNotes(originalNotes, with: originalFourTuple)
            }
        }
        return observable
    }

    /// 编辑页创建新的文档
    func createMeetingNotes(by templateItem: CalendarTemplateItem?, title: Server.NotesTitleForm) -> Observable<(MeetingNotesModel?, Bool)> {
        let observable = loader.createNotes(by: templateItem,
                                            title: title,
                                            fourTuple: originalFourTuple,
                                            originalToken: originalNotes?.token)
            .share()
        observable
            .observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] (model, isNewCreate) in
                if !isNewCreate {
                    self?.originalNotes = model
                }
                guard let model = model else {
                    self?.bindToViewStatus(.createMeetingNotes)
                    return
                }
                let viewData = model.transformToViewData()
                self?.currentNotes = model
                self?.bindToViewStatus(.viewData(viewData))
            })
            .disposed(by: disposeBag)
        return observable
    }

    /// 获取有效会议模版列表
    /// 已废弃，后续下掉
    func fetchTemplateList() -> Observable<CalendarTemplateItem?> {
        loader.fetchTemplateList()
    }

    /// 刷新当前文档信息，注意：文档部分信息不可被 getNotesInfo 返回值覆盖
    func refreshCurrentNotes() {
        guard let notes = currentNotes else {
            return
        }
        let docOwnerId = notes.docOwnerId
        let docBotId = notes.docBotId
        let eventPermission = notes.eventPermission
        let showEventPermission = notes.showEventPermission
        let notesType = notes.notesType
        loader.getNotesInfo(with: notes.token, docType: notes.type)
            .observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] model in
                guard let self = self, self.currentNotes == notes else { return }
                guard var model = model else {
                    /// 文档被删除
                    self.currentNotes = nil
                    self.bindToViewStatus(.createMeetingNotes)
                    return
                }
                /// 部分信息不可被 getNotesInfo 返回值覆盖
                model.docOwnerId = docOwnerId
                model.docBotId = docBotId
                model.eventPermission = eventPermission
                model.showEventPermission = showEventPermission
                model.notesType = notes.notesType

                let viewData = model.transformToViewData()
                self.currentNotes = model
                self.bindToViewStatus(.viewData(viewData))
                self.syncThumbnailImage()
            }).disposed(by: disposeBag)
    }
    
    /// 通过Model重置MeetingNotes
    func resetMeetingNote(model: MeetingNotesModel?) {
        if let model = model {
            let viewData = model.transformToViewData()
            self.currentNotes = model
            self.bindToViewStatus(.viewData(viewData))
        } else {
            self.currentNotes = nil
            self.bindToViewStatus(.createMeetingNotes)
        }
    }

    /// 同步缩略图最新变更
    private func syncThumbnailImage() {
        guard var notes = currentNotes else { return }
        loader.syncThumbnailImage(notes: notes) { [weak self] rxThumbnail in
            guard let self = self else { return }
            self.loader.accessDataQueue.async {
                if self.currentNotes == notes {
                    notes.thumbnail?.rxImage = rxThumbnail
                    self.currentNotes = notes
                    let viewData = notes.transformToViewData()
                    self.bindToViewStatus(.viewData(viewData))
                }
            }
        }
    }

    /// 关联文档
    func associateMeetingNotes(token: String, type: Int) -> Observable<MeetingNotesModel?> {
        let observable = loader.getAssociateNotesInfo(docToken: token, docType: type).share()
        observable.observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] model in
                guard let model = model else {
                    self?.bindToViewStatus(.createMeetingNotes)
                    return
                }
                let viewData = model.transformToViewData()
                self?.currentNotes = model
                self?.bindToViewStatus(.viewData(viewData))
            }).disposed(by: disposeBag)
        return observable
    }

    /// 变更日程协作人对文档的权限
    func changeNotesEventPermission(_ permission: CalendarNotesEventPermission) {
        self.currentNotes?.eventPermission = permission
    }

    /// 收敛ViewStatus信号发送，进行统一处理
    func bindToViewStatus(_ viewStatus: MeetingNotesViewStatus) {
        var viewStatus = viewStatus
        switch viewStatus {
        case .viewData(var viewData):
            /// 修改doc删除按钮权限
            viewData.isDocDeletable = canBindNotes()
            viewStatus = .viewData(viewData)
        default: break
        }
        self.rxViewStatus.accept(viewStatus)
    }
}

extension EventEditMeetingNotesMananger {
    /// 是否可以进行创建/解绑操作
    func canBindNotes() -> Bool {
        guard let event = delegate?.getEventEditModel() else {
            return false
        }
        return loader.canCreateNotes(with: event.getPBModel())
    }
}
