//
//  ByteViewCalendarDependency.swift
//  ByteViewCalendar
//
//  Created by kiri on 2023/6/30.
//

import Foundation
import UIKit
import ByteViewNetwork

public protocol ByteViewCalendarDependency {
    func gotoUpgrade(from: UIViewController)
    func showPstnPhones(meetingNumber: String, phones: [PSTNPhone], from: UIViewController)
}
