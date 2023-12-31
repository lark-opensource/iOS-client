//
//  BTRatingPanel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/2/17.
//

import Foundation
import RxCocoa
import RxSwift
import RxRelay
import SKCommon
import SKUIKit
import UniverseDesignColor
import SKResource
import UniverseDesignInput
import UniverseDesignIcon

final class BTRatingPanel: UIView {

    weak var delegate: BTRatingPanelDelegate?
    
    private final class Constants {
        static let mainViewFullHeight = 312.0 + 34.0
    }

    lazy var titleView = SKDraggableTitleView().construct { it in
        it.topLine.isHidden = true
        it.rightButton.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonDone, for: .normal)
        it.rightButton.addTarget(self, action: #selector(doneClick), for: .touchUpInside)
        it.leftButton.isHidden = true
    }
    
    lazy var mainView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12.0
        view.layer.maskedCorners = .top
        view.layer.masksToBounds = true
        view.backgroundColor = UDColor.bgFloat
        
        view.addSubview(titleView)
        view.addSubview(ratingView)
        
        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        ratingView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(titleView.snp.bottom).offset(70)
        }
        return view
    }()
    
    lazy var ratingView: BTRatingView = {
        let ratingView = BTRatingView()
        ratingView.delegate = self
        return ratingView
    }()

    init() {
        super.init(frame: .zero)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        layer.ud.setShadowColor(UDColor.shadowDefaultLg)
        layer.shadowOpacity = 1
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: -6)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeClick))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        
        addSubview(mainView)

        mainView.snp.makeConstraints { make in
            make.height.equalTo(Constants.mainViewFullHeight)
            make.right.left.bottom.equalToSuperview()
        }
    }
    
    func show(completion: (() -> Void)? = nil) {
        self.mainView.transform = CGAffineTransformMakeTranslation(0, Constants.mainViewFullHeight)
        UIView.animate(withDuration: 0.25) {
            self.mainView.transform = CGAffineTransformMakeTranslation(0, 0)
        } completion: { [weak self] (completed) in
            if completed { completion?() }
            self?.delegate?.scrollTillFieldVisible()
        }
    }

    func hide(immediately: Bool, clickDone: Bool) {
        if immediately {
            mainView.transform = CGAffineTransformMakeTranslation(0, Constants.mainViewFullHeight)
            self.layoutIfNeeded()
            self.didHide(clickDone: clickDone)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.mainView.transform = CGAffineTransformMakeTranslation(0, Constants.mainViewFullHeight)
                self.backgroundColor = .clear
            } completion: { (completed) in
                if completed {
                    self.didHide(clickDone: clickDone)
                }
            }
        }
    }
    
    private func didHide(clickDone: Bool) {
        removeFromSuperview()
        delegate?.close(self, clickDone: clickDone)
    }
    
    @objc
    private func closeClick() {
        self.hide(immediately: false, clickDone: false)
    }
    
    @objc
    private func doneClick() {
        self.hide(immediately: false, clickDone: true)
    }
}

extension BTRatingPanel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self ? true : false
    }
}

extension BTRatingPanel: BTRatingViewDelegate {
    func ratingValueChanged(rateView: BTRatingView, value: Int?) {
        self.delegate?.ratingValueChanged(self, value: value)
    }
}

protocol BTRatingPanelDelegate: AnyObject {
    func close(_ panel: BTRatingPanel, clickDone: Bool)
    func ratingValueChanged(_ panel: BTRatingPanel, value: Int?)
    func scrollTillFieldVisible()
}
