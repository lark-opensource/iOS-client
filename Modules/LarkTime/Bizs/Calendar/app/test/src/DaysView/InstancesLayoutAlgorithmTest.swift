//
//  InstancesLayoutAlgorithmTest.swift
//  CalendarTests
//
//  Created by heng zhu on 2018/12/14.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import XCTest
import RxSwift
import RustPB
@testable import Calendar

let requestScheduler: SerialDispatchQueueScheduler = SerialDispatchQueueScheduler(
    queue: DispatchQueue(label: "calendar.work.queue"),
    internalSerialQueueName: "calendar.work.queue"
)

//// swiftlint:disable number_separator
//class InstancesLayoutAlgorithmTest: XCTestCase {
//
//    let layoutAlgorithm = InstancesLayoutAlgorithm(layoutRequest: AuthMock.shareInstance.userClient().calendarApi(requestScheduler: requestScheduler).getInstancesLayoutRequest)
//    let key1 = Int32(2458477)
//    let key2 = Int32(2458478)
//    let key3 = Int32(2458479)
//
//    func testLayoutInstancesOne() {
//        var map = DaysInstancesContentMap()
//        let eventIndicatorUIColor = UIColor.cd.blue6
//        let frame1 = CGRect(x: 50, y: 200, width: 100, height: 50.0)
//        let content1 = DaysInstanceViewModel(instanceId: "-1",
//                              backgroundColor: eventIndicatorUIColor.withAlphaComponent(0.2),
//                              foregroundColor: eventIndicatorUIColor,
//                              isNewEvent: true,
//                              titleText: BundleI18n.Calendar.Calendar_Edit_addEventNamedTitle,
//                              indicatorColor: eventIndicatorUIColor,
//                              borderColor: eventIndicatorUIColor,
//                              frame: frame1,
//                              isEditable: true,
//                              longPressBorderColor: eventIndicatorUIColor)
//
//        map[key1] = [content1]
//
//        let result = layoutAlgorithm.layoutInstances(daysInstencesMap: map, isSingleDay: true, panelSize: CGSize(width: 111.666, height: 1200.0), daysRange: [key1])
//
//        XCTAssertTrue(result[key1]?.count == 1)
//    }
//
//    func testLayoutInstancesThree() {
//        var map = DaysInstancesContentMap()
//        let eventIndicatorUIColor = UIColor.cd.blue6
//        let frame1 = CGRect(x: 50, y: 200, width: 100, height: 50.0)
//        let frame2 = CGRect(x: 150, y: 250, width: 100, height: 50.0)
//        let frame3 = CGRect(x: 100, y: 300, width: 100, height: 50.0)
//        let content1 = DaysInstanceViewModel(instanceId: "-1",
//                        backgroundColor: eventIndicatorUIColor.withAlphaComponent(0.2),
//                        foregroundColor: eventIndicatorUIColor,
//                        isNewEvent: true,
//                        titleText: BundleI18n.Calendar.Calendar_Common_Add,
//                        indicatorColor: eventIndicatorUIColor,
//                        borderColor: eventIndicatorUIColor,
//                        frame: frame1,
//                        isEditable: true,
//                        longPressBorderColor: eventIndicatorUIColor)
//        let content2 = DaysInstanceViewModel(instanceId: "-1",
//                                             backgroundColor: eventIndicatorUIColor.withAlphaComponent(0.2),
//                                             foregroundColor: eventIndicatorUIColor,
//                                             isNewEvent: true,
//                                             titleText: BundleI18n.Calendar.Calendar_Common_Add,
//                                             indicatorColor: eventIndicatorUIColor,
//                                             borderColor: eventIndicatorUIColor,
//                                             frame: frame2,
//                                             isEditable: true,
//                                             longPressBorderColor: eventIndicatorUIColor)
//        let content3 = DaysInstanceViewModel(instanceId: "-1",
//                                             backgroundColor: eventIndicatorUIColor.withAlphaComponent(0.2),
//                                             foregroundColor: eventIndicatorUIColor,
//                                             isNewEvent: true,
//                                             titleText: BundleI18n.Calendar.Calendar_Common_Add,
//                                             indicatorColor: eventIndicatorUIColor,
//                                             borderColor: eventIndicatorUIColor,
//                                             frame: frame3,
//                                             isEditable: true,
//                                             longPressBorderColor: eventIndicatorUIColor)
//
//        map[key1] = [content1]
//        map[key2] = [content2]
//        map[key3] = [content3]
//
//        let result = layoutAlgorithm.layoutInstances(daysInstencesMap: map,
//                                                     isSingleDay: false,
//                                                     panelSize: CGSize(width: 111.666, height: 1200.0),
//                                                     daysRange: [key1, key2, key3])
//
//        XCTAssertTrue(result[key1]?.count == 1)
//        XCTAssertTrue(result[key2]?.count == 1)
//        XCTAssertTrue(result[key3]?.count == 1)
//    }
//
//}
