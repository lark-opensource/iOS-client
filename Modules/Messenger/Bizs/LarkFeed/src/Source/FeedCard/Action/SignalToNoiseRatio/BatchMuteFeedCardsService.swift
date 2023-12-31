//
//  BatchMuteFeedCardsService.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/8.
//

import Foundation
import RxSwift
import UIKit

protocol BatchMuteFeedCardsService {
    var pushMuteFeedCards: Observable<PushMuteFeedCards> { get }

    func addTaskID(taskID: String, mute: Bool)
    func addAtAllTaskID(taskID: String, muteAtAll: Bool)
}
