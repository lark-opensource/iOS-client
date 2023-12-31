//
//  MeetTabSectionHeaderView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import UIKit
import Lottie
import UniverseDesignIcon
import ByteViewCommon

class MeetTabSectionHeaderView: UITableViewHeaderFooterView, MeetTabSectionConfigurable {

    lazy var paddingView: UIView = {
        let paddingView = UIView()
        paddingView.backgroundColor = .ud.bgBody
        return paddingView
    }()

    lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8.0
        return stackView
    }()

    lazy var titleLabel: UILabel = UILabel(frame: CGRect.zero)

    lazy var titleIcon: UIImageView = {
        let titleIcon = UIImageView()
        titleIcon.isHidden = true
        return titleIcon
    }()

    var animationView: LOTAnimationView?

    lazy var moreButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setImage(UDIcon.getIconByKey(.hideToolbarOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.hideToolbarOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12)), for: .highlighted)
        button.setAttributedTitle(.init(string: I18n.View_MV_ViewAllHere, config: .assist, textColor: UIColor.ud.textPlaceholder), for: .normal)
        button.setAttributedTitle(.init(string: I18n.View_MV_ViewAllHere, config: .assist, textColor: UIColor.ud.textPlaceholder), for: .highlighted)
        button.setBackgroundColor(.clear, for: .normal)
        button.setBackgroundColor(.ud.fillPressed.withAlphaComponent(0.12), for: .highlighted)
        button.addInteraction(type: .hover)

        let space: CGFloat = 2.0
        let titleLabelWidth = button.titleLabel?.intrinsicContentSize.width ?? 0
        let imageViewWidth = button.currentImage?.size.width ?? 0
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleLabelWidth + space / 2, bottom: 0, right: -(titleLabelWidth + space / 2))
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageViewWidth + space / 2), bottom: 0, right: imageViewWidth + space / 2)
        button.clipsToBounds = true
        button.layer.cornerRadius = 6.0
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear

        contentView.addSubview(paddingView)
        paddingView.addSubview(titleStackView)
        paddingView.addSubview(moreButton)

        paddingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleIcon.snp.makeConstraints {
            $0.width.height.equalTo(20.0)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func updateLayout() {
        let isPadFullScreen = Util.isIpadFullScreen && !MeetTabTraitCollectionManager.shared.isRegular
        titleStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(20.0)
            $0.bottom.equalToSuperview().inset(6.0)
            if isPadFullScreen {
                $0.left.equalToSuperview().offset(32.0)
                $0.right.lessThanOrEqualToSuperview().offset(-32.0)
            } else {
                $0.left.equalToSuperview().offset(16.0)
                $0.right.lessThanOrEqualToSuperview().offset(-16.0)
            }
        }
        moreButton.snp.remakeConstraints {
            $0.centerY.equalTo(titleStackView)
            $0.left.greaterThanOrEqualTo(titleStackView).priority(999)
            if isPadFullScreen {
                $0.right.equalToSuperview().inset(25.0)
            } else {
                $0.right.equalToSuperview().inset(9.0)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindTo(viewModel: MeetTabSectionViewModel) {
        let config = VCFontConfig(fontSize: 16, lineHeight: 24, fontWeight: .semibold)
        let textColor: UIColor? = viewModel.textColor
        titleLabel.attributedText = .init(string: viewModel.title,
                                          config: config,
                                          textColor: textColor)
        moreButton.rx.action = viewModel.moreAction
        moreButton.isHidden = !viewModel.isLoadMore
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleIcon.isHidden = true
        animationView?.removeFromSuperview()
    }
}
