//
//  TipViewController.swift
//  MailSDK
//
//  Created by majx on 2019/12/13.
//

import Foundation
import EENavigator

class TipViewController: UIViewController {
    var tipView: TipView?
    var forView: UIView?
    private let navigator: Navigatable

    init(text: String, forView: UIView, navigator: Navigatable) {
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.forView = forView

        var preferences = TipView.globalPreferences
        preferences.drawing.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        preferences.drawing.foregroundColor = .white
        preferences.drawing.cornerRadius = 20
        preferences.drawing.arrowPosition = .bottom
        preferences.drawing.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        preferences.positioning.maxWidth = CGFloat(Display.width * 0.7)
        preferences.positioning.bubbleHInset = 16
        preferences.positioning.contentVInset = 11

        preferences.animating.dismissFinalAlpha = 0.0
        preferences.animating.dismissTransform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        preferences.animating.dismissDuration = 0.2
        preferences.animating.showDuration = 0.2
        preferences.animating.springDamping = 0.8
        preferences.animating.springVelocity = 0.8

        self.tipView = TipView(text: text, preferences: preferences, delegate: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(fromVC: UIViewController) {
        navigator.present(self, wrap: nil, from: fromVC, prepare: nil, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundHandler))
        self.view.addGestureRecognizer(tap)
        self.view.isUserInteractionEnabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let forView = forView {
            tipView?.show(animated: true, forView: forView, mainSceneWindow: navigator.mainSceneWindow, withinSuperview: self.view)
        }
    }

    @objc
    private func tapBackgroundHandler() {
        tipView?.dismiss(withCompletion: {
            self.dismiss(animated: false, completion: nil)
        })
    }
}

extension TipViewController: TipViewDelegate {
    func tipViewDidDismiss(_ tipView: TipView) {

    }
}
