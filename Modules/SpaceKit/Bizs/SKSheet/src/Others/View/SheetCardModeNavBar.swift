//
// Created by duanxiaochen.7 on 2019/9/22.
// Affiliated with SpaceKit.
//
// Description: sheet 进入卡片模式之后的导航栏+状态栏

import UIKit
import RxSwift
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKFoundation

class SheetCardModeNavBar: UIView {
    var exitButton: UIButton?
    var rightButtons: [UIButton] = []
    var leftButtons: [UIButton] = []

    lazy var titleLabel = UILabel(frame: .zero).construct { it in
        it.textColor = UDColor.textTitle
        it.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        it.lineBreakMode = .byTruncatingTail
        it.textAlignment = .center
    }

    private lazy var leftStackView = UIStackView(frame: .zero).construct { it in
        it.axis = .horizontal
        it.distribution = .equalSpacing
        it.alignment = .center
        it.spacing = 20
    }

    private lazy var rightStackView = UIStackView(frame: .zero).construct { it in
        it.axis = .horizontal
        it.distribution = .equalSpacing
        it.alignment = .center
        it.spacing = 20
    }

    let disposeBag = DisposeBag()

    // MARK: - intercept pop gesture
    weak var previousGestureDelegate: UIGestureRecognizerDelegate?
    var interactivePopGestureRecognizer: UIGestureRecognizer?

    init(backgroundColor: UIColor) {
        super.init(frame: .zero)
        self.backgroundColor = backgroundColor

        addSubview(leftStackView)
        leftStackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        addSubview(rightStackView)
        rightStackView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(leftStackView.snp.right).offset(16)
            make.right.lessThanOrEqualTo(rightStackView.snp.left).offset(-16)
            make.center.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    func setup(info: SheetCardModeNavBarService.NaviInfo, bgColor: UIColor) {
        titleLabel.text = info.title
        setupButtons(menus: info.leftMenus, stackView: leftStackView, callback: info.callback)
        setupButtons(menus: info.rightMenus, stackView: rightStackView, callback: info.callback)
        backgroundColor = bgColor
        exitButton = leftStackView.arrangedSubviews.first as? UIButton

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupButtons(menus: [SheetCardModeNavBarService.MenuInfo], stackView: UIStackView, callback: @escaping (String) -> Void) {
        stackView.subviews.forEach { $0.removeFromSuperview() }

        for menuInfo in menus {
            let button = UIButton(type: .custom).construct { it in
                let image = UDIcon.getIconByKey(menuInfo.imageID)
                it.setImage(image, withColorsForStates: [
                    (UDColor.iconN1, .normal), (UDColor.primaryContentDefault, .selected),
                    (UDColor.iconN3, .highlighted), (UDColor.primaryContentLoading, UIControl.State.selected.union(.highlighted)),
                    (UDColor.iconDisabled, .disabled)
                ])
                it.rx.tap
                    .subscribe(onNext: { _ in
                        callback(menuInfo.id)
                    })
                    .disposed(by: disposeBag)
                it.contentVerticalAlignment = .fill
                it.contentHorizontalAlignment = .fill
            }

            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { (make) in
                make.width.height.equalTo(24)
            }
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopInterceptPopGesture()
    }
}

extension SheetCardModeNavBar: UIGestureRecognizerDelegate {

    func startInterceptPopGesture(gesture: UIGestureRecognizer?) {
        if gesture?.delegate !== self {
            previousGestureDelegate = gesture?.delegate
            gesture?.delegate = self
            self.interactivePopGestureRecognizer = gesture
            DocsLogger.info("SheetCardModeNavBar -- add naviPopGestureDelegate")
        }
    }

    func stopInterceptPopGesture() {
        DocsLogger.info("SheetCardModeNavBar -- remove naviPopGestureDelegate previousGestureDelegate's nil is \(previousGestureDelegate == nil)")
        interactivePopGestureRecognizer?.delegate = previousGestureDelegate
        interactivePopGestureRecognizer = nil
        previousGestureDelegate = nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        exitButton?.sendActions(for: .touchUpInside)
        return false
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }

}
