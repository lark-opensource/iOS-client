import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import SnapKit

final class FloatingSkeletonView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        return nil
    }


    let topStatusView = FloatingTopStatusView()
    let userInfoView: InMeetUserInfoView = {
        let view = InMeetUserInfoView()
        view.displayParams = Display.phone ? .floating : .floatingLarge
        return view
    }()

    let contentContainer = UIView()

    private func setupSubviews() {
        self.addSubview(contentContainer)
        self.addSubview(topStatusView)
        self.addSubview(userInfoView)

        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        userInfoView.externalRightInset = 2.0
        userInfoView.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview().inset(2.0)
            make.right.lessThanOrEqualToSuperview().offset(-2.0)
            make.height.equalTo(Display.phone ? 16.0 : 20.0)
        }

        topStatusView.snp.remakeConstraints { make in
            make.left.top.equalToSuperview().inset(2.0)
        }
    }

    var overlayView: UIView? {
        willSet {
            guard newValue !== self.overlayView else {
                return
            }
            overlayView?.removeFromSuperview()
        }

        didSet {
            guard oldValue !== self.overlayView else {
                return
            }
            if let v = self.overlayView {
                self.addSubview(v)
                v.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }

    var contentView: UIView? {
        willSet {
            guard newValue !== self.contentView else {
                return
            }
            contentView?.removeFromSuperview()
        }
        didSet {
            guard oldValue !== self.contentView else {
                return
            }
            if let v = self.contentView {
                self.contentContainer.addSubview(v)
                v.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }

}
