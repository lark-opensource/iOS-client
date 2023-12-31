//
//  EnvInfoView.swift
//  LarkAccount
//
//  Created by ByteDance on 2022/7/16.
//

import Foundation
import LarkAccountInterface
import EENavigator
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import UniverseDesignToast


final class EnvInfoView: UIView {
    @Provider var account: AccountService
    private let disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "当前环境信息"
        label.font = UIFont.systemFont(ofSize: Display.phone ? 14 : 24)
        label.textColor = UIColor.white
        label.numberOfLines = 1
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: Display.phone ? 14 : 24, weight: .light)), for: .normal)
        } else {
            button.setImage(UIImage(named: "xmark"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFill
        }
        let size = Display.phone ? CGSize(width: 14, height: 14) : CGSize(width: 24, height: 24)
        button.frame = CGRect(origin: .zero, size: size)
        button.tintColor = UIColor.white
        return button
    }()
    
    @objc private func closeButtonClicked() {
        EnvInfoManager.shared.removeEnvInfoView()
        EnvInfoManager.shared.envInfoManagerDelegate?.updateButtonStatus()
    }
    
    private struct EnvInfoViewUIConfig {
        let labelInterval: Int = 5
        let topPadding: Int = 10
        let leftPadding: Int = 5
        let rightPadding: Int = -5
        let labelArrayCount: Int = 5
    }
    
    private static let uiConfig = EnvInfoViewUIConfig()
    
    private let model = EnvInfoModel()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Display.phone ? 12 : 20)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()
    
    private let textLabelAttributes: [NSAttributedString.Key : Any] = {
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 5
        let attributes = [NSAttributedString.Key.paragraphStyle: paraph]
        return attributes
    }()
    
    init() {
        super.init(frame: .zero)
        setUI()
        textLabel.attributedText = NSAttributedString(string: model.getNewInfo(), attributes: textLabelAttributes)
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(copyInfo)))
        account
            .foregroundUserObservable
            .subscribe(onNext: { [weak self] _ in
                guard let newInfo = self?.model.getNewInfo(),
                      let attributes = self?.textLabelAttributes else {
                    return
                }
                self?.textLabel.attributedText = NSAttributedString(string: newInfo, attributes: attributes)
            })
            .disposed(by: disposeBag)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUI(){
        backgroundColor = UIColor.darkGray.withAlphaComponent(0.6)
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(EnvInfoView.uiConfig.topPadding)
            $0.left.equalTo(EnvInfoView.uiConfig.leftPadding)
        }
        
        addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.size.equalTo(closeButton.frame.size)
            $0.right.equalTo(EnvInfoView.uiConfig.rightPadding)
        }
        
        addSubview(textLabel)
        textLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(EnvInfoView.uiConfig.labelInterval)
            $0.left.equalTo(titleLabel.snp.left)
            $0.right.lessThanOrEqualTo(EnvInfoView.uiConfig.rightPadding)
        }
        
    }
    
    @objc private func copyInfo() {
        UIPasteboard.general.string = model.getNewInfo()
        guard let window = superview else {
            return
        }
        UDToast.showSuccess(with: "复制到粘贴板", on: window)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touche = touches.first
        
        guard let newPlace = touche?.preciseLocation(in: touche?.view?.superview),
              let oldPlace = touche?.previousLocation(in: touche?.view?.superview) else {
            return
        }
        let offsetX = newPlace.x - oldPlace.x
        let offsetY = newPlace.y - oldPlace.y
        let newCGRect = frame.offsetBy(dx: offsetX, dy: offsetY)
        guard let isContain = superview?.frame.contains(newCGRect), isContain else {
            return
        }
        
        EnvInfoManager.shared.changeEnvInfoViewConstraints(rect: newCGRect)
    }
    
}

