//
//  MindnoteStructureCollectionViewCell.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/9/6.
//  

import Foundation
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class MindnoteStructureButton: UIButton {
    private let normalImageView = UIImageView()
    private let activeImageView = UIImageView()
    var selectedStructure: (() -> Void)?
    var defaultBackgroundColor = UDColor.bgBodyOverlay {
        didSet {
            if !normalImageView.isHidden {
                backgroundColor = defaultBackgroundColor
            }
        }
    }

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        normalImageView.isHidden = false
        activeImageView.isHidden = true
        addSubview(normalImageView)
        addSubview(activeImageView)
        normalImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        activeImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @objc
    private func tapped() {
        selectedStructure?()
    }

    func update(_ data: ThemeItem, selected: Bool) {
        backgroundColor = selected ? UDColor.fillActive : defaultBackgroundColor
        normalImageView.isHidden = selected
        activeImageView.isHidden = !selected
        if let normalUrl = data.normalImg, normalUrl.count > 0 {
            normalImageView.kf.setImage(with: URL(string: normalUrl), placeholder: nil, options: nil)
            activeImageView.kf.setImage(with: URL(string: data.activeImg ?? ""), placeholder: nil, options: nil)
        } else {
            guard let key = data.key, let image = imageKeyMap[key] else { return }
            normalImageView.image = image
            guard let selectedImage = imageSelectedKeyMap[key] else { return }
            activeImageView.image = selectedImage
        }
    }

    // FIXME: UDIcon 替换
    private var imageKeyMap: [String: UIImage] {
        return ["right": BundleResources.SKResource.Mindnote.mindnote_structure_icon_rightview,
                "left": BundleResources.SKResource.Mindnote.mindnote_structure_icon_leftview,
                "default": BundleResources.SKResource.Mindnote.mindnote_structure_icon_bilateralview,
                "org": BundleResources.SKResource.Mindnote.mindnote_structure_icon_downview
        ]
    }

    // FIXME: UDIcon 替换
    private var imageSelectedKeyMap: [String: UIImage] {
        return ["right": BundleResources.SKResource.Mindnote.mindnote_structure_icon_rightview_selected,
                "left": BundleResources.SKResource.Mindnote.mindnote_structure_icon_leftview_selected,
                "default": BundleResources.SKResource.Mindnote.mindnote_structure_icon_bilateralview_selected,
                "org": BundleResources.SKResource.Mindnote.mindnote_structure_icon_downview_selected
        ]
    }
}
