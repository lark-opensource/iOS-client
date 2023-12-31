//
//  MeetingRoomMultiLevelSelectionViewController+CustomViews.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/9/3.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import UniverseDesignIcon
import UniverseDesignCheckBox

extension MeetingRoomMultiLevelSelectionViewController {
    final class LevelIndicatorView: UIView {
        lazy var baseScrollView: UIScrollView = {
            let scrollView = UIScrollView()
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.isExclusiveTouch = true
            scrollView.contentInset = UIEdgeInsets(horizontal: 16, vertical: 0)
            return scrollView
        }()

        lazy var baseStackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .equalSpacing
            stackView.spacing = 4
            return stackView
        }()

        fileprivate let levelRelay = PublishRelay<MLLevel>()
        let levelToUpdate = PublishRelay<MLLevel>()
        private(set) var currentLevel: MLLevel?
        var alwaysShowIndicator = false

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = UIColor.ud.bgBody

            addSubview(baseScrollView)
            baseScrollView.addSubview(baseStackView)

            baseScrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            baseStackView.snp.makeConstraints { make in
                make.edges.centerY.equalToSuperview()
            }

            addBottomSepratorLine()

            _ = levelRelay.subscribeForUI(onNext: { [weak self] newLevel in
                self?.refreshLevels(level: newLevel)
                self?.currentLevel = newLevel
            })

        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            if currentLevel?.superLevel == nil && !alwaysShowIndicator {
                // root only
                return CGSize(width: UIView.noIntrinsicMetric, height: 0)
            } else {
                return CGSize(width: UIView.noIntrinsicMetric, height: 46)
            }
        }

        private func refreshLevels(level: MLLevel) {
            // 如果没打开始终显示且只有根层级 不展示
            if !alwaysShowIndicator && level.superLevel == nil {
                baseStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                invalidateIntrinsicContentSize()
                return
            }

            var levelsToDisplay = [MLLevel]()
            var current: MLLevel? = level
            repeat {
                levelsToDisplay.insert(current!, at: 0)
                current = current?.superLevel
            } while current != nil

            var views = levelsToDisplay
                .map { level -> UIView in
                    let label = UILabel()
                    label.isUserInteractionEnabled = true
                    label.text = level.name

                    if level == levelsToDisplay.last {
                        label.textColor = UIColor.ud.textCaption
                    } else {
                        label.textColor = UIColor.ud.primaryContentDefault

                        let tap = UITapGestureRecognizer()
                        label.addGestureRecognizer(tap)

                        _ = tap.rx.event
                            .subscribe(onNext: { [weak self] _ in
                                if level.needUpdate {
                                    self?.levelToUpdate.accept(level)
                                } else {
                                    self?.levelRelay.accept(level)
                                }
                            })
                    }

                    return label
                }
                .reduce([UIView]()) { list, button in
                    let arrowView = UIImageView(image: UDIcon.rightOutlined.renderColor(with: .n3))
                    arrowView.snp.makeConstraints { $0.width.height.equalTo(16) }
                    return list + [button, arrowView]
                }
            if !views.isEmpty {
                views.removeLast()
            }

            baseStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            views.forEach { baseStackView.addArrangedSubview($0) }

            let width = baseStackView.systemLayoutSizeFitting(.zero).width

            if window == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let targetOffsetX = width + self.baseScrollView.contentInset.left - self.frame.width
                    if targetOffsetX > 0 {
                        self.baseScrollView.contentOffset = CGPoint(x: targetOffsetX, y: 0)
                    }
                }
            } else {
                let targetOffsetX = width + baseScrollView.contentInset.left - frame.width
                if targetOffsetX > 0 {
                    baseScrollView.contentOffset = CGPoint(x: targetOffsetX, y: 0)
                }
            }

            invalidateIntrinsicContentSize()
        }
    }

    final class SelectAllView: UIView {
        fileprivate var selectTypeRelay = PublishRelay<SelectType>()

        var currentType: SelectType = .nonSelected {
            didSet {
                checkBox.isEnabled = currentType != .disabled
                checkBox.isSelected = currentType == .selected || currentType == .halfSelected
                checkBox.updateUIConfig(boxType: currentType.boxType, config: UDCheckBoxUIConfig())
            }
        }

        private let checkBox = UDCheckBox()
        private let label = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            layoutUI()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func layoutUI() {
            backgroundColor = UIColor.ud.bgBody

            checkBox.isUserInteractionEnabled = false
            addSubview(checkBox)
            checkBox.snp.makeConstraints { make in
                make.leading.equalTo(16)
                make.top.equalToSuperview().inset(12)
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(12)
                make.size.equalTo(CGSize(width: 20, height: 20))
            }

            label.text = I18n.Calendar_Common_SelectAll
            label.textColor = .ud.textTitle
            label.font = UIFont.cd.font(ofSize: 14)
            addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalTo(checkBox.snp.trailing).offset(8)
                make.centerY.equalTo(checkBox.snp.centerY)
                make.trailing.lessThanOrEqualToSuperview()
            }

            addTopBorder()

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
            addGestureRecognizer(tapGesture)
        }

        @objc
        private func toggle() {
            switch self.currentType {
            case .selected, .halfSelected:
                self.currentType = .nonSelected
                self.selectTypeRelay.accept(.nonSelected)
            case .nonSelected:
                self.currentType = .selected
                self.selectTypeRelay.accept(.selected)
            case .disabled:
                // do nothing
                break
            }
        }
    }
}

extension Reactive where Base == MeetingRoomMultiLevelSelectionViewController.LevelIndicatorView {
    var level: ControlProperty<MLLevel> {
        ControlProperty(values: base.levelRelay, valueSink: Binder<MLLevel>(base.levelRelay, binding: { target, newValue in
            target.accept(newValue)
        }))
    }
}

extension Reactive where Base == MeetingRoomMultiLevelSelectionViewController.SelectAllView {
    var selectAllState: Binder<SelectType> {
        Binder(base) { base, newValue in
            base.currentType = newValue
        }
    }

    var selectAllStateDidChange: Observable<SelectType> {
        base.selectTypeRelay.asObservable()
    }
}
