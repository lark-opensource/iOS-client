//
//  FilePreviewView.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/9.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit

class FilePreviewView: UIImageView {

    private var iconDimensionConstraint: Constraint?

    var iconDimension: CGFloat = 30.0 {
        didSet {
            DispatchQueue.main.async {
                self.previewIconView.snp.updateConstraints {
                    $0.width.height.equalTo(self.iconDimension)
                }
            }
        }
    }

    var showShadow: Bool = false {
        didSet {
            shadowLayer.isHidden = !showShadow
        }
    }

    var showBadge: Bool = false {
        didSet {
            previewBadgeView.isHidden = !showBadge
        }
    }

    lazy var previewBadgeView = ShadowBadgeView()

    lazy var previewIconView: UIImageView = {
        let previewIconView = UIImageView()
        previewIconView.contentMode = .scaleAspectFit
        return previewIconView
    }()

    lazy var shadowLayer: UIView = {
        let shadowLayer = UIView()
        shadowLayer.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.15)
        return shadowLayer
    }()

    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor.ud.staticWhite
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        layer.cornerRadius = 8.0
        layer.borderWidth = 1.0
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        clipsToBounds = true
        contentMode = .scaleAspectFill

        shadowLayer.isHidden = true
        previewBadgeView.isHidden = true

        addSubview(shadowLayer)
        addSubview(previewIconView)
        addSubview(previewBadgeView)
        addSubview(durationLabel)

        shadowLayer.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        previewIconView.snp.makeConstraints {
            $0.width.height.equalTo(iconDimension)
            $0.center.equalToSuperview()
        }
        previewBadgeView.snp.makeConstraints {
            $0.right.bottom.equalTo(-2.0)
            $0.width.greaterThanOrEqualTo(16.0)
        }
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(-4)
            make.bottom.equalTo(-2)
        }
    }

    func reset() {
        showBadge = false
        showShadow = false
        previewBadgeView.showLabel = false

        image = nil
        previewIconView.image = nil
        previewBadgeView.iconView.image = nil
    }
}
