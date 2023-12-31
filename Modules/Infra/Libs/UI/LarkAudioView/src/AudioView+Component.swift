//
//  AudioView+Component.swift
//  LarkCore
//
//  Created by 李晨 on 2019/3/8.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignShadow

final class AudioStateView: UIButton {
    enum Status {
        case stop
        case playing
        case loading
    }

    var hitTestExternal: CGFloat = 10

    var status: Status = .stop {
        didSet {
            self.updateStateImage()
        }
    }

    var isValid: Bool = true {
        didSet {
            self.backgroundColor = isValid
                ? colorConfig?.foreground
                : colorConfig?.foreground?.withAlphaComponent(0.3)
        }
    }

    var style: AudioView.Style = .light
    var colorConfig: AudioView.StateColorConfig? {
        didSet {
            updateStateImage()
        }
    }

    let icon: UIImageView = {
        let icon = UIImageView()
        return icon
    }()

    init() {
        super.init(frame: .zero)
        self.addSubview(icon)
        icon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(15)
        }
        self.updateStateImage()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        updateStateImage()
        layer.cornerRadius = bounds.width / 2
    }

    func updateStateImage() {
        self.backgroundColor = isValid
            ? colorConfig?.foreground
            : colorConfig?.foreground?.withAlphaComponent(0.3)
        switch self.status {
        case .stop:
            icon.contentMode = .center
            icon.image = Resources.VoicePause.withRenderingMode(.alwaysTemplate)
            icon.tintColor = colorConfig?.background ?? .white
            self.stopAnimation()
        case .playing:
            icon.contentMode = .center
            icon.image = Resources.voicePlay.withRenderingMode(.alwaysTemplate)
            icon.tintColor = colorConfig?.background ?? .white
            self.stopAnimation()
        case .loading:
            icon.contentMode = .scaleToFill
            icon.image = Resources.voiceTextLoading.withRenderingMode(.alwaysTemplate)
            icon.tintColor = colorConfig?.background ?? .white
            self.startAnimationIfNeeded()
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            return hitView
        }
        let hitFrame = CGRect(
            x: -self.hitTestExternal,
            y: -self.hitTestExternal,
            width: 2 * self.hitTestExternal + self.frame.width,
            height: 2 * self.hitTestExternal + self.frame.height)
        if hitFrame.contains(point) {
            return self
        }
        return nil
    }

    func startAnimationIfNeeded() {
        if self.icon.layer.animation(forKey: "lu.rotateAnimation") == nil {
            self.icon.lu.addRotateAnimation()
        }
    }

    func stopAnimation() {
        self.icon.lu.removeRotateAnimation()
    }
}

final class AudioPanView: UIButton {
    enum PanState {
        case ready
        case play
        case draging
    }

    enum PanStyle {
        case blue
        case white
    }

    var colorConfig: AudioView.PanColorConfig? {
        didSet {
            if let config = colorConfig {
                readyView.backgroundColor = config.background
                playView.backgroundColor = config.background
            } else {
                readyView.backgroundColor = .white
                playView.backgroundColor = .white
            }
            update(panView: panView, style: style)
        }
    }

    var style: AudioPanView.PanStyle = .white {
        didSet {
            if style == .blue {
                panView = getPanView(style: .blue)
            }
        }
    }

    var hitTestExternal: CGFloat = 10

    var panState: PanState = .ready {
        didSet {
            switch panState {
            case .ready:
                self.readyView.isHidden = false
                self.playView.isHidden = true
                self.panView.isHidden = true
            case .play:
                self.readyView.isHidden = true
                self.playView.isHidden = false
                self.panView.isHidden = true
            case .draging:
                self.readyView.isHidden = true
                self.playView.isHidden = true
                self.panView.isHidden = false
            }
        }
    }

    lazy var readyView: UIView = {
        var view = UIView()
        view.backgroundColor = colorConfig?.background ?? UIColor.white
        view.layer.cornerRadius = 8
        view.isUserInteractionEnabled = false
        view.layer.ud.setShadow(type: .s2Down)
        return view
    }()

    lazy var playView: UIView = {
        var view = UIView()
        view.backgroundColor = colorConfig?.background ?? UIColor.white
        view.layer.cornerRadius = 8
        view.isUserInteractionEnabled = false
        view.layer.ud.setShadow(type: .s2Down)
        return view
    }()

    lazy var panView: UIView = {
        return getPanView(style: .white)
    }()

    private(set) var isTouching: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.readyView)
        self.readyView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(16)
            maker.center.equalToSuperview()
        }

        self.addSubview(self.playView)
        self.playView.isHidden = true
        self.playView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(16)
            maker.center.equalToSuperview()
        }

        self.addSubview(self.panView)
        self.panView.isHidden = true
        self.panView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(18)
            maker.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isTouching = true
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isTouching = false
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isTouching = false
        super.touchesCancelled(touches, with: event)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            return hitView
        }
        let hitFrame = CGRect(
            x: -self.hitTestExternal,
            y: -self.hitTestExternal,
            width: 2 * self.hitTestExternal + self.frame.width,
            height: 2 * self.hitTestExternal + self.frame.height)
        if hitFrame.contains(point) {
            return self
        }
        return nil
    }

    private func getPanView(style: AudioPanView.PanStyle) -> UIView {
        let view = UIView()
        update(panView: view, style: style)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 9
        view.isUserInteractionEnabled = false
        view.layer.ud.setShadow(type: .s2Down)
        return view
    }

    private func update(panView: UIView, style: AudioPanView.PanStyle) {
        if style == .blue {
            panView.backgroundColor = colorConfig?.background ?? UIColor.ud.B300
        } else {
            panView.backgroundColor = colorConfig?.background ?? UIColor.ud.primaryOnPrimaryFill
        }
    }
}
