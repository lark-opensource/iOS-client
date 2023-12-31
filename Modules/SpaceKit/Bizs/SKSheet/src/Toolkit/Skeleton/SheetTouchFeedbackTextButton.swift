//
// Created by duanxiaochen.7 on 2021/9/16.
// Affiliated with SKSheet.
//
// Description:

import SKUIKit
import RxSwift
import UniverseDesignColor

class SheetTouchFeedbackTextButton: UIButton {
    let normalBg = UIColor.clear
    let selectBg = UIColor.ud.fillPressed
    let tapCallback: () -> Void
    var disposeBag = DisposeBag()

    init(onTap: @escaping () -> Void) {
        tapCallback = onTap
        super.init(frame: .zero)
        backgroundColor = normalBg
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.ud.setBorderColor(UDColor.N400)
        layer.masksToBounds = true
        setTitle("", withFontSize: 16, fontWeight: .regular, color: UDColor.textTitle, forState: [.normal])
        setTitle("", withFontSize: 16, fontWeight: .regular, color: UDColor.textDisabled, forState: [.disabled])
        addTarget(self, action: #selector(didReceiveTouchDown), for: .touchDown)
        addTarget(self, action: #selector(didReceiveTouchUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(didReceiveTouchUpOutside), for: .touchUpOutside)
        addTarget(self, action: #selector(didReceiveTouchUpOutside), for: .touchCancel)
        docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didReceiveTouchDown() {
        showFeedbackBackground(true)
    }

    @objc
    func didReceiveTouchUpOutside() {
        showFeedbackBackground(false)
    }

    @objc
    func didReceiveTouchUpInside() {
        showFeedbackBackground(false)
        tapCallback()
    }

    func showFeedbackBackground(_ show: Bool) {
        backgroundColor = show ? selectBg : normalBg
    }
}
