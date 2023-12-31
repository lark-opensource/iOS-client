//
// Created by duanxiaochen.7 on 2022/4/7.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import SKResource

// MARK: - BTRecordFilterView
final class BTRecordFilterView: UIView {
    lazy var leftIconView = UIImageView().construct { it in
        it.contentMode = .scaleAspectFill
        it.image = UDIcon.warningColorful
    }

    lazy var contentLabel = UILabel().construct { it in
        it.text = BundleI18n.SKResource.Doc_Block_RecordFilteredTip
        it.font = UIFont.boldSystemFont(ofSize: 14)
        it.textColor = UDColor.functionWarningContentDefault
    }

    lazy var closeButton = UIButton().construct { it in
        it.addTarget(self, action: #selector(closeButtonClick(sender:)), for: .touchUpInside)
        it.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
    }

    weak var delegate: BTRecordFilterViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLayout() {
        addSubview(leftIconView)
        leftIconView.snp.makeConstraints { it in
            it.width.height.equalTo(16)
            it.left.equalToSuperview().offset(16)
            it.centerY.equalToSuperview()
        }

        addSubview(contentLabel)
        contentLabel.snp.makeConstraints { it in
            it.left.equalTo(self.leftIconView.snp.right).offset(4.5)
            it.right.equalToSuperview().offset(-40.5)
            it.centerY.equalToSuperview()
        }

        addSubview(closeButton)
        closeButton.snp.makeConstraints { it in
            it.width.height.equalTo(16)
            it.right.equalToSuperview().offset(-16)
            it.centerY.equalToSuperview()
        }
    }

    @objc
    func closeButtonClick(sender: UIButton) {
        delegate?.didClickBannerClose()
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 40.0
        return size
    }

}

// MARK: - BTRecordFilterViewDelegate
protocol BTRecordFilterViewDelegate: AnyObject {
    func didClickBannerClose()
}

extension BTRecord: BTRecordFilterViewDelegate {
    func didClickBannerClose() {
        delegate?.didCloseBanner()
    }
}
