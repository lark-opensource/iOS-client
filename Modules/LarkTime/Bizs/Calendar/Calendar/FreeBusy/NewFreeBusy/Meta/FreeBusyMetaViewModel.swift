//
//  FreeBusyMetaViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/8/28.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import LarkContainer

class FreeBusyMetaViewModel: UserResolverWrapper {
    let logger = Logger.log(FreeBusyMetaViewModel.self, category: "Calendar.FreeBusyMetaViewModel")
    
    let userResolver: UserResolver
    let sceneType: FreeBusySceneType
    
    var freeBusyViewModel: FreeBusyViewModel?
    var groupFreeBusyViewModel: GroupFreeBusyViewModel?
    var arrangementViewModel: ArrangementViewModel?
    var meetingRoomFreeBusyViewModel: MeetingRoomFreeBusyViewModel?
    
    init(userResolver: UserResolver,
         userIds: [String],
         isFromProfile: Bool,
         createEventSucceedHandler: @escaping CreateEventSucceedHandler) {
        self.userResolver = userResolver
        self.sceneType = .profile
        freeBusyViewModel = FreeBusyViewModel(userResolver: userResolver,
                                              userIds: userIds,
                                              isFromProfile: isFromProfile,
                                              createEventSucceedHandler: createEventSucceedHandler)
    }
    
    init (userResolver: UserResolver,
          userIds: [String],
          meetingRoom: Rust.MeetingRoom,
          createEventBody: CalendarCreateEventBody? = nil,
          createEventSucceedHandler: @escaping CreateEventSucceedHandler) {
        self.userResolver = userResolver
        self.sceneType = .meetingRoom
        
        meetingRoomFreeBusyViewModel = MeetingRoomFreeBusyViewModel(userResolver: userResolver,
                                                                    userIds: userIds,
                                                                    meetingRoom: meetingRoom,
                                                                    createEventBody: createEventBody,
                                                                    createEventSucceedHandler: createEventSucceedHandler)
    }
    
    init (userResolver: UserResolver,
          chatId: String,
          chatType: String,
          createEventBody: CalendarCreateEventBody? = nil,
          createEventSucceedHandler: @escaping CreateEventSucceedHandler) {
        self.userResolver = userResolver
        self.sceneType = .group
        
        groupFreeBusyViewModel = GroupFreeBusyViewModel(userResolver: userResolver,
                                                        chatId: chatId,
                                                        chatType: chatType,
                                                        createEventBody: createEventBody,
                                                        createEventSucceedHandler: createEventSucceedHandler)
    }
    
    
    init(userResolver: UserResolver,
         dataSource: ArrangementDataSource) {
        self.userResolver = userResolver
        self.sceneType = .append
        
        arrangementViewModel = ArrangementViewModel(userResolver: userResolver,
                                                    dataSource: dataSource)
    }
    
    func getCreateEventCoordinator(
        contextBuilder: (UnsafeMutablePointer<EventCreateContext>) -> Void = { _ in }
    ) -> EventEditCoordinator {
        var createContext = EventCreateContext()
        contextBuilder(&createContext)
        return EventEditCoordinator(
            userResolver: self.userResolver,
            editInput: .createWithContext(createContext),
            dependency: EventEditCoordinator.DependencyImpl(userResolver: self.userResolver)
        )
    }
}

extension FreeBusyMetaViewModel {
    
    func buildContentViewModel() -> FreeBusyDetailViewModel? {
        switch sceneType {
        case .profile:
            return freeBusyViewModel
        case .group:
            return groupFreeBusyViewModel
        case .meetingRoom:
            return meetingRoomFreeBusyViewModel
        case .append:
            return arrangementViewModel
        default:
            logger.error("can't buildContentViewModel with unknown sceneType")
        }
    }
}

// MARK: - Common Data
enum FreeBusySceneType {
    case profile
    case group
    case append
    case meetingRoom
}
