//
//  InterviewQuestionnaireDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/16.
//

import Foundation
import ByteViewNetwork

public protocol InterviewQuestionnaireDependency {
    var userId: String { get }
    var httpClient: HttpClient { get }
    func openURL(_ url: URL)
}
