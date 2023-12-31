//
//  swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/8.
//

import Foundation

let entryViewSize: CGFloat = 58
let screenHeight = UIScreen.main.bounds.height
let screenWidth = UIScreen.main.bounds.width

class AudioSessionDebugEntryView: UIWindow {

    static let defaultPosition = CGPoint(x: 0, y: screenWidth / 3)

    lazy var entryBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.backgroundColor = UIColor.green
        button.setTitle("🔔", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(entryClick), for: .touchUpInside)
        return button
    }()

    lazy var pan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        return pan
    }()

    init(startPosition: CGPoint = AudioSessionDebugEntryView.defaultPosition) {
        let defaultPosition = AudioSessionDebugEntryView.defaultPosition
        var x = startPosition.x
        var y = startPosition.y
        if (x < 0 || x > (screenWidth - entryViewSize)) {
            x = defaultPosition.x
        }

        if (y < 0 || y > (screenHeight - entryViewSize)) {
            y = defaultPosition.y
        }
        super.init(frame: CGRect(x: x, y: y, width: entryViewSize, height: entryViewSize))
#if swift(>=5.1)
        if #available(iOS 13.0, *) {
            for windowScene in UIApplication.shared.connectedScenes {
                if windowScene.activationState == .foregroundActive {
                    self.windowScene = windowScene as? UIWindowScene
                    break
                }
            }
        }
#endif
        self.backgroundColor = .clear
        self.windowLevel = UIWindow.Level.statusBar + 100
        self.layer.masksToBounds = true
        let rootVc = UIViewController()
        rootVc.view.addSubview(entryBtn)
        self.rootViewController = rootVc
        self.addGestureRecognizer(pan)
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func entryClick() {
        if AudioSessionDebugHomeWindow.shared.isHidden {
            AudioSessionDebugHomeWindow.shared.show()
        } else {
            AudioSessionDebugHomeWindow.shared.hide()
        }
    }

    @objc
    private func handlePan(_ pan: UIPanGestureRecognizer) {
        let offsetPoint = pan.translation(in: pan.view)
        pan.setTranslation(.zero, in: pan.view)
        guard let panView = pan.view else { return }
        var newX = panView.center.x + offsetPoint.x
        var newY = panView.center.y + offsetPoint.y
        if (newX < entryViewSize / 2) {
            newX = entryViewSize / 2
        }
        if (newX > screenWidth - entryViewSize / 2) {
            newX = screenWidth - entryViewSize / 2;
        }
        if (newY < entryViewSize / 2) {
            newY = entryViewSize / 2
        }
        if (newY > screenHeight - entryViewSize / 2) {
            newY = screenHeight - entryViewSize / 2;
        }
        panView.center = CGPoint(x: newX, y: newY)
    }
}
