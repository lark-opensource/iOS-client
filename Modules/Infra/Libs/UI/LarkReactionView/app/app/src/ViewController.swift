//
//  ViewController.swift
//  LarkReactionViewDev
//
//  Created by 李晨 on 2019/6/5.
//

import Foundation
import UIKit
import LarkReactionView
import SnapKit
import LarkEmotion

class ViewController: UIViewController, ReactionViewDelegate {
    func reactionDidTapped(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        print("did tapped type \(tapType)")
    }

    func reactionViewImage(_ reactionVM: ReactionInfo, callback: @escaping (UIImage) -> Void) {
        if let emotionInfo = EmotionHelper.reactionsDic[reactionVM.reactionKey],
            let image = EmotionResources.emotion(named: emotionInfo.imageName) {
            callback(image)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let reactonView1 = ReactionView()
        reactonView1.delegate = self
        reactonView1.preferMaxLayoutWidth = UIScreen.main.bounds.width - 100
        reactonView1.reactions = [
            ReactionInfo(reactionKey: "OK", users: [
                ReactionUser(id: "1", name: "测试1"),
                ReactionUser(id: "1", name: "测试2"),
                ReactionUser(id: "1", name: "测试3"),
                ReactionUser(id: "1", name: "测试4"),
                ReactionUser(id: "1", name: "测试5"),
                ReactionUser(id: "1", name: "测试1"),
                ReactionUser(id: "1", name: "测试2"),
                ReactionUser(id: "1", name: "测试3"),
                ReactionUser(id: "1", name: "测试4"),
                ReactionUser(id: "1", name: "测试5")
            ]),
            ReactionInfo(reactionKey: "LOVE", users: [
                ReactionUser(id: "2", name: "测试2"),
                ReactionUser(id: "2", name: "测试2"),
                ReactionUser(id: "2", name: "测试2")
            ]),
            ReactionInfo(reactionKey: "DULL", users: [
                ReactionUser(id: "3", name: "测试3")
            ]),
            ReactionInfo(reactionKey: "4", users: [
                ReactionUser(id: "4", name: "测试5")
            ])
        ]

        self.view.addSubview(reactonView1)
        reactonView1.snp.makeConstraints { (maker) in
            maker.left.equalTo(50)
            maker.right.equalTo(-50)
            maker.top.equalTo(100)
            maker.bottom.equalToSuperview()
        }
    }
}
