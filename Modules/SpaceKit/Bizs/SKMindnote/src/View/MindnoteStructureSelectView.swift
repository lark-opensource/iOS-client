//
//  MindnoteStructureSelectView.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/9/4.
//  

import UIKit
import SnapKit
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignFont
import UniverseDesignColor

class MindnoteStructureSelectView: UIView {
    struct Config {
        static let itemHeight: CGFloat = 60
        static let cellKey = "mindnote.theme.structure.cell"
    }

    private let stackView = UIStackView()
    private var structures: [ThemeItem]?
    private var activeStructureKey: String?
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.SKResource.Mindnote_Mindnote_Title_Structure
        return label
    }()
    var selectStructure: ((String) -> Void)?
    var optionBackgroundColor = UDColor.bgBodyOverlay {
        didSet {
            optionBgColorDidUpdated()
        }
    }


    init() {
        super.init(frame: .zero)
        setupTitle(titleLabel)
        setupStackView(stackView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTitle(_ title: UILabel) {
        addSubview(titleLabel)
        title.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(16)
        }
    }

    private func setupStackView(_ stackView: UIStackView) {
        self.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
            make.height.equalTo(Config.itemHeight)
        }
        stackView.layer.cornerRadius = 8
        stackView.layer.masksToBounds = true
    }

    func updateStructure(_ data: MindnoteThemeModel) {
        activeStructureKey = data.activeStructureKey
        reloadData(data.structures)
    }

    private func reloadData(_ items: [ThemeItem]?) {
        structures = items
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        structures?.forEach({ (data) in
            let button = MindnoteStructureButton()
            button.defaultBackgroundColor = optionBackgroundColor
            button.docs.addStandardLift()
            button.update(data, selected: data.key == activeStructureKey)
            button.selectedStructure = { [weak self] in
                guard let `self` = self else { return }
                guard let key = data.key else { return }
                self.selectStructure?(key)
            }
            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.height.equalToSuperview()
            }
        })
    }

    private func optionBgColorDidUpdated() {
        stackView.arrangedSubviews.forEach { view in
            guard let button = view as? MindnoteStructureButton else { return }
            button.defaultBackgroundColor = optionBackgroundColor
        }
    }
}
