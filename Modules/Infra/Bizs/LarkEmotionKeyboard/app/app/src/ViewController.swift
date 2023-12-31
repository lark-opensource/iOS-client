//
//  ViewController.swift
//  LarkEmotionKeyboardDev
//
//  Created by 王元洵 on 2021/2/26.
//

import Foundation
import UIKit
import LarkEmotionKeyboard
import SnapKit

class ViewController: UIViewController {}
/*
class ViewController: UIViewController,
                      EmojiDataSourceDependency,
                      EmojiEmotionItemDelegate {
    func loadReactions() {
    }

    func emojiEmotionInputViewDidTapCell(emojiKey: String) {
        print("tap cell")
    }

    func emojiEmotionInputViewDidTapBackspace() {
        print("tap backspace")
    }

    func emojiEmotionInputViewDidTapSend() {
        print("tap send")
    }

    func emojiEmotionActionEnable() -> Bool {
        true
    }

    func isKeyboardNewStyleEnable() -> Bool {
        false
    }

    func getRecentReactions() -> [String] {
        var testRecentReactions: [String] = []
        for _ in 1...7 {
            testRecentReactions.append("JIAYI")
        }
        return testRecentReactions
    }

    func getUsedReactions() -> [String] {
        var testUsedReactions: [String] = []
        for _ in 1...35 {
            testUsedReactions.append("JIAYI")
        }
        return testUsedReactions
    }

    func loadReactionsIfNeeded() {
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let mockDataSource = MockEmotionDataSource(dependency: self,
                                                   displayInPad: false,
                                                   displayHeight: 812)
        mockDataSource.delegate = self
        let emotionKeyboard = EmotionKeyboardView(config: .init(backgroundColor: UIColor.lk.N100,
                                                                cellDidSelectedColor: UIColor.lk.N300),
                                                  dataSources: [mockDataSource])
        self.view.addSubview(emotionKeyboard)
        emotionKeyboard.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(336)
        }
    }
}
*/
