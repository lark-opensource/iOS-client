//
//  AudioSessionDebugCell.swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/11.
//

import Foundation

class AudioDebugBaseCell: UITableViewCell {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSubviews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)

        let c1 = NSLayoutConstraint(item: titleLabel,
                                    attribute: .top,
                                    relatedBy: .equal,
                                    toItem: self.contentView,
                                    attribute: .top,
                                    multiplier: 1,
                                    constant: 5)
        let c2 = NSLayoutConstraint(item: titleLabel,
                                    attribute: .left,
                                    relatedBy: .equal,
                                    toItem: self.contentView,
                                    attribute: .left,
                                    multiplier: 1,
                                    constant: 20)
        let c3 = NSLayoutConstraint(item: titleLabel,
                                    attribute: .right,
                                    relatedBy: .equal,
                                    toItem: self.contentView,
                                    attribute: .right,
                                    multiplier: 1,
                                    constant: -20)
        let c4 = NSLayoutConstraint(item: subTitleLabel,
                                    attribute: .top,
                                    relatedBy: .equal,
                                    toItem: titleLabel,
                                    attribute: .bottom,
                                    multiplier: 1,
                                    constant: 5)
        let c5 = NSLayoutConstraint(item: subTitleLabel,
                                    attribute: .bottom,
                                    relatedBy: .lessThanOrEqual,
                                    toItem: self.contentView,
                                    attribute: .bottom,
                                    multiplier: 1,
                                    constant: -5)
        let c6 = NSLayoutConstraint(item: subTitleLabel,
                                    attribute: .left,
                                    relatedBy: .equal,
                                    toItem: titleLabel,
                                    attribute: .left,
                                    multiplier: 1,
                                    constant: 0)
        let c7 = NSLayoutConstraint(item: subTitleLabel,
                                    attribute: .right,
                                    relatedBy: .equal,
                                    toItem: titleLabel,
                                    attribute: .right,
                                    multiplier: 1,
                                    constant: 0)
        contentView.addConstraint(c1)
        contentView.addConstraint(c2)
        contentView.addConstraint(c3)
        contentView.addConstraint(c4)
        contentView.addConstraint(c5)
        contentView.addConstraint(c6)
        contentView.addConstraint(c7)
    }
}

class AudioDebugSubtitleCell: AudioDebugBaseCell {

    static let identifier = "AudioDebugSubtitleCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        updateSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindModel(model: AudioDebugSubtitleCellModelGetter) {
        model.execute { [weak self] (v) in
            guard let value = v as? AudioDebugSubtitleCellModel else { return }
            self?.titleLabel.text = value.title
            self?.subTitleLabel.text = value.value
        }
    }
}

class AudioDebugButtonCell: AudioDebugBaseCell {

    static let identifier = "AudioDebugButtonCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.textColor = UIColor.systemBlue
        textLabel?.textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindModel(model: AudioDebugButtonCellModelGetter) {
        model.execute { [weak self] (v) in
            guard let value = v as? AudioDebugButtonCellModel else { return }
            self?.textLabel?.text = value.title
        }
    }
}

class AudioDebugSingleSelCell: AudioDebugBaseCell {

    static let identifier = "AudioDebugSingleSelCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        updateSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindModel(model: AudioDebugSingleSelCellModelGetter) {
        model.execute { [weak self] (v) in
            guard let value = v as? AudioDebugSingleSelCellModel else { return }
            self?.titleLabel.text = value.title
            self?.subTitleLabel.text = value.value.value
        }
    }

    func bindModel(model: AudioDebugSingleSelActionCellModelGetter) {
        model.execute { [weak self] (v) in
            guard let value = v as? AudioDebugSingleSelActionCellModel else { return }
            self?.titleLabel.text = value.title
            self?.subTitleLabel.text = value.value.value
        }
    }
}

class AudioDebugMultiSelCell: AudioDebugBaseCell {

    static let identifier = "AudioDebugMultiSelCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        updateSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindModel(model: AudioDebugMultiSelCellModelGetter) {
        model.execute { [weak self] (v) in
            guard let value = v as? AudioDebugMultiSelCellModel else { return }
            self?.titleLabel.text = value.title
            self?.subTitleLabel.text = value.value.value.joined(separator: "|")
        }
    }
}

class AudioDebugSwitchCell: AudioDebugBaseCell {

    static let identifier = "AudioDebugSwitchCell"

    var switchView: UISwitch?
    var action: ((Bool) -> Bool)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        textLabel?.textColor = UIColor.systemBlue
        textLabel?.textAlignment = .center

        self.switchView = UISwitch()
        self.switchView?.addTarget(self, action: #selector(switchOnValueChanged), for: .valueChanged)
        self.accessoryView = self.switchView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindModel(model: AudioDebugSwitchCellModelGetter) {
        model.execute { [weak self] (v) in
            guard let value = v as? AudioDebugSwitchCellModel else { return }
            self?.textLabel?.text = value.title
            self?.action = value.value
            self?.switchView?.isOn = value.isDefaultOn
        }
    }

    @objc
    func switchOnValueChanged() {
        guard let switchView = switchView else { return }
        let _ = self.action?(switchView.isOn)
    }
}
