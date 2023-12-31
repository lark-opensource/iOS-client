//
//  SheetColumnSwitchView.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/27.
//

import Foundation
import SKCommon
import SKResource
import RxSwift

protocol SheetColumnSwitchViewDelegate: AnyObject {
    func didRequestTo(index: Int, view: SheetColumnSwitchView)
}

class SheetColumnSwitchView: UIView {

    weak var delegate: SheetColumnSwitchViewDelegate?
    
    //当前索引,从1开始
    private var current = 0
    private var total = 0

    lazy var titleLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 16)
        it.textColor = UIColor.ud.textTitle
        it.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
    }

    private lazy var buttonContainer = UIView().construct { it in
        it.backgroundColor = UIColor.ud.lineBorderComponent
        it.layer.cornerRadius = 8
        it.layer.masksToBounds = true
    }
    
    var previousButton = UIButton()
    var nextButton = UIButton()

    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        func makeButton(with title: String) -> UIButton {
            let btn = UIButton()
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(UIColor.ud.textTitle, for: .normal)
            btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
            btn.titleLabel?.textAlignment = .center
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            btn.layer.cornerRadius = 7
            btn.layer.masksToBounds = true
            btn.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
            btn.contentEdgeInsets = UIEdgeInsets(horizontal: 10, vertical: 8)
            btn.backgroundColor = UIColor.ud.bgBody
            btn.addTarget(self, action: #selector(didReceiveTouchDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(didReceiveTouchUpOutside(_:)), for: .touchUpOutside)
            btn.addTarget(self, action: #selector(didReceiveTouchUpOutside(_:)), for: .touchCancel)
            btn.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
            return btn
        }
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor.ud.bgBody

        previousButton = makeButton(with: BundleI18n.SKResource.Doc_Sheet_PreColumn)
        previousButton.layer.maskedCorners = .left
        previousButton.addTarget(self, action: #selector(didPressPreviousButton), for: .touchUpInside)
        nextButton = makeButton(with: BundleI18n.SKResource.Doc_Sheet_NextColumn)
        nextButton.layer.maskedCorners = .right
        nextButton.addTarget(self, action: #selector(didPressNextButton), for: .touchUpInside)

        addSubview(titleLabel)
        addSubview(buttonContainer)
        buttonContainer.addSubview(previousButton)
        buttonContainer.addSubview(nextButton)

        buttonContainer.snp.makeConstraints { (make) in
            make.height.equalTo(32)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        previousButton.snp.makeConstraints { (make) in
            make.top.leading.bottom.equalToSuperview().inset(1)
        }
        
        nextButton.snp.makeConstraints { (make) in
            make.leading.equalTo(previousButton.snp.trailing).offset(1)
            make.width.equalTo(previousButton)
            make.top.trailing.bottom.equalToSuperview().inset(1)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(buttonContainer.snp.leading).inset(16)
            make.centerY.equalToSuperview()
        }

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateIndex(current: Int, total: Int) {
        self.current = current
        self.total = total
        updateButtonIfNeed()
    }

    private func updateButtonIfNeed() {
        if current < 1 || total <= 1 {
            makeButtonDisable(previousButton, disable: true)
            makeButtonDisable(nextButton, disable: true)
            return
        }
        makeButtonDisable(previousButton, disable: current <= 1)
        makeButtonDisable(nextButton, disable: current >= total)
    }

    private func makeButtonDisable(_ button: UIButton, disable: Bool) {
        button.isEnabled = !disable
    }

    @objc
    func didPressPreviousButton() {
        current = max(1, current - 1)
        updateButtonIfNeed()
        delegate?.didRequestTo(index: current, view: self)
        showFeedbackBackground(false, sender: previousButton)
    }

    @objc
    func didPressNextButton() {
        current = min(total, current + 1)
        updateButtonIfNeed()
        delegate?.didRequestTo(index: current, view: self)
        showFeedbackBackground(false, sender: nextButton)
    }
    
    @objc
    func didReceiveTouchDown(_ sender: UIButton) {
        showFeedbackBackground(true, sender: sender)
    }

    @objc
    func didReceiveTouchUpOutside(_ sender: UIButton) {
        showFeedbackBackground(false, sender: sender)
    }

    func showFeedbackBackground(_ show: Bool, sender: UIButton) {
        sender.backgroundColor = show ? UIColor.ud.fillPressed : UIColor.ud.bgBody
    }
}
