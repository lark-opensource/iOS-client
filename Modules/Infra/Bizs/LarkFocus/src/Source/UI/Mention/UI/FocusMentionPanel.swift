//
//  FocusMention.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/8.
//

import UIKit
import Foundation
import LarkMention
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkContainer
import UniverseDesignActionPanel
import RustPB

final class FocusMentionPanel: UDActionPanel {    

    var mentionVC: FocusMentionViewController

    weak var delegate: MentionPanelDelegate?

    private var disposeBag = DisposeBag()

    init(mentionVC: FocusMentionViewController) {
        self.mentionVC = mentionVC
        var config = UDActionPanelUIConfig()
        config.originY = UIScreen.main.bounds.height * 0.2
        config.canBeDragged = true
        config.showIcon = true
        super.init(customViewController: mentionVC, config: config)
        self.view.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 展示
    func show(from vc: UIViewController) {
        mentionVC.delegate = delegate
        vc.present(self, animated: true)
    }
}
