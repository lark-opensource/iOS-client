//
//  MinutesTranscriptView.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/9/14.
//

import Foundation
import SnapKit
import UniverseDesignIcon

final class MinutesTranscriptView: UIView {

    private lazy var bgView: UIImageView = {
        let iv = UIImageView()
        iv.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        iv.addSubview(desLabel)
        desLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(icon.snp.bottom).offset(16)
        }
        return iv
    }()

    private lazy var icon: UIImageView = {
        let iv = UIImageView()
        iv.image = UDIcon.getIconByKey(.transcribeOutlined, renderingMode: .alwaysTemplate, iconColor: UIColor.ud.gradientBlue(ofSize: CGSize(width: 36, height: 36)), size: CGSize(width: 36, height: 36))
        return iv
    }()

    private lazy var desLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.text = BundleI18n.Minutes.MMWeb_G_TranscriptionisNotesOnly_Desc
        return label
    }()

    private lazy var currentTimeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor.ud.primaryOnPrimaryFill
        l.text = "00:00"
        return l
    }()
    private lazy var endTimeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.7)
        let text = "--:--"
        l.text = "  /  \(text)"
        return l
    }()

    private lazy var leftBottomStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.addArrangedSubview(currentTimeLabel)
        stack.addArrangedSubview(endTimeLabel)
        return stack
    }()

    private lazy var blackView: UIView = {
        let v = UIView()
        v.backgroundColor = .black.withAlphaComponent(0.3)
        v.addSubview(leftBottomStack)
        leftBottomStack.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview().inset(16)
        }
        return v
    }()

    private lazy var grandientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(red: 0.87, green: 0.96, blue: 1, alpha: 1).cgColor, UIColor(red: 0.84, green: 0.88, blue: 0.98, alpha: 1).cgColor, UIColor(red: 0.58, green: 0.69, blue: 0.97, alpha: 0.79).cgColor]
        layer.locations = [0, 0.58, 1]
        layer.opacity = 0.25
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(grandientLayer)
        addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(blackView)
        blackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAction)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside: CGPoint, with: UIEvent?) -> Bool {
        var rect = bounds
        rect.size.height = bounds.height + 10
        return rect.contains(inside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        grandientLayer.frame = bounds
        CATransaction.commit()
    }

    @objc func tapAction() {
        blackView.isHidden = !blackView.isHidden
    }

    func setProgressBar(_ bar: MinutesTranscriptProgressBar) {
        addSubview(bar)
        bar.backgroundColor = .clear
        bar.currentTimeLabel.isHidden = true
        bar.endTimeLabel.isHidden = true
        bar.currentTimeDidhanged = { [weak self] time in
            self?.currentTimeLabel.text = time
        }
        bar.endTimeDidhanged = { [weak self] time in
            self?.endTimeLabel.text = "  /  \(time ?? "--:--")"
        }
        bar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(-16)
            make.bottom.equalTo(22)
            make.height.equalTo(46)
        }
        self.endTimeLabel.text = "  /  \(bar.endTimeLabel.text ?? "--:--")"
    }
}
