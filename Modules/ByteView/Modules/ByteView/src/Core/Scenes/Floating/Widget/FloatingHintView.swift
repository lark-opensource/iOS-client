import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignStyle
import UniverseDesignFont
import SnapKit
import ByteViewCommon

private let shareLoadingHintImg: UIImage = {
    let size = Display.phone ? CGSize(width: 36, height: 36) : CGSize(width: 64, height: 64)
    return UDIcon.getIconByKey(.shareScreenFilled,
                        iconColor: UDColor.iconDisabled,
                        size: size)
}()

func createFloatingShareLoadingHintView() -> UIView {
    let imgView = UIImageView(image: shareLoadingHintImg)
    let view = UIView()
    view.addSubview(imgView)

    if Display.phone {
        imgView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-2.0)
            make.size.equalTo(CGSize(width: 36, height: 36))
        }
    } else {
        InMeetOrientationToolComponent.isLandscapeOrientationRelay
            .subscribe(onNext: { isLandscape in
                imgView.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    if isLandscape {
                        make.size.equalTo(CGSize(width: 54, height: 54))
                        make.centerY.equalToSuperview().offset(-3.5)
                    } else {
                        make.size.equalTo(CGSize(width: 64, height: 64))
                        make.centerY.equalToSuperview().offset(-8.0)
                    }
                }
            })
            .disposed(by: view.rx.disposeBag)
    }

    return view
}

final class FloatingHintView: UIView {
    let hintImageView = UIImageView()
    let hintLabel: UILabel = {
        let hintLabel = UILabel()
        hintLabel.font = UDFont.caption1
        hintLabel.textColor =  UDColor.textCaption
        hintLabel.numberOfLines = 2
        hintLabel.textAlignment = .center
        hintLabel.lineBreakMode = .byTruncatingTail
        return hintLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private static let selfShareScreenHintImg = UDIcon.getIconByKey(.shareScreenFilled, iconColor: UDColor.functionSuccessFillDefault, size: CGSize(width: 32, height: 32))
    static func makeSelfShareScreenHint() -> FloatingHintView {
        let v = FloatingHintView()
        v.hintImageView.image = selfShareScreenHintImg
        v.hintLabel.text = I18n.View_VM_Loading
        return v
    }

    private static let callingHintImg = UDIcon.getIconByKey(.callFilled, iconColor: UDColor.functionSuccessFillDefault, size: CGSize(width: 32, height: 32))
    static func makeCallHintView() -> FloatingHintView {
        let v = FloatingHintView()
        v.hintImageView.image = callingHintImg
        v.hintLabel.text = I18n.View_G_Calling
        return v
    }

    private func setupSubviews() {
        let topSpacer = UILayoutGuide()
        let bottomSpacer = UILayoutGuide()

        self.addLayoutGuide(topSpacer)
        self.addLayoutGuide(bottomSpacer)
        self.addSubview(hintImageView)
        self.addSubview(hintLabel)


        topSpacer.snp.makeConstraints { make in
            make.top.equalToSuperview()
        }
        bottomSpacer.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(topSpacer)
        }

        hintImageView.snp.remakeConstraints { make in
            make.size.equalTo(CGSize(width: 32.0, height: 32.0))
            make.centerX.equalToSuperview()
            make.top.equalTo(topSpacer.snp.bottom)
        }
        hintLabel.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(8.0)
            make.top.equalTo(hintImageView.snp.bottom).offset(4.0)
            make.bottom.equalTo(bottomSpacer.snp.top)
        }
    }
}
