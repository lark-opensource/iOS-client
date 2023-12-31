//
//  ViewController.swift
//  LarkMenuControllerDev
//
//  Created by 李晨 on 2019/6/11.
//

import Foundation
import UIKit
import LarkMenuController
import LarkEmotion
import LarkInteraction
import LarkEmotionKeyboard

class ViewController: UIViewController {}

/*
class ViewController: UIViewController, ReactionImageDelegate {

    static func reactionViewImage(_ reactionKey: String, callback: @escaping (UIImage) -> Void) {
        if let emotionInfo = EmotionHelper.reactionsDic[reactionKey],
            let image = EmotionResources.emotion(named: emotionInfo.imageName) {
            callback(image)
        }
    }

    static func getImageByKey(_ reactionKey: String) -> UIImage? {
        if let emotionInfo = EmotionHelper.reactionsDic[reactionKey] {
            return EmotionResources.emotion(named: emotionInfo.imageName)
        }
        return nil
    }

    var tap: UITapGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()

        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleGesuture(gesture:))
        )
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gesture)

        let right = RightClickRecognizer(
            target: self,
            action: #selector(handleGesuture(gesture:))
        )
        view.addGestureRecognizer(right)

        self.tap = gesture
    }

    @objc
    private func handleGesuture(gesture: UIGestureRecognizer) {
        guard gesture.state == .began || gesture is UITapGestureRecognizer else {
            return
        }
        let actionItems = [
            MenuActionItem(
                name: "1",
                image: UIImage(named: "menu_multi")!,
                enable: true,
                action: { (_) in
                    print("click action 1")
                }),
            MenuActionItem(
                name: "21asdfasdfasdfasdfa",
                image: UIImage(named: "menu_reply")!,
                enable: true,
                action: { (_) in
                    print("click action 2")
            })
        ]

        let reactions = EmotionHelper.reactions.map { (key) -> MenuReactionItem in
            return MenuReactionItem(type: key, action: { (key) in
                print("click reaction \(key)")
            })
        }

        let vm = MenuViewModel(
            recent: Array(reactions.prefix(6)),
            allReactions: reactions,
            actionItems: actionItems)

        // 更新 reactin bar 位置 方式1
        vm.menuBar.reactionBarAtTop = false
        vm.menuBar.actionBar.actionIconInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        let layout = SimpleMenuLayout()

        let menu = MenuViewController(
            viewModel: vm,
            layout: layout,
            trigerView: self.view,
            trigerLocation: gesture.location(in: self.view))

        tap?.isEnabled = false

        // dismiss block
        menu.dismissBlock = { [weak self] in
            self?.tap?.isEnabled = true
        }

        // 直接 present
//        menu.modalPresentationStyle = .overCurrentContext
//        self.present(menu, animated: false, completion: nil)

        // OR
        menu.show(in: self)
    }
}

class MenuViewModel: SimpleMenuViewModel {
    open override func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {
        if isFirstTime {
            // 更新 reactin bar 位置 方式2
            var reactionBatAtTop: Bool = true
            if let location = info.transformTrigerLocation() {
                reactionBatAtTop = location.y < rect.origin.y
            } else if let locationRect = info.transformTrigerView() {
                reactionBatAtTop = locationRect.origin.y < rect.origin.y
            }
            self.menuBar.reactionBarAtTop = reactionBatAtTop
        }
    }
}
*/
