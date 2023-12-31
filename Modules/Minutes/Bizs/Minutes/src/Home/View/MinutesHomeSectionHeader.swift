//
//  MinutesHomeSectionHeader.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/14.
//

import UIKit
import UniverseDesignColor
import MinutesFoundation
import MinutesNetwork
import Reachability
import UniverseDesignIcon

class MinutesHomeSectionHeader: UITableViewHeaderFooterView {

    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = UIColor.ud.textTitle
        return l
    }()

    lazy var filterButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.filterOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 18, height: 18)), for: .normal)
        return btn
    }()

    lazy var sortButton: SortButton = {
        let btn = SortButton()
        btn.isHidden = true
        return btn
    }()

    lazy var line: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.lineDividerDefault
        return v
    }()

    private lazy var noNetworkView: MinutesHomeNoNetworkView = {
        let view = MinutesHomeNoNetworkView()
        view.isHidden = true
        return view
    }()

    var isButtonHighlight: Bool = false {
        didSet {
            if isButtonHighlight {
                filterButton.setImage(UDIcon.getIconByKey(.filterOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 18, height: 18)), for: .normal)
            } else {
                filterButton.setImage(UDIcon.getIconByKey(.filterOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 18, height: 18)), for: .normal)
            }
            sortButton.isSelected = isButtonHighlight
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
        }

        contentView.addSubview(filterButton)
        filterButton.snp.makeConstraints { make in
            make.right.equalTo(-1)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        contentView.addSubview(noNetworkView)
        noNetworkView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(line.snp.bottom)
            make.height.equalTo(44)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveNetworkStatusChanged(_:)), name: .reachabilityChanged, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onReceiveNetworkStatusChanged(_ notification: Notification) {
        guard let someReachability = notification.object as? Reachability else { return }
        if someReachability.connection == .none {
            noNetworkView.isHidden = false
        } else {
            noNetworkView.isHidden = true
        }
    }

    func config(with viewModel: MinutesSpaceListViewModel) {
        titleLabel.text = viewModel.spaceType.sectionTitle
        isButtonHighlight = viewModel.isFilterIconActived
        if viewModel.spaceType == .home {
            titleLabel.isHidden = false
            sortButton.isHidden = true
            filterButton.isHidden = false
            line.isHidden = false
        } else {
            titleLabel.isHidden = true
            sortButton.isHidden = false
            filterButton.isHidden = true
            line.isHidden = true
            sortButton.titleLabel.text = viewModel.rankType.title
            sortButton.arrowUp = viewModel.asc
        }
    }
}

extension MinutesHomeSectionHeader {

    class SortButton: UIControl {

        lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = .systemFont(ofSize: 14)
            l.textColor = UIColor.ud.textCaption
            return l
        }()

        lazy var icon: UIImageView = {
            let iv = UIImageView()
            iv.image = UDIcon.getIconByKey(.spaceUpOutlined, iconColor: UIColor.ud.textCaption, size: CGSize(width: 14, height: 14))
            return iv
        }()

        var arrowUp: Bool = true {
            didSet {
                if arrowUp {
                    icon.transform = CGAffineTransform.init(scaleX: 1.0, y: 1.0)
                } else {
                    icon.transform = CGAffineTransform.init(scaleX: 1.0, y: -1.0)
                }
            }
        }

        override var isSelected: Bool {
            didSet {
                if isSelected {
                    titleLabel.textColor = UIColor.ud.primaryContentDefault
                    icon.image = UDIcon.getIconByKey(.spaceUpOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 14, height: 14))
                } else {
                    titleLabel.textColor = UIColor.ud.textCaption
                    icon.image = UDIcon.getIconByKey(.spaceUpOutlined, iconColor: UIColor.ud.textCaption, size: CGSize(width: 14, height: 14))

                }
            }
        }

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.isUserInteractionEnabled = false
            stackView.addArrangedSubview(titleLabel)
            stackView.setCustomSpacing(4, after: titleLabel)
            stackView.addArrangedSubview(icon)
            return stackView
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.bgBody
            addSubview(stackView)
            stackView.snp.makeConstraints { maker in
                maker.centerY.left.right.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
