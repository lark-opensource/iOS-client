//
//  FullScreenGuideView.swift
//  ByteView
//
//  Created by ZhangJi on 2022/9/27.
//

import Foundation
import SnapKit
import ByteViewSetting

class FullScreenGuideView: UIView {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: BundleResources.ByteView.Meet.guide_click)
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_HideAccessToolbar
        label.textColor = .white
        label.font = .systemFont(ofSize: 17.0, weight: .medium)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgMask
        self.addSubview(imageView)
        self.addSubview(textLabel)

        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(120)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-18)
        }

        textLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).inset(-12)
        }
    }
}

class UIShortTapGestureRecognizer: UITapGestureRecognizer {
    var autoHideToolbarConfig: AutoHideToolbarConfig = .default

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(autoHideToolbarConfig.doubleTapTimeout) / 1000) { [weak self] in
            if self?.state != .ended {
                self?.state = .failed
            }
        }
    }
}

class UIFullScreenGestureRecognizer: UITapGestureRecognizer {
    static var whiteListClass: [AnyClass] = [UIControl.self, InMeetNavigationBar.self, InMeetShareScreenBottomView.self, WhiteboardBottomView.self]

    var eventHandled = false

    override func reset() {
        eventHandled = false
        super.reset()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            var view = touch.view
            while view != nil {
                if Self.whiteListClass.contains(where: { view!.isKind(of: $0) }) {
                    self.eventHandled = true
                    return
                }

                view = view?.superview
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if !eventHandled {
            self.eventHandled = true
            self.state = .ended
        } else {
            self.state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.eventHandled = true
        self.state = .failed
    }
}
