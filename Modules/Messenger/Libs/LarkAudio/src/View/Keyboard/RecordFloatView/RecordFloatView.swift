//
//  RecordFloatView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/29.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import LarkContainer

final class RecordFloatView: UIView {
    enum State {
        case normal
        case cancel
    }

    var state: State = .normal {
        didSet {
            self.updateViewState()
        }
    }
    var time: TimeInterval = 0 {
        didSet {
            self.updateTimeLabel()
        }
    }

    var processing: Bool = false {
        didSet {
            if processing == oldValue { return }
            self.decibleViews.forEach { (view) in
                view.isHidden = processing
            }
            if processing {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }

    private var decibleNumber: Int = 15

    private var iconView: UIView = UIView()
    private var countDownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 26)
        label.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        label.textColor = UIColor.ud.colorfulRed
        return label
    }()
    private var icon: UIImageView = UIImageView()
    private var tipLabel: UILabel = UILabel()
    private var timeLabel: UILabel = UILabel()
    private var activityIndicator = UIActivityIndicatorView()

    private var decibleViews: [UIView] = []
    private var decibles: [CGFloat] = []

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.cornerRadius = 30
        return layer
    }()

    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 22
    private let maxDecible: CGFloat = 80
    private let minDecible: CGFloat = 40

    private var defaultDecibles: [CGFloat] = [40, 40, 40, 40, 44, 47, 49, 50, 49, 47, 44, 40]
    private var defaultIndex: Int = 0

    // 取单个数字的最大宽度
    private static var numberMaxWidth: CGFloat = {
        let font = UIFont.systemFont(ofSize: 16)
        return (0...9).map({ (index) -> CGFloat in
            let rect = NSString(string: "\(index)").boundingRect(
                with: CGSize(width: 100, height: CGFloat(MAXFLOAT)),
                options: .usesLineFragmentOrigin,
                attributes: [.font: font],
                context: nil)
            print("\(index),\(rect)")
            return rect.width
        }).max() ?? 0
    }()

    private let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        self.initDecibleNumber()
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func append(decible: CGFloat) {

        // 利用随机种子生成一组数据
        var randomSet: [CGFloat] = []

        if decible > self.minDecible + 10 {
            var faultNumber: Int = 0
            var lastValue = decible
            while randomSet.count < self.decibleNumber {
                var value = lastValue + 5 - CGFloat.random(in: 0...9)
                while value < decible - 20 || value > decible + 5 {
                    value = lastValue + 5 - CGFloat.random(in: 0...9)
                }
                randomSet.append(value)
                lastValue = value

                // 添加随机断层
                if Int.random(in: 0...7) == 0 && lastValue > minDecible + 10 && faultNumber < 3 {
                    randomSet.append(CGFloat.random(in: 0...CGFloat(UInt32(lastValue - minDecible - 1))) / 3 + minDecible)
                    faultNumber += 1
                }
            }
        } else {
            for index in 0..<self.decibleNumber {
                var decibleIndex = self.defaultIndex + index
                if decibleIndex >= self.defaultDecibles.count {
                    decibleIndex %= self.defaultDecibles.count - 1
                }
                randomSet.append(self.defaultDecibles[decibleIndex])
            }

            if self.defaultIndex == self.defaultDecibles.count - 1 {
                self.defaultIndex = 0
            } else {
                self.defaultIndex += 1
            }
        }

        self.decibles = randomSet
        self.updateDeciblesView()
    }

    func setCountDown(time: TimeInterval?) {
        if let time = time {
            self.countDownLabel.isHidden = false
            self.countDownLabel.text = "\(Int(time))"
        } else {
            self.countDownLabel.isHidden = true
        }
    }

    private func initDecibleNumber() {
        let minNumber = 15
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
        let width = max(
            (BundleI18n.LarkAudio.Lark_Chat_RecordAudioSlideUp as NSString).size(withAttributes: attributes).width,
            (BundleI18n.LarkAudio.Lark_Chat_RecordAudioCancel as NSString).size(withAttributes: attributes).width
        )

        self.decibleNumber = max(minNumber, Int((width - 35) / 4))
    }

    private func setupViews() {
        self.layer.cornerRadius = 30
        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.layer.shadowColor = UIColor.ud.N900.withAlphaComponent(0.16).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 10
        self.layer.shadowOpacity = 1

        self.layer.addSublayer(self.gradientLayer)

        self.addSubview(self.iconView)
        iconView.layer.masksToBounds = true
        iconView.layer.cornerRadius = 22.5
        iconView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.iconView.snp.makeConstraints { (maker) in
            maker.left.top.equalTo(7.5)
            maker.bottom.equalTo(-7.5)
            maker.width.height.equalTo(45)
        }

        self.iconView.addSubview(self.icon)
        icon.snp.makeConstraints { (maker) in
            maker.center.equalTo(self.iconView)
            maker.width.height.equalTo(24)
        }

        self.iconView.addSubview(self.countDownLabel)
        self.countDownLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        self.countDownLabel.isHidden = true

        self.addSubview(self.tipLabel)
        self.tipLabel.textAlignment = .center
        self.tipLabel.font = UIFont.systemFont(ofSize: 12)
        self.tipLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.tipLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(self.iconView.snp.right).offset(7)
            maker.right.equalToSuperview().offset(-22.5)
            maker.bottom.equalTo(-9)
        }

        for _ in 0..<self.decibleNumber {
            let view = UIView()
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 1
            view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            self.addSubview(view)
            view.snp.makeConstraints { (maker) in
                if let lastView = self.decibleViews.last {
                    maker.left.equalTo(lastView.snp.right).offset(2)
                } else {
                    maker.left.equalTo(self.iconView.snp.right).offset(7)
                }
                maker.width.equalTo(2)
                maker.bottom.equalToSuperview().offset(-30.5)
                maker.height.equalTo(4)
            }

            self.decibleViews.append(view)
        }

        self.addSubview(self.timeLabel)
        self.timeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.timeLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.timeLabel.textAlignment = .right
        self.timeLabel.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-22.5)
            maker.top.equalToSuperview().offset(11)
            if let lastView = self.decibleViews.last {
                maker.left.greaterThanOrEqualTo(lastView.snp.right).offset(5)
            }
            maker.width.equalTo(0)
        }

        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .white
        self.addSubview(activityIndicator)
        self.activityIndicator.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(17.5)
            maker.left.equalTo(self.iconView.snp.right).offset(7)
            maker.top.equalTo(13)
        }

        self.updateViewState()
        self.updateTimeLabel()
        self.updateDeciblesView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.bounds
    }

    private func updateViewState() {
        switch self.state {
        case .normal:
            self.icon.image = Resources.new_float_record_normal
            self.gradientLayer.colors = [UDColor.B500.cgColor, UDColor.B500.cgColor]
            self.tipLabel.textColor = UIColor.ud.staticWhite
            self.tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_RecordAudioSlideUp
        case .cancel:
            self.gradientLayer.colors = [UDColor.R500.cgColor, UDColor.R500.cgColor]
            self.icon.image = Resources.new_float_record_cancel
            self.tipLabel.textColor = UIColor.ud.staticWhite
            self.tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_RecordAudioCancel
        }
    }

    private func updateTimeLabel() {
        let time = Int(self.time)
        let second = time % 60
        let minute = time / 60
        let secondStr = String(format: "%02d", second)
        if minute == 0 {
            self.timeLabel.text = "\(second)\""
        } else {
            self.timeLabel.text = "\(minute)\'\(secondStr)\""
        }

        self.timeLabel.snp.updateConstraints { (maker) in
            maker.width.equalTo(ceil(CGFloat(self.timeLabel.text?.count ?? 0) * RecordFloatView.numberMaxWidth))
        }
    }

    private func updateDeciblesView() {
        self.decibles.enumerated().forEach { (index, decible) in
            if index >= self.decibleViews.count { return }
            let view = self.decibleViews[index]

            let height = max(
                self.minHeight,
                min(self.maxHeight, self.maxHeight * (decible - self.minDecible) / (self.maxDecible - self.minDecible))
            )
            view.snp.updateConstraints({ (maker) in
                maker.height.equalTo(height)
            })
        }

        if self.superview != nil {
            UIView.animate(withDuration: 0.1) {
                self.layoutIfNeeded()
            }
        }
    }
}
