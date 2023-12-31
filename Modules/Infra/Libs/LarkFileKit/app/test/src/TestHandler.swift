//
//  FileTrackerTest.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/11/4.
//

import Foundation
import LarkFileKit

class TestHandler: FileTrackInfoHandler {
    var trackInfos: [FileTrackInfo] = []

    func track(info: FileTrackInfo) {
        trackInfos.append(info)
    }
}
