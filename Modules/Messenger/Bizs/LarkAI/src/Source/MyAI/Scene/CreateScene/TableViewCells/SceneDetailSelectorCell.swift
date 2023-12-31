////
////  SceneDetailSelectorCell.swift
////  LarkAI
////
////  Created by Zigeng on 2023/10/10.
////
//
import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignColor
import LarkFeatureGating
import SnapKit
import EENavigator

final class SceneDetailSelectorCell: UITableViewCell, SceneDetailCell {
    typealias VM = SceneDetailSelectorCellViewModel
    static let identifier: String = "SceneDetailSelectorCell"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var textPreviewLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        return view
    }()

    var tapAction: VM.TapAction?
    var preview: VM.Preview? = .none
    func setCell(vm: VM) {
        titleLabel.text = vm.title
        self.tapAction = vm.tapAction
        switch vm.preview {
        case .text(let text):
            textPreviewLabel.text = text
        default:
            textPreviewLabel.text = nil
        }
        self.preview = vm.preview
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // 去掉点击高亮效果
        let container = UIView()
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.height.equalTo(46)
            make.edges.equalToSuperview()
        }
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        container.addSubview(arrowView)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        container.addSubview(textPreviewLabel)
        textPreviewLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(16)
            make.right.equalTo(arrowView.snp.left).offset(-4)
        }
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellDidtapped)))
    }

    @objc
    private func cellDidtapped() {
        guard let window = self.window else { return }
        tapAction?(window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
