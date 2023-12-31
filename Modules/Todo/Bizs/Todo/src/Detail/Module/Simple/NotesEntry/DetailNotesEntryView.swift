//
//  DetailNotesEntryView.swift
//  Todo
//
//  Created by 张威 on 2021/2/6.
//

import SnapKit
import EditTextView
import LarkUIKit
import CTFoundation
import UniverseDesignIcon
import UIKit
import UniverseDesignFont

/// Detail - Notes - EntryView

final class DetailNotesEntryView: BasicCellLikeView {

    var onTap: (() -> Void)?

    lazy var textView: LarkEditTextView = DetailNotesInputView.makeEditTextView()

    private lazy var containerView: UIView = UIView()
    private lazy var textViewMaskView: UIView = UIView()

    private lazy var moreButton: UIButton = {
        var btn = UIButton()
        btn.setTitle(I18N.Todo_Task_ShowMore, for: .normal)
        btn.titleLabel?.font = UDFont.systemFont(ofSize: 14)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.titleLabel?.textAlignment = .right
        return btn
    }()

    private lazy var gradientView: UIView = {
        let gradientView = GradientView()
        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [
            UIColor.ud.bgBody.withAlphaComponent(0.8),
            UIColor.ud.bgBody.withAlphaComponent(0)
        ]
        gradientView.locations = [1.0, 0.0]
        gradientView.direction = .vertical
        return gradientView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(containerView)
        content = .customView(containerView)
        let image = UDIcon.detailsOutlined
            .ud.resized(to: CGSize(width: 16, height: 16))
            .ud.withTintColor(UIColor.ud.iconN3)
        icon = .customImage(image)
        iconAlignment = .topByOffset(2.5)

        backgroundColor = UIColor.ud.bgBody
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        containerView.addSubview(textView)
        containerView.addSubview(moreButton)
        containerView.addSubview(gradientView)
        addSubview(textViewMaskView)
        moreButton.isUserInteractionEnabled = false
        gradientView.isUserInteractionEnabled = false
        textView.isEditable = false
        textView.textDragInteraction?.isEnabled = false

        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(-16)
            make.height.lessThanOrEqualTo(Config.maxHeight)
        }

        textViewMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        moreButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-20)
        }

        gradientView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(textView)
            make.height.equalTo(25)
        }

        moreButton.isHidden = true
        gradientView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAttrText(_ attrText: AttrText?) {
        let attrText = attrText ?? .init()

        textView.attributedText = attrText
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        if textView.contentSize.height > Config.maxHeight {
            moreButton.isHidden = false
            gradientView.isHidden = false
            textView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(-20)
            }
        } else {
            moreButton.isHidden = true
            gradientView.isHidden = true
            textView.snp.updateConstraints {
                $0.bottom.equalToSuperview()
            }
        }
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}

extension DetailNotesEntryView {

    struct Config {
        static let maxHeight: CGFloat = 170.0
    }

}
