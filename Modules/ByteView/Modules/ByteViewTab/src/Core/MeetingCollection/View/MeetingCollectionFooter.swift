//
//  MeetingCollectionFooter.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/8.
//

import Foundation
import UniverseDesignColor
import ByteViewNetwork
import UIKit

class MeetingCollectionFooter: UIView {

    var isTopConstraint: Bool = true {
        didSet {
            guard isTopConstraint != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    lazy var roundedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.masksToBounds = false
        let shadowColor = UDColor.getValueByKey(.s2DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
        view.layer.ud.setShadowColor(shadowColor, bindTo: containerView)
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 3
        view.layer.cornerRadius = 10.0
        return view
    }()

    var angleView = UIView()

    var containerView = UIView()
    var line1 = UIView()
    var line2 = UIView()

    var titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    func setupSubviews() {
        line1.backgroundColor = UIColor.ud.lineDividerDefault
        line2.backgroundColor = UIColor.ud.lineDividerDefault
        angleView.backgroundColor = UIColor.ud.bgBody

        addSubview(containerView)
        containerView.addSubview(roundedView)
        containerView.addSubview(line1)
        containerView.addSubview(line2)
        containerView.addSubview(titleLabel)

        roundedView.addSubview(angleView)

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        line1.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.left.equalToSuperview().offset(32.0)
            $0.height.equalTo(1.0)
            $0.right.equalTo(titleLabel.snp.left).offset(-15.0)
        }

        line2.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.right.equalToSuperview().offset(-32.0)
            $0.height.equalTo(1.0)
            $0.left.equalTo(titleLabel.snp.right).offset(15.0)
        }

        roundedView.snp.makeConstraints {
            $0.top.centerX.width.equalToSuperview()
            $0.height.equalTo(58.0)
        }
        angleView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(10.0)
        }
    }

    func bindViewModel(monthLimit: Int) {
        titleLabel.attributedText = .init(string: I18n.View_G_DisplayNumberMonthMeeting(monthLimit),
                                          config: .bodyAssist,
                                          alignment: .center,
                                          lineBreakMode: .byWordWrapping,
                                          textColor: UIColor.ud.textPlaceholder)
    }

    func updateLayout() {
        if traitCollection.isRegular {
            backgroundColor = .clear
            roundedView.isHidden = false
            let padding = 48.0
            let cellWidth = bounds.width - 2 * padding
            roundedView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 3, width: cellWidth, height: 58), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath

            line1.snp.updateConstraints {
                $0.left.equalToSuperview().offset(32.0)
                $0.height.equalTo(1.0)
            }

            line2.snp.updateConstraints {
                $0.right.equalToSuperview().offset(-32.0)
                $0.height.equalTo(1.0)
            }

            containerView.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.left.right.equalToSuperview().inset(padding)
            }
            titleLabel.snp.remakeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalToSuperview().inset(12.0)
            }
        } else {
            backgroundColor = UIColor.ud.bgBody
            roundedView.isHidden = true

            line1.snp.updateConstraints {
                $0.left.equalToSuperview().offset(16.0)
                $0.height.equalTo(0.5)
            }

            line2.snp.updateConstraints {
                $0.right.equalToSuperview().offset(-16.0)
                $0.height.equalTo(0.5)
            }

            containerView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints {
                $0.centerX.equalToSuperview()
                if isTopConstraint {
                    $0.top.equalToSuperview().inset(16.0)
                } else {
                    $0.bottom.equalToSuperview().inset(48.0)
                }
            }
        }
    }

    func calculateHeight() -> CGFloat {
        traitCollection.isRegular ? 82.0 : 86.0
    }
}
