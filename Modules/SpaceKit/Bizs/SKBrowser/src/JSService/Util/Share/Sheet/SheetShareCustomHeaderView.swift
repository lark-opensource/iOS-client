//
//  SheetShareCustomHeaderView.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/10/23.
//  

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation

enum SheetShareCustomHeaderViewStyle {
    case dark
    case light
}
 
class SheetShareCustomHeaderView: UIView {
    
    var style: SheetShareCustomHeaderViewStyle = .light {
        didSet {
            backgroundColor = UIColor.ud.bgBody
            titleLabel.textColor = UIColor.ud.N1000
            let image = exitImageWhite.ud.withTintColor(UIColor.ud.N1000)
            exitButton.setImage(image, for: .normal)
            exitButton.setImage(image, for: .disabled)
        }
    }

    var exitAction: (() -> Void)?
    let exitImageWhite = UDIcon.closeOutlined
    let exitImageBlack = UDIcon.closeOutlined
    
    lazy var exitButton = UIButton(type: .custom).construct { (it) in
        it.imageView?.image = exitImageBlack
        it.setImage(exitImageBlack, for: .normal)
        it.setImage(exitImageBlack, for: .disabled)
        it.addTarget(self, action: #selector(didClickExit), for: .touchUpInside)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.docs.addStandardHighlight()
    }

    lazy var titleLabel = UILabel(frame: .zero).construct { (it) in
        it.textColor = UIColor.ud.N900
        it.highlightedTextColor = UIColor.ud.colorfulBlue
        it.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
    }

    private lazy var rightStackView = UIStackView(frame: .zero).construct { it in
        it.axis = .horizontal
        it.distribution = .equalSpacing
        it.alignment = .fill
        it.spacing = 20
    }

    var rightButtons: [UIButton] = []
    var leftButtons: [UIButton] = []

    let disposeBag = DisposeBag()

    // MARK: - intercept pop gesture
    weak var previousGestureDelegate: UIGestureRecognizerDelegate?
    var interactivePopGestureRecognizer: UIGestureRecognizer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupConstraints() {
        backgroundColor = UIColor.ud.N00

        addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(exitButton)
        }

        addSubview(rightStackView)
        rightStackView.snp.makeConstraints { (make) in
            make.leading.greaterThanOrEqualTo(titleLabel)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

    }

    public func setup(info: SheetNaviInfo!) {
        //loading状态设置
        if let titleItem = info.titleItem {
            titleLabel.text = titleItem.text
        }

        //按钮设置
        setupButtons(menus: info.rightItem, stackView: rightStackView, itemLength: 24)

        setNeedsLayout()
        layoutIfNeeded()
    }


    fileprivate func setupButtons(menus: [SheetNaviItemInfo], stackView: UIStackView, itemLength: CGFloat) {
        //clear
        let arrangedSubViews = stackView.arrangedSubviews
        for subView in arrangedSubViews {
            subView.removeFromSuperview()
        }

        for menuInfo in menus {
            let button = UIButton(type: .custom).construct { it in
                it.rx.tap
                    .subscribe(onNext: { _ in
                        if let callback = menuInfo.callback {
                            callback()
                        }
                    })
                    .disposed(by: disposeBag)
                it.contentVerticalAlignment = .fill
                it.contentHorizontalAlignment = .fill
            }

            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { (make) in
                make.width.height.equalTo(itemLength)
            }
        }
    }
    
    @objc
    func didClickExit(_ sender: Any) {
        if let action = exitAction {
            action()
        }
    }

    deinit {
        stopInterceptPopGesture()
    }
}

extension SheetShareCustomHeaderView: UIGestureRecognizerDelegate {

    func startInterceptPopGesture(gesture: UIGestureRecognizer?) {
        if gesture?.delegate !== self {
            previousGestureDelegate = gesture?.delegate
            gesture?.delegate = self
            self.interactivePopGestureRecognizer = gesture
            DocsLogger.info("SheetShareHeaderView -- add naviPopGestureDelegate")
        }
    }

    func stopInterceptPopGesture() {
        interactivePopGestureRecognizer?.delegate = previousGestureDelegate
        DocsLogger.info("SheetShareHeaderView -- remove naviPopGestureDelegate previousGestureDelegate's nil is \(previousGestureDelegate == nil)")
        interactivePopGestureRecognizer = nil
        previousGestureDelegate = nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        exitButton.sendActions(for: .touchUpInside)
        return false
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }

}
