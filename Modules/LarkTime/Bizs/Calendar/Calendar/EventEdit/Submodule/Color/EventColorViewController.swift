//
//  EventColorViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/2/24.
//

import UniverseDesignIcon
import LarkUIKit
import UIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkInteraction
import UniverseDesignColorPicker

/// 日程 - Color 编辑页

protocol EventColorViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventColorViewController)
    func didFinishEdit(from viewController: EventColorViewController)
}

final class EventColorViewController: BaseUIViewController {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    weak var delegate: EventColorViewControllerDelegate?
    internal private(set) var selectedColor: ColorIndex

    private let disposeBag = DisposeBag()
    private var colorItemViews: [UIButton] = []
    private let colorsArray = SkinColorHelper.colorsForPicker
    private var headerTitle: String
    private let isShowBack: Bool

    init(selectedColor: ColorIndex, headerTitle: String, isShowBack: Bool) {
        self.selectedColor = selectedColor
        self.headerTitle = headerTitle
        self.isShowBack = isShowBack
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = headerTitle
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        setupNaviItem(isShowBack: isShowBack)
        setupColorItems()
        resetColorSelected()
    }

    private func setupNaviItem(isShowBack: Bool) {
        let naviItem: LKBarButtonItem
        if isShowBack {
            naviItem = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1).withRenderingMode(.alwaysOriginal))
        } else {
            naviItem = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1))
        }
        naviItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = naviItem
    }

    private typealias ColorItem = (index: String, color: UIColor)
    private func setupColorItems() {
        colorItemViews = colorsArray.enumerated().map({ (index, color) in
            let button = UIButton.cd.button(type: .custom)
            button.tag = index
            let image = UIImage.cd.image(
                withColor: color,
                size: CGSize(width: 36, height: 36),
                cornerRadius: 4
            )
            button.setBackgroundImage(image, for: .normal)
            button.setImage(UIImage.cd.image(named: "colorPickerSelect"), for: .selected)
            button.rx.controlEvent(.touchUpInside).bind { [unowned self] in
                guard self.selectedColor.rawValue != index else { return }
                self.selectedColor = .init(rawValue: index) ?? .carmine
                self.resetColorSelected()
                self.delegate?.didFinishEdit(from: self)
            }.disposed(by: disposeBag)
            button.snp.makeConstraints {
                $0.width.height.equalTo(36)
            }
            if #available(iOS 13.4, *) {
                let pointer = PointerInteraction(style: .init(effect: .lift))
                button.addLKInteraction(pointer)
            }
            return button
        })

        let whiteBackgroundView = UIView()
        whiteBackgroundView.layer.cornerRadius = 10
        whiteBackgroundView.layer.masksToBounds = true
        whiteBackgroundView.layer.ud.setBackgroundColor(UIColor.ud.bgFloat)
        view.addSubview(whiteBackgroundView)
        whiteBackgroundView.snp.makeConstraints {
            $0.left.equalTo(20)
            $0.right.equalTo(-20)
            $0.top.equalTo(12)
        }

        let firstStackView = UIStackView(arrangedSubviews: Array(colorItemViews.prefix(colorsArray.count / 2)))
        firstStackView.axis = .horizontal
        firstStackView.alignment = .center
        firstStackView.distribution = .equalSpacing
        firstStackView.isLayoutMarginsRelativeArrangement = true
        whiteBackgroundView.addSubview(firstStackView)
        firstStackView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview()
            $0.height.equalTo(66)
        }

        let secondStackView = UIStackView(arrangedSubviews: Array(colorItemViews.suffix(colorsArray.count / 2)))
        secondStackView.axis = .horizontal
        secondStackView.alignment = .center
        secondStackView.distribution = .equalCentering
        secondStackView.isLayoutMarginsRelativeArrangement = true
        whiteBackgroundView.addSubview(secondStackView)
        secondStackView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(firstStackView.snp.bottom)
            $0.height.equalTo(66)
            $0.bottom.equalToSuperview()
        }
    }

    private func resetColorSelected() {
        colorItemViews.forEach { [weak self] button in
            guard let self = self else { return }
            button.isSelected = button.tag == self.selectedColor.rawValue
        }
    }

}
