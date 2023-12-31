//
//  CalendarAttachableComponentRegistery.swift
//  CalendarFoundation
//
//  Created by tuwenbo on 2022/9/13.
//

import Foundation
import RustPB
import RxSwift
import RxRelay
import LarkContainer

public final class CalendarAttachableComponentRegistery {
    private static var attachableComponents: [AttachableComponentType: AttachableComponent.Type] = [:]

    public static func register(identifier: AttachableComponentType, type: AttachableComponent.Type) {
        attachableComponents[identifier] = type
    }

    public static func buildComponent(for identifier: AttachableComponentType, with rxEventData: BehaviorRelay<CalendarEventData>, userResolver: UserResolver) -> Component? {
        if let componentType = attachableComponents[identifier] {
            return componentType.init(userResolver: userResolver, rxEventData: rxEventData)
        }
        return nil
    }
}

public enum AttachableComponentType {
    case larkMeeting
}

public struct CalendarEventData {
    public let event: RustPB.Calendar_V1_CalendarEvent
    public let instance: RustPB.Calendar_V1_CalendarEventInstance

    public init(event: RustPB.Calendar_V1_CalendarEvent, instance: RustPB.Calendar_V1_CalendarEventInstance) {
        self.event = event
        self.instance = instance
    }
}

open class AttachableComponent: UserContainerComponent {
    public var rxEventData: BehaviorRelay<CalendarEventData>

    required public init(userResolver: UserResolver, rxEventData: BehaviorRelay<CalendarEventData>) {
        self.rxEventData = rxEventData
        super.init(userResolver: userResolver)
    }

}
