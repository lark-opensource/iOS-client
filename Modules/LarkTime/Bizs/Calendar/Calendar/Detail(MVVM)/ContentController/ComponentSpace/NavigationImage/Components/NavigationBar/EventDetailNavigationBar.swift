//
//  EventDetailNavigationBar.swift
//  Calendar
//
//  Created by Rico on 2021/3/17.
//

import Foundation
import UIKit
import LarkInteraction
import CalendarFoundation
import UniverseDesignIcon
import RxCocoa
import RxSwift
import UniverseDesignColor

protocol EventDetailNavigationBarViewDataType {
    var textColor: UIColor { get }
    var cornerImage: UIImage? { get }
    var hasMoreButton: Bool { get }
    var hasUndecrpytDeleteButton: Bool { get }
    var titleText: String { get }
    var shareButtonStyle: EventDetailNavigationBar.ShareButtonStyle { get }
    var editButtonStyle: EventDetailNavigationBar.EditButtonStyle { get }
}

/**
 高度是 EventDetail.navigationBarHeight，布局顶部是屏幕的顶部
 */
final class EventDetailNavigationBar: UIView, ViewDataReceiver {

    enum EditButtonStyle {
        case normal
        case disabled
        case none
    }

    enum PresentStyle {
        case present
        case push
    }

    enum NavigationTappedType {
        case close
        case share
        case edit
        case delete
        case more
    }

    enum ShareButtonStyle {
        case hidden
        case shareable
        case forbidden(String)  // toast message
    }

    private let disposeBag = DisposeBag()

    private var backButton = UIButton.cd.button(type: .custom)

    typealias NavigationTappedAction = (NavigationTappedType) -> Void

    var tappedAction: NavigationTappedAction?

    var toastAction: ((String) -> Void)?

    private var viewData: EventDetailNavigationBarViewDataType?

    func update(viewData: EventDetailNavigationBarViewDataType) {
        self.viewData = viewData

        self.moreButton.isHidden = !viewData.hasMoreButton
        self.deleteButton.isHidden = !viewData.hasUndecrpytDeleteButton

        self.titleLabel.textColor = viewData.textColor
        self.titleLabel.text = viewData.titleText
        self.titleLabel.tryFitFoFigmaLineHeight()
        let editButtonStyle = viewData.editButtonStyle

        switch viewData.shareButtonStyle {
        case .hidden:
            self.shareButton.isHidden = true
        case .shareable:
            self.shareButton.isHidden = false
            self.shareButton.alpha = 1
        case .forbidden:
            self.shareButton.isHidden = false
            self.shareButton.alpha = 0.4
        }

        switch editButtonStyle {
        case .none:
            self.editButton.isHidden = true
        case .normal:
            self.editButton.isHidden = false
            self.editButton.alpha = 1
        case .disabled:
            self.editButton.isHidden = false
            self.editButton.alpha = 0.4
        }
        updateCornerImageView(viewData: viewData)
    }

    var presentStyle: PresentStyle = .push {
        didSet {
            var image: UIImage
            switch presentStyle {
            case .present: image = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1)
            case .push: image = UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1)
            }
            backButton.setImage(image, for: .normal)
        }
    }

    private let stackView = UIStackView()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        layoutUI()
        bindViewAction()
    }

    private func layoutUI() {

        self.addSubview(backButton)
        self.addSubview(stackView)
        self.addSubview(cornerImageView)
        self.addSubview(titleLabel)

        // 以 backButton 为基准，底部距离 superview 底部 18
        backButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24).priority(.high)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(16)
        }

        let items: [UIButton] = [moreButton, editButton, deleteButton, shareButton]
        stackView.axis = .horizontal
        stackView.spacing = 24
        stackView.distribution = .fill
        stackView.snp.makeConstraints { (make) in
            make.centerY.equalTo(backButton)
            make.right.equalToSuperview().offset(-16)
        }
        items.forEach { stackView.insertArrangedSubview($0, at: 0) }

        stackView.insertArrangedSubview(cornerImageView, at: 0)

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(backButton)
            make.left.equalTo(backButton.snp.right).offset(12)
            make.right.equalTo(stackView.snp.left).offset(-24)
        }

        self.transformUI(with: 0.0)

        let buttons: [UIButton] = [backButton, editButton, shareButton, deleteButton, moreButton]
        buttons.forEach { button in
            button.tintColor = UDColor.iconN1
            if #available(iOS 13.4, *) {
                button.lkPointerStyle = PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (CGSize(width: 44, height: 36), 8)
                }))
            }
        }
    }

    private func updateCornerImageView(viewData: EventDetailNavigationBarViewDataType) {
        if let image = viewData.cornerImage {
            self.cornerImageView.isHidden = false
            self.cornerImageView.image = image
        } else {
            self.cornerImageView.isHidden = true
        }
    }

    private func bindViewAction() {
        backButton.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            self?.tappedAction?(.close)
        }).disposed(by: disposeBag)

        moreButton.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            self?.tappedAction?(.more)
        }).disposed(by: disposeBag)

        deleteButton.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            self?.tappedAction?(.delete)
        }).disposed(by: disposeBag)

        editButton.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            self?.tappedAction?(.edit)
        }).disposed(by: disposeBag)

        shareButton.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            if let shareButtonStyle = self?.viewData?.shareButtonStyle {
                if case let .forbidden(message) = shareButtonStyle {
                    self?.toastAction?(message)
                    return
                }
            }
            self?.tappedAction?(.share)
        }).disposed(by: disposeBag)
    }

    private func createItemButton(with image: UIImage) -> UIButton {
        let btn = UIButton.cd.button(type: .custom)
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        btn.setImage(image, for: .normal)
        return btn
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let cornerImageView: UIImageView = {
        let imgview = UIImageView()
        imgview.isHidden = true
        imgview.contentMode = .center
        imgview.setContentHuggingPriority(.required, for: .horizontal)
        return imgview
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title3(.fixed)
        label.textColor = UDColor.primaryPri700
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private(set) lazy var editButton: UIButton = {
        return self.createItemButton(with: UDIcon.getIconByKeyNoLimitSize(.editOutlined).scaleNaviSize().renderColor(with: .n1))
    }()

    private(set) lazy var shareButton: UIButton = {
        return self.createItemButton(with: UDIcon.getIconByKeyNoLimitSize(.shareOutlined).scaleNaviSize().renderColor(with: .n1))
    }()

    private(set) lazy var moreButton: UIButton = {
        return self.createItemButton(with: UDIcon.getIconByKeyNoLimitSize(.moreOutlined).scaleNaviSize().renderColor(with: .n1))
    }()

    private(set) lazy var deleteButton: UIButton = {
        return self.createItemButton(with: UDIcon.getIconByKeyNoLimitSize(.deleteTrashOutlined).scaleNaviSize().renderColor(with: .n1))
    }()
}

extension EventDetailNavigationBar {
    func transformUI(with progress: CGFloat) {
        let preAlpha = self.titleLabel.alpha
        let textAlpha: CGFloat
        if progress > 2.0 {
            textAlpha = 1.0
        } else if progress < 1.0 {
            textAlpha = .zero
        } else {
            textAlpha = progress - 1.0
        }
        self.titleLabel.alpha = textAlpha
        if preAlpha != textAlpha,
           [preAlpha, textAlpha].contains(.zero),
           let viewData = viewData {
            updateCornerImageView(viewData: viewData)
        }
    }
}
