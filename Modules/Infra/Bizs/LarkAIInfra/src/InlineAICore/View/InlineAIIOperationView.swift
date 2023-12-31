//
//  InlineAIIOperationView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/25.
//  


import UIKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme

final class InlineAIIOperationView: InlineAIItemBaseView {

    var containerView = UIScrollView()
    
    private var buttons: [UIButton] = []
    
    private var cacheButtons: [UIButton] = []
    
    var operates: [InlineAIPanelModel.Operate] = []
    
    var disposeBag = DisposeBag()
    
    override var show: Bool {
        didSet {
            if !self.show {
                self.containerView.setContentOffset(CGPoint(x: -self.containerView.contentInset.left, y: 0), animated: false)
            }
        }
    }
    struct Metric {
        static let containerHeight: CGFloat = 50
        static let buttonHeight: CGFloat = 36
        static let buttonFont = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        static let bottomMargin: CGFloat = 10
        static let topMargin: CGFloat = 4
        static let buttonTextMargin: CGFloat = 16
    }

    private lazy var gradientShadow: InlineAIGradientView = {
        let gradientView = InlineAIGradientView(direction: .horizental, colors: [UDColor.bgFloat.withAlphaComponent(0.00), UDColor.bgFloat.withAlphaComponent(1)])
        gradientView.isHidden = true
        return gradientView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getOperationViewHieght() -> CGFloat {
        return Metric.containerHeight
    }
    
    override func didDismissCompletion() {
         super.didPresentCompletion()
         self.containerView.setContentOffset(.zero, animated: false)
    }
    
    func setupInit() {
        containerView.showsHorizontalScrollIndicator = false
        containerView.showsVerticalScrollIndicator = false
        containerView.delegate = self
        containerView.contentInset = .init(top: 0, left: 10, bottom: 0, right: 0)
        addSubview(containerView)
        addSubview(gradientShadow)
    }
    
    func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
            make.height.equalTo(Metric.containerHeight)
        }
        
        gradientShadow.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(32)
        }
    }
    
    private func generateButton() -> UIButton {
        if let btn = cacheButtons.popLast() {
            return btn
        }
        let button = UIButton()
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.titleLabel?.font = Metric.buttonFont
        button.clipsToBounds = true
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        return button
    }


    private func removeSuffixButton(count: Int) {
        guard buttons.count >= count else {
            LarkInlineAILogger.error("remove count:\(count) greater than buttonsCount:\(buttons.count)")
            return
        }
        
        var needRemoveCount = count
        while needRemoveCount > 0 {
            let btn = buttons.removeLast()
            btn.removeFromSuperview()
            cacheButtons.append(btn)
            needRemoveCount -= 1
        }
    }
    
    private func _update(operates: InlineAIPanelModel.Operates) {
        guard buttons.count > 0, buttons.count == operates.data.count else {
            LarkInlineAILogger.error("buttons count:\(buttons.count) operates count:\(operates.data.count)")
            return
        }
        var preBtn = buttons[0]
        for (idx, tuple) in Array(zip(buttons, operates.data)).enumerated() {
            let button = tuple.0
            let model = tuple.1
            let isPrimary = model.btnTypeEnum == .primary
            let isEnable = !(model.disabled ?? false)
            button.isEnabled = isEnable
            button.setTitle(model.text, for: .normal)
            button.rx.tap.subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.eventRelay.accept(.chooseOperator(operate: model))
            }).disposed(by: disposeBag)
//            if !isPrimary {
//                button.rx.isHighlighted
//                       .subscribe(onNext: { [weak button] (isHighlighted) in
//                           guard let btn = button else { return }
//                           if isHighlighted, let color = UDColor.AIDynamicLine(ofSize: btn.bounds.size) {
//                               btn.ud.setLayerBorderColor(color)
//                           } else {
//                               btn.ud.setLayerBorderColor(UDColor.lineBorderComponent)
//                           }
//                       }).disposed(by: self.disposeBag)
//            }

            let width = model.text.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 36), options: [], attributes: [NSAttributedString.Key.font: Metric.buttonFont], context: nil).size.width + Metric.buttonTextMargin * 2
            button.setButtonStyle(isGradient: isPrimary,
                                  bounds: CGRect(origin: .zero, size: CGSize(width: width, height: 36)),
                                  xMargin: Metric.buttonTextMargin)
            if idx == 0 {
                button.snp.remakeConstraints { make in
                    make.bottom.equalToSuperview().inset(Metric.bottomMargin)
                    make.top.equalToSuperview().inset(Metric.topMargin)
                    make.width.equalTo(width)
                    make.height.equalTo(Metric.buttonHeight)
                    make.left.equalToSuperview().offset(0.5)
                }
            } else if idx == buttons.count - 1 {
                button.snp.remakeConstraints { make in
                    make.bottom.equalTo(preBtn)
                    make.top.equalTo(preBtn)
                    make.width.equalTo(width)
                    make.height.equalTo(Metric.buttonHeight)
                    make.left.equalTo(preBtn.snp.right).offset(8)
                    make.right.equalToSuperview().offset(-12)
                }
            } else {
                button.snp.remakeConstraints { make in
                    make.bottom.equalTo(preBtn)
                    make.top.equalTo(preBtn)
                    make.width.equalTo(width)
                    make.height.equalTo(Metric.buttonHeight)
                    make.left.equalTo(preBtn.snp.right).offset(8)
                }
            }
            preBtn = button
        }
//        bringSubviewToFront(gradientShadow)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
//            guard let self = self else { return }
//            self.gradientShadow.isHidden = self.containerView.contentSize.width <= self.containerView.frame.width
//        }
    }
}

extension InlineAIIOperationView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let width = self.containerView.frame.width
//        let delta = self.containerView.contentSize.width - width
//        let offsetRemain = self.containerView.contentSize.width - width - scrollView.contentOffset.x
//        let deviation: CGFloat = 1
//        if offsetRemain < deviation  {
//            self.gradientShadow.isHidden = true
//        } else {
//            self.gradientShadow.isHidden = delta <= 0
//        }
    }
}

extension InlineAIIOperationView {
    
    func update(operates: InlineAIPanelModel.Operates?) {
        guard let operates = operates else { return }
        disposeBag = DisposeBag() // 重制点击事件
        var count = operates.data.count - buttons.count
        self.operates = operates.data
        if count > 0 {
            while count > 0 {
                let btn = generateButton()
                containerView.addSubview(btn)
                buttons.append(btn)
                count -= 1
            }
        } else if count < 0 {
            removeSuffixButton(count: -count)
        }
        LarkInlineAILogger.info("update operates count:\(operates.data.count)")
        _update(operates: operates)
    }
    
}

extension Reactive where Base: UIButton {
    var isHighlighted: Observable<Bool> {
        let anyObservable = self.base.rx.methodInvoked(#selector(setter: self.base.isHighlighted))
        let boolObservable = anyObservable
            .flatMap { Observable.from(optional: $0.first as? Bool) }
            .startWith(self.base.isHighlighted)
            .distinctUntilChanged()
            .share()

        return boolObservable
    }
}
