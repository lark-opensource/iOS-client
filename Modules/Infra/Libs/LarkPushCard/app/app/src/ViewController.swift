//
//  ViewController.swift
//  LarkPushCardDev
//
//  Created by 白镜吾 on 2022/8/18.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import LarkPushCard
import UniverseDesignButton

// swiftlint:disable all
class ViewController: UIViewController {
    let button = UIButton()
    let addButton = UIButton()
    let thirdButton = UIButton()
    let customButton = UIButton()
    var label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.B100

        self.view.addSubview(button)
        self.view.addSubview(addButton)
        self.view.addSubview(thirdButton)
        self.view.addSubview(customButton)

        button.backgroundColor = .blue
        button.setTitle("UrgentView", for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(urgentClick(_:)), for: .touchUpInside)

        addButton.backgroundColor = .blue
        addButton.setTitle("RingView", for: .normal)
        addButton.addTarget(self, action: #selector(RingClick(_:)), for: .touchUpInside)
        addButton.layer.cornerRadius = 10

        thirdButton.backgroundColor = .blue
        thirdButton.setTitle("CalendarPromptView", for: .normal)
        thirdButton.layer.cornerRadius = 10
//        thirdButton.addTarget(self, action: #selector(CalendarPromptViewClick(_:)), for: .touchUpInside)

        customButton.backgroundColor = .blue
        customButton.setTitle("customView", for: .normal)
        customButton.layer.cornerRadius = 10
        customButton.addTarget(self, action: #selector(clickCustomButton(_:)), for: .touchUpInside)

        customButton.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(button.snp.top).offset(-16)
        }

        button.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(addButton.snp.top).offset(-16)
        }

        addButton.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(thirdButton.snp.top).offset(-16)
        }

        thirdButton.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-32)
        }

    }

    @objc
    func urgentClick(_ sender: UIButton) {
        let button1 = CardButtonConfig(title: "Wait", buttonColorType: .secondary) { model in
            PushCardCenter.shared.remove(with: model.id)
        }
        let button2 = CardButtonConfig(title: "Open", buttonColorType: .primaryBlue) { model in
            PushCardCenter.shared.remove(with: model.id)
            PushCardCenter.shared.post(model)
        }

        let id = UUID().uuidString
        let model = UrgentModel(id: id,
                                priority: .normal,
                                title: nil,
                                buttonConfigs: [button1, button2],
                                icon: nil,
                                customView: UrgencyCustomView(id: id),
                                duration: nil,
                                bodyTapHandler: { model in
//            PushCardCenter.shared.remove(with: model.id, changeToStack: true)
//            self.view.backgroundColor = .red
        },
                                removeHandler: nil,
                                extraParams: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            PushCardCenter.shared.post(model)
        })
    }

    @objc
    func RingClick(_ sender: UIButton) {
        var id = UUID().uuidString
        let model = MockModel(id: id,
                              priority: .high,
                              title: nil,
                              buttonConfigs: nil,
                              icon: nil,
                              customView: RingView(id: id),
                              duration: nil,
                              bodyTapHandler: nil,
                              removeHandler: nil,
                              extraParams: nil)
        PushCardCenter.shared.post(model)
    }

//    @objc
//    func CalendarPromptViewClick(_ sender: UIButton) {
//
//        let model = MockModel(id: UUID().uuidString,
//                              title: nil,
//                              buttonConfigs: nil,
//                              icon: nil,
//                              customView: CalendarPromptView(),
//                              duration: 5,
//                              bodyTapHandler: nil,
//                              removeHandler: nil,
//                              extraParams: nil)
//        PushCardCenter.shared.post(model)
//    }

    @objc
    func clickCustomButton(_ sender: UIButton) {


        let startTime = CFAbsoluteTimeGetCurrent()
        var models: [Cardable] = []
        for i in 0..<1 {
            let button1 = CardButtonConfig(title: "Wait", buttonColorType: .secondary) { model in
                PushCardCenter.shared.remove(with: model.id)
            }
            let button2 = CardButtonConfig(title: "Open", buttonColorType: .primaryBlue) { model in
                PushCardCenter.shared.remove(with: model.id)
                PushCardCenter.shared.post(model)
            }

            let id = UUID().uuidString
            let model = MockModel(id: id,
                                  priority: .normal,
                                  title: "\(i)",
                                  buttonConfigs: [button1, button2],
                                  icon: nil,
                                  customView: UrgencyCustomView(id: id),
                                  duration: nil,
                                  bodyTapHandler: { model in
//                PushCardCenter.shared.remove(with: model.id, changeToStack: true)
//                self.view.backgroundColor = .red
            },
                                  removeHandler: nil,
                                  extraParams: nil)

            models.append(model)
        }
        PushCardCenter.shared.post(models)
        let endTime = CFAbsoluteTimeGetCurrent()
    }
}

struct UrgentModel: Cardable {

    var id: String

    var priority: LarkPushCard.CardPriority = .normal

    var title: String?

    var buttonConfigs: [LarkPushCard.CardButtonConfig]?

    var icon: UIImage?

    var customView: UIView?

    var duration: TimeInterval?

    var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?

    var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)? = nil

    var removeHandler: ((LarkPushCard.Cardable) -> Void)?

    var extraParams: Any?

    func calculateCardHeight(with width: CGFloat) -> CGFloat? {
        return max(UrgencyCustomView.heightOfContent("sdksldjasl", width: width) + 28, 46)
    }
}

struct MockModel: Cardable {

    var id: String

    var priority: LarkPushCard.CardPriority = .normal

    var title: String?

    var buttonConfigs: [LarkPushCard.CardButtonConfig]?

    var icon: UIImage?

    var customView: UIView?

    var duration: TimeInterval?

    var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?

    var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)? = nil

    var removeHandler: ((LarkPushCard.Cardable) -> Void)?

    var extraParams: Any?
}
