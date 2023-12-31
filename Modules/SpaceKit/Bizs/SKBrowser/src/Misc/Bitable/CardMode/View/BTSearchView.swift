//
//  BTSearchBar.swift
//  DocsSDK
//
//  Created by Gill on 2020/3/26.
//

import UIKit
import SnapKit
import SKUIKit
import LarkInteraction
import RxCocoa
import RxSwift
import RxRelay
import SKCommon
import SKResource
import UniverseDesignColor

public final class BTSearchView: UIView {

    private let disposeBag = DisposeBag()

    public let searchTextField = SKSearchUITextField()

    private var showRightButtonConstraint: Constraint!

    private var hideRightButtonConstraint: Constraint!

    public let rightButton = UIButton()
    
    public var shouldShowRightBtn: Bool = true

    private let diposeBag = DisposeBag()

    public init(placeholderText: String = BundleI18n.SKResource.Doc_Facade_Search,
                shouldShowRightBtn: Bool = true,
                rightButtonText: String = BundleI18n.SKResource.Bitable_Common_ButtonCancel) {
        super.init(frame: .zero)
        backgroundColor = UDColor.bgFloat
        self.shouldShowRightBtn = shouldShowRightBtn

        searchTextField.initialPlaceHolder = placeholderText
        searchTextField.returnKeyType = .search
        searchTextField.setContentCompressionResistancePriority(.defaultHigh - 1, for: .horizontal)
        searchTextField.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)


        rightButton.setTitle(rightButtonText, for: .normal)
        rightButton.titleLabel?.font = .systemFont(ofSize: 16)
        rightButton.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        rightButton.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        rightButton.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)

        addSubview(rightButton)
        addSubview(searchTextField)

        searchTextField.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            hideRightButtonConstraint = make.right.equalToSuperview().offset(-16).constraint
            hideRightButtonConstraint.deactivate()
            showRightButtonConstraint = make.right.equalTo(rightButton.snp.left).offset(-12).constraint
            showRightButtonConstraint.deactivate()
        }
        rightButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }

        hideRightButton(animated: false)

        searchTextField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                self?.showRightButton(animated: true)
            })
            .disposed(by: disposeBag)
        rightButton.rx.tap.asSignal()
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                self.searchTextField.text = nil
                self.searchTextField.endEditing(true)
                self.hideRightButton(animated: true)
            })
            .disposed(by: disposeBag)

        if #available(iOS 13.4, *) {
            func expand(size: CGSize) -> CGSize {
                var size = size
                size.width += 8
                size.height += 6
                return size
            }

            if rightButton.lkPointerStyle == nil {
                let rightButtonSize = expand(size: rightButton.frame.size)
                rightButton.lkPointerStyle = PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (rightButtonSize, 8)
                    })
                )
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showRightButton(animated: Bool = true) {
        guard shouldShowRightBtn else {
            return
        }
        UIView.animate(withDuration: animated ? 0.15 : 0) { [self] in
            hideRightButtonConstraint.deactivate()
            showRightButtonConstraint.activate()
            rightButton.alpha = 1
            layoutIfNeeded()
        }
    }

    public func hideRightButton(animated: Bool = true) {
        guard shouldShowRightBtn else {
            return
        }
        UIView.animate(withDuration: animated ? 0.15 : 0) { [self] in
            showRightButtonConstraint.deactivate()
            hideRightButtonConstraint.activate()
            rightButton.alpha = 0
            layoutIfNeeded()
        }
    }
}
