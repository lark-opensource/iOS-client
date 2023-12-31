import UIKit
import UniverseDesignColor
import SnapKit

class FloatingMaskView: UIView {
    let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.backgroundColor = .clear
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDisplayStyle(isPad: Bool) {
        infoLabel.font = UIFont.systemFont(ofSize: isPad ? 14.0 : 12.0)
        infoLabel.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(isPad ? 16.0 : 8.0)
        }
    }

    var infoStatus: String = "" {
        didSet {
            guard self.infoStatus != oldValue else {
                return
            }
            self.infoLabel.text = self.infoStatus
            if self.infoStatus.isEmpty {
                self.isHidden = true
            } else {
                self.isHidden = false
            }
        }
    }

    private func setupSubviews() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.addSubview(infoLabel)
        self.isHidden = true
        infoLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(8.0)
        }
    }
}
