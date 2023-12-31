//
//  SIPDialInSelectionView.swift
//  ByteView
//
//  Created by admin on 2022/5/27.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon

final class SIPDialInSelectionView: UIView {

    final class StateButton: UIButton {

        var spacing: CGFloat = 4.0 {
            didSet {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }

        var loadingViewSize: CGSize = CGSize(width: 16.0, height: 16.0) {
            didSet {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }

        private let loadingView: LoadingView = {
            let loading = LoadingView(frame: CGRect(origin: .zero, size: CGSize(width: 16, height: 16)), style: .blue)
            loading.backgroundColor = .clear
            return loading
        }()

        private let retryImgView: UIImageView = {
            let img = UDIcon.getIconByKey(.refreshOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
            let imgView = UIImageView(image: img)
            return imgView
        }()

        var isLoading: Bool = false {
            didSet {
                guard oldValue != isLoading else {
                    return
                }
                if isLoading {
                    isUserInteractionEnabled = false
                    loadingView.play()
                    loadingView.isHidden = false
                    retryImgView.isHidden = true
                    self.setTitle(I18n.View_G_Getting, for: .disabled)
                    self.setTitleColor(.ud.udtokenComponentTextDisabledLoading, for: .disabled)
                } else {
                    isUserInteractionEnabled = true
                    loadingView.stop()
                    loadingView.isHidden = true
                    retryImgView.isHidden = false
                    self.setTitle(I18n.View_G_FailedToGet, for: .disabled)
                    self.setTitleColor(.ud.textTitle, for: .disabled)
                }
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupSubviews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            size.width += loadingViewSize.width + spacing
            return size
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var size = super.sizeThatFits(size)
            size.width += loadingViewSize.width + spacing
            return size
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if isLoading {
                loadingView.frame = CGRect(x: self.contentEdgeInsets.left,
                                           y: (self.bounds.height - loadingViewSize.height) * 0.5,
                                           width: loadingViewSize.width,
                                           height: loadingViewSize.height)
                var titleFrame = self.titleLabel?.frame ?? .zero
                titleFrame.origin.x = loadingView.frame.maxX + spacing
                self.titleLabel?.frame = titleFrame
            } else {
                retryImgView.frame = CGRect(x: self.contentEdgeInsets.left,
                                           y: (self.bounds.height - loadingViewSize.height) * 0.5,
                                           width: loadingViewSize.width,
                                           height: loadingViewSize.height)
                var titleFrame = self.titleLabel?.frame ?? .zero
                titleFrame.origin.x = retryImgView.frame.maxX + spacing
                self.titleLabel?.frame = titleFrame
            }
            self.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        private func setupSubviews() {
            loadingView.isHidden = true
            retryImgView.isHidden = false
            self.addSubview(self.loadingView)
            self.addSubview(self.retryImgView)
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    private lazy var despLabel: CopyableTextView = {
        let label = CopyableTextView()
        label.textContainerInset = .zero
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .right
        label.textContainer.maximumNumberOfLines = 1
        label.textContainer.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var arrowImgView: UIImageView = {
        let arrowIcon = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
        let imgView = UIImageView(image: arrowIcon)
        imgView.autoresizesSubviews = true
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()

    private lazy var stateBtn: StateButton = {
        let btn = StateButton()
        btn.isUserInteractionEnabled = false
        btn.isEnabled = false
        return btn
    }()

    var title = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var despAttributedText: NSAttributedString? {
        didSet {
            despLabel.attributedText = despAttributedText
        }
    }

    var stateType: SIPDialViewModel.StateType = .none {
        didSet {
            let showArrow = stateType == .arrow
            let showState = stateType == .error || stateType == .loading
            arrowImgView.isHidden = !showArrow
            stateBtn.isHidden = !showState
            despLabel.isHidden = showState
            switch stateType {
            case .none:
                arrowImgView.image = nil
            case .arrow:
                arrowImgView.image = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
            case .error:
                stateBtn.isLoading = false
            case .loading:
                stateBtn.isLoading = true
            }

            despLabel.snp.updateConstraints { make in
                make.right.equalTo(arrowImgView.snp.left).offset(showArrow ? 0 : 16)
            }

        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(despLabel)
        addSubview(arrowImgView)
        addSubview(stateBtn)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(52)
            make.width.lessThanOrEqualTo(100)
        }

        arrowImgView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        despLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalTo(arrowImgView.snp.left).offset(0)
        }

        stateBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.width.greaterThanOrEqualTo(68)
        }
    }

    func addTapGesture(_ gestrue: UITapGestureRecognizer) {
        despLabel.addGestureRecognizer(gestrue)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class SIPChosenIPCell: UITableViewCell {

    lazy var checkImgView: UIImageView = {
        let icon = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
        let checkImgView = UIImageView(image: icon)
        checkImgView.contentMode = .scaleAspectFit
        checkImgView.backgroundColor = .clear
        return checkImgView
    }()

    lazy var lineView: UIView = {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    var showChecked: Bool = false {
        didSet {
            checkImgView.isHidden = !showChecked
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.backgroundColor = .ud.bgFloatBase
        self.contentView.backgroundColor = .ud.bgFloatBase
        self.textLabel?.textColor = .ud.textTitle
        self.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.contentView.addSubview(checkImgView)
        self.contentView.bringSubviewToFront(checkImgView)
        self.addSubview(lineView)

        checkImgView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalTo(self.safeAreaLayoutGuide).offset(-16)
        }

        if let textLabel = self.textLabel {
            lineView.snp.makeConstraints { make in
                make.right.bottom.equalToSuperview()
                make.left.equalTo(textLabel)
                make.height.equalTo(0.5)
            }
        } else {
            lineView.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
