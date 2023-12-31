//
//  ImageEditAddMosaicPanel.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/3.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

// swiftlint:disable identifier_name
enum MosaicType: Int {
    case mosaic = 1
    case Gaussan
    static var `default`: MosaicType { return .mosaic }
}

enum SelectionType: Int {
    case point = 0
    case area = 1
    static var `default`: SelectionType { return .point }
}

protocol ImageEditAddMosaicPanelDelegate: AnyObject {

    func panel(_ panel: ImageEditAddMosaicPanel, didChange mosaicType: MosaicType)
    func panel(_ panel: ImageEditAddMosaicPanel, didChange selectionType: SelectionType)
}

final class ImageEditAddMosaicPanel: UIView {
    weak var delegate: ImageEditAddMosaicPanelDelegate?

    private let mosaicTypeStackView = UIStackView()
    private let selectionTypeSegments = UISegmentedControl()
    private let isSmartMosaicEnabled = false // smart mosaic功能下线
    private var mosaicType = MosaicType.default
    private var selectionType = SelectionType.default
    private let disposeBag = DisposeBag()

    init(type: MosaicType, smartMosaicStateObservable: Observable<SmartMosaicState>) {
        super.init(frame: CGRect.zero)

        mosaicTypeStackView.axis = .horizontal
        mosaicTypeStackView.spacing = 20
        addSubview(mosaicTypeStackView)
        mosaicTypeStackView.snp.makeConstraints { (make) in
            make.height.equalTo(30)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-25)
        }
        [MosaicType.mosaic, .Gaussan].forEach { (mosaicType) in
            let button = MosaicTypeButton(type: mosaicType)
            button.addTarget(self, action: #selector(typeButtonClicked), for: .touchUpInside)
            mosaicTypeStackView.addArrangedSubview(button)
            button.isSelected = (mosaicType == type)
        }

        setupSelectionTypeSegments()

        snp.makeConstraints { (make) in
            make.height.equalTo(55)
        }

        smartMosaicStateObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (state) in
            guard let self = self else {
                return
            }
            self.updateSmartMosaicState(state)
        }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshSettings() {
        delegate?.panel(self, didChange: mosaicType)
        delegate?.panel(self, didChange: selectionType)
    }

    private func setupSelectionTypeSegments() {
        if !isSmartMosaicEnabled {
            return
        }

        selectionTypeSegments.insertSegment(with: Resources.edit_finger_select.withRenderingMode(.alwaysOriginal),
                                            at: 0,
                                            animated: false)
        selectionTypeSegments.insertSegment(with: Resources.edit_area_select.withRenderingMode(.alwaysOriginal),
                                            at: 1,
                                            animated: false)
        selectionTypeSegments.layer.borderColor = UIColor.ud.N800.cgColor
        selectionTypeSegments.layer.borderWidth = 1.0
        if #available(iOS 13.0, *) {
            selectionTypeSegments.backgroundColor = .black
            selectionTypeSegments.selectedSegmentTintColor = UIColor.ud.colorfulBlue
        } else {
            selectionTypeSegments.setBackgroundImage(imageWithColor(color: UIColor.ud.colorfulBlue),
                                                     for: .selected,
                                                     barMetrics: .default)
            selectionTypeSegments.setBackgroundImage(imageWithColor(color: .black),
                                                     for: .normal,
                                                     barMetrics: .default)
            selectionTypeSegments.layer.cornerRadius = 6.0
            selectionTypeSegments.layer.masksToBounds = true
        }
        selectionTypeSegments.selectedSegmentIndex = SelectionType.point.rawValue
        selectionTypeSegments.addTarget(self, action: #selector(segmentsValueUpdated), for: .valueChanged)
        addSubview(selectionTypeSegments)

        selectionTypeSegments.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-10)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(73)
            make.height.equalTo(32)
        }
    }

    private func updateSmartMosaicState(_ state: SmartMosaicState) {
        switch state {
        case .fail:
            self.selectionTypeSegments.selectedSegmentIndex = SelectionType.point.rawValue
            delegate?.panel(self, didChange: .point)
        default:
            break
        }
    }

    @objc
    private func segmentsValueUpdated() {
        let index = selectionTypeSegments.selectedSegmentIndex
        let selectionType = SelectionType(rawValue: index) ?? .point
        self.selectionType = selectionType
        delegate?.panel(self, didChange: selectionType)

        // smart mosaic功能下线
//        // Show guide bubble for smart mosaic
//        if selectionType == .area {
//            if let dependency = ModuleDependency.dependency {
//                let rect = convert(selectionTypeSegments.frame, to: nil)
//                let targetRect = CGRect(x: rect.centerX, y: rect.minY, width: rect.width / 2, height: rect.height)
//                dependency.showBubbleGuide(targetRect: targetRect,
//                                           key: "image_editor_smart_mosaic",
//                                           message: BundleI18n.LarkImageEditor.Lark_ASL_PixelateOnboarding)
//            }
//        }
    }

    @objc
    private func typeButtonClicked(_ button: MosaicTypeButton) {
        mosaicTypeStackView.arrangedSubviews.forEach { (view) in
            if let typeButton = view as? MosaicTypeButton {
                typeButton.isSelected = (typeButton === button)
            }
        }
        self.mosaicType = button.type
        delegate?.panel(self, didChange: button.type)
    }

    private func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
// swiftlint:enable identifier_name
