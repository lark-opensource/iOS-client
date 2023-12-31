//
//  SpacePanelCell.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/8/25.
//

import Foundation
import UniverseDesignColor

private extension SpacePanelCell {
    enum Layout {
        static var backgroundColor: UIColor { UDColor.bgFloat }
        static var selectedBackgroundColor: UIColor { UDColor.primaryFillSolid02 }
        static var titleColor: UIColor { UDColor.textTitle }
        static var invalidTitleColor: UIColor { UDColor.textDisabled }
        static var selectedTitleColor: UIColor { UDColor.primaryContentDefault }
        static var pressedBackgroundColor: UIColor { UDColor.fillPressed }
    }
}

public final class SpacePanelCell: UICollectionViewCell {

    public enum ValidState {
        case valid
        case invalid(reason: String)
    }

    override public var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = Layout.selectedBackgroundColor
                titleLabel.textColor = Layout.selectedTitleColor
            } else {
                contentView.backgroundColor = Layout.backgroundColor
                titleLabel.textColor = Layout.titleColor
            }
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            if isSelected { return }
            if isHighlighted {
                contentView.backgroundColor = Layout.pressedBackgroundColor
            } else {
                contentView.backgroundColor = Layout.backgroundColor
            }
        }
    }

    private(set) public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = Layout.titleColor
        label.textAlignment = .center
        return label
    }()

    public var validState = ValidState.valid {
        didSet {
            switch validState {
            case .valid:
                titleLabel.textColor = Layout.titleColor
            case .invalid:
                titleLabel.textColor = Layout.invalidTitleColor
            }
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        validState = .valid
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        contentView.backgroundColor = Layout.backgroundColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
