//
//  ToolBarViewController.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import UIKit

class ToolBarViewController: VMViewController<ToolBarViewModel>, MeetingLayoutStyleListener {
    var bottomBarGuide: UILayoutGuide?

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
    }
}
