//
//  ViewController.swift
//  LarkReactionDetailControllerDev
//
//  Created by 李晨 on 2019/6/17.
//

import UIKit
import Foundation
import LarkUIKit
import LarkPageController
import LarkReactionDetailController
import LarkEmotion

class ViewController: UIViewController, ReactionDetailViewModelDelegate {
    private let button = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        button.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        button.backgroundColor = UIColor.ud.R200
        button.addTarget(self, action: #selector(showDetail), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc
    private func showDetail() {
        show()
    }

    func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let info = EmotionHelper.reactionsDic[reaction],
                let image = EmotionResources.emotion(named: info.imageName) {
                callback(image)
            }
        }
    }

    func reactionDetailFetchReactions(message: Message, callback: @escaping ([Reaction]?, Error?) -> Void) {

        let reactions: [Reaction] = [
            Reaction(type: "OK", chatterIds: ["1", "2", "3", "4", "5"]),
            Reaction(type: "THUMBSUP", chatterIds: ["1", "2", "3", "4", "5", "1"]),
            Reaction(type: "HEART", chatterIds: ["1", "2", "3", "4", "5", "2"]),
            Reaction(type: "APPLAUSE", chatterIds: ["1", "2", "3", "4", "5", "3"]),
            Reaction(type: "BLUSH", chatterIds: ["1", "2", "3", "4", "5", "4"]),
            Reaction(type: "MUSCLE", chatterIds: ["1", "2", "3", "4", "5", "5"])
        ]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            callback(reactions, nil)
        }
    }

    func reactionDetailFetchChatters(
        message: Message,
        reaction: Reaction,
        callback: @escaping ([Chatter]?, Error?) -> Void
    ) {
        let chattersMap = [
            "1": Chatter(
                id: "1",
                avatarKey: "avatar1",
                displayName: "1111",
                descriptionText: "hahaha",
                descriptionType: .onDefault),
            "2": Chatter(
                id: "2",
                avatarKey: "avatar2",
                displayName: "2222",
                descriptionText: "hahaasdfasdfasdfasdfasdfasdfsadfha",
                descriptionType: .onBusiness),
            "3": Chatter(
                id: "3",
                avatarKey: "avatar3",
                displayName: "3333",
                descriptionText: "hahaha",
                descriptionType: .onLeave),
            "4": Chatter(
                id: "4",
                avatarKey: "avatar4",
                displayName: "4444",
                descriptionText: "hahaha",
                descriptionType: .onMeeting),
            "5": Chatter(
                id: "5",
                avatarKey: "avatar5",
                displayName: "5555",
                descriptionText: "",
                descriptionType: .onDefault)
        ]

        let chatters = reaction.chatterIds.compactMap { (id) -> Chatter? in
            return chattersMap[id]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            callback(chatters, nil)
        }
    }

    func reactionDetailFetchChatterAvatar(message: Message, chatter: Chatter, callback: @escaping (UIImage) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let image = UIImage(named: "\(chatter.avatarKey).jpg") {
                callback(image)
            }
        }
    }

    func reactionDetailClickChatter(message: Message, chatter: Chatter, controller: UIViewController) {
        print("did click chatter \(chatter.id)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    private func show() {
        let message = Message(id: "123", channelID: "123")
        let controller = ReactionDetailVCFactory.create(message: message, dependency: self)
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.view.backgroundColor = UIColor.clear
        self.present(controller, animated: true, completion: nil)
    }
}
