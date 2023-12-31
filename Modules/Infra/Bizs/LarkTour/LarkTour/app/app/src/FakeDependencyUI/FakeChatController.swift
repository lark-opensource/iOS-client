//
//  FakeChatController.swift
//  LarkTourDev
//
//  Created by Meng on 2020/6/19.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import LarkTourInterface

class FakeChatController: FakeDependencyController {
    @Provider private var chatGuideService: TourChatGuideService

    private let chatId: String
    private let chatInputView = UILabel(frame: .zero)

    override var description: String {
        return "假装你进入了一个Chat"
    }

    init(chatId: String) {
        self.chatId = chatId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = "FakeChatController"

        view.addSubview(chatInputView)
        chatInputView.text = "Send Message to xxx"
        if #available(iOS 13.0, *) {
            chatInputView.textColor = .label
        } else {
            chatInputView.textColor = .black
        }
        chatInputView.backgroundColor = Colors.random()
        chatInputView.textAlignment = .center
        chatInputView.clipsToBounds = true
        chatInputView.layer.borderWidth = 1.0
        chatInputView.layer.borderColor = UIColor.lightGray.cgColor
        chatInputView.layer.cornerRadius = 16.0
        chatInputView.layer.shadowOffset = CGSize(width: 10.0, height: 10.0)
        chatInputView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(36.0)
            make.height.equalTo(46.0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        isNavigationBarHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if chatGuideService.needShowChatUserGuide(for: chatId) {
            let rect = chatInputView.convert(chatInputView.bounds, to: nil)
            let targetRect = CGRect(
                rect.minX + 16.0, rect.minY + 10.0,
                70.0, 24.0
            )
            chatGuideService.showChatUserGuideIfNeeded(with: chatId, on: targetRect, completion: nil)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = true
        isNavigationBarHidden = true
    }
}
