//
//  PureSafeModeViewController.swift
//  LarkSafeMode
//
//  Created by luyz on 2023/8/31.
//

import Foundation

final class PureSafeModeViewController : UIViewController {
        
    var mainLabel: UILabel = UILabel()
    var descLabel: UILabel = UILabel()
    var showImage: UIImageView = UIImageView()
    var fixButton: SafeModeButton = SafeModeButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = PureLanguage.pureSafeModeViewTitle
        self.view.backgroundColor = color(242.0, 243.0, 245.0)
        
        mainLabel.text = PureLanguage.pureSafeModeViewDataError
        mainLabel.textAlignment = .center
        mainLabel.font = .systemFont(ofSize: 20, weight: .medium)
        mainLabel.textColor = color(31.0, 35.0, 41.0)
        mainLabel.frame = CGRect(x: 0,
                                 y: self.view.frame.height/2 - 62,
                                 width: self.view.frame.width,
                                 height: 28)
        self.view.addSubview(mainLabel)

        showImage.image = UIImage(named: "emptyNegativeError",
                                  in: SafeModeUDBundleConfig.UniverseDesignEmptyBundle,
                              compatibleWith: nil) ?? UIImage()
        let imageWidth = showImage.image?.size.width ?? 100
        let imageHeight = showImage.image?.size.height ?? 100
        showImage.frame = CGRectMake((self.view.frame.width - imageWidth)/2,
                                     mainLabel.frame.minY - imageHeight - 20,
                                     imageWidth,
                                     imageHeight)
        self.view.addSubview(showImage)
        
        descLabel.textColor = color(156.0, 162.0, 169.0)
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.numberOfLines = 0
        descLabel.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.alignment = .center
        descLabel.attributedText = NSMutableAttributedString(
            string: PureLanguage.pureSafeModeViewDescTitle,
            attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        descLabel.frame = CGRect(x: 0,
                                 y: mainLabel.frame.maxY + 10,
                                 width: self.view.frame.width,
                                 height: 14 * 5)
        self.view.addSubview(descLabel)
        
        fixButton.layer.cornerRadius = 4
        fixButton.backgroundColor = color(51.0, 112.0, 255.0)
        fixButton.titleLabel?.textColor = UIColor.white
        fixButton.setTitleColor(UIColor.lightGray, for: UIControl.State.highlighted)
        fixButton.setTitle(PureLanguage.pureSafeModeViewStartFixTitle, for: .normal)
        fixButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        fixButton.addTarget(self, action: #selector(repair), for: .touchUpInside)
        fixButton.frame = CGRect(x: 16,
                                 y: self.view.frame.height - 90,
                                 width: self.view.frame.width - 16 * 2,
                                 height: 48)
        self.view.addSubview(fixButton)
    }
    
    @objc
    func repair(button: SafeModeButton) {
        if button.currentTitle == PureLanguage.pureSafeModeViewStartFixTitle {
            repairing(button: button)
            DispatchQueue.global().async {
                LarkSafeModeUtil.pureDeepClearAllUserCache()
                DispatchQueue.main.async {
                   self.repaired(button: button)
                }
            }
        } else if button.currentTitle == PureLanguage.pureSafeModeViewGotItTitle {
            exit(0)
        }
    }
    
    func repairing(button: SafeModeButton) {
        mainLabel.text =  PureLanguage.pureSafeModeViewDataFixingTitle
        descLabel.text = ""
        showImage.image = UIImage(named: "emptyNeutralRestoring",
                                  in: SafeModeUDBundleConfig.UniverseDesignEmptyBundle,
                              compatibleWith: nil) ?? UIImage()
        button.setTitle(PureLanguage.pureSafeModeViewDataFixingButtonTitle, for: .normal)
        button.showLoading()
    }
    
    func repaired(button: SafeModeButton) {
        mainLabel.text = PureLanguage.pureSafeModeViewRestartTitle
        showImage.image = UIImage(named: "emptyPositiveComplete",
                              in: SafeModeUDBundleConfig.UniverseDesignEmptyBundle,
                          compatibleWith: nil) ?? UIImage()
        button.setTitle(PureLanguage.pureSafeModeViewGotItTitle, for: .normal)

        button.hideLoading()
    }
    
    func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}
