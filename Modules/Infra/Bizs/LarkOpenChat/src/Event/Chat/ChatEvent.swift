//
//  ChatEvent.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/21.
//

import Foundation
import LarkModel
import LarkOpenIM

public final class ViewWillAppear: Event {
    public override class var name: String { return "ViewWillAppear" }
    public override class var type: EventType { return .chat }
}

public final class ViewDidAppear: Event {
    public override class var name: String { return "ViewDidAppear" }
    public override class var type: EventType { return .chat }
}

public final class ViewWillDisappear: Event {
    public override class var name: String { return "ViewWillDisappear" }
    public override class var type: EventType { return .chat }
}

public final class ViewDidDisappear: Event {
    public override class var name: String { return "ViewDidDisappear" }
    public override class var type: EventType { return .chat }
}
