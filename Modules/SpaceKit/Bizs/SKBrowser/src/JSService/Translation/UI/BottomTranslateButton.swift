//
//  BottomTranslateButton.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/7/18.
//
import UIKit
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift
import LarkContainer

protocol BottomTranslateButtonDelegate: AnyObject {
    func bottomDidSelectDiffLanguage(language: String, displayLanguage: String)
    func clickSeeOrignal()
    func autoDismissSelf()
}
// nolint: duplicated_code
class BottomTranslateButton: UIButton {
    private let disposeBag: DisposeBag = DisposeBag()
    fileprivate lazy var seeOrignalBtn: UIButton = {
        let item: UIButton
        item = UIButton()
        item.addTarget(self, action: #selector(clickSeeOri), for: .touchUpInside)
        item.tintColor = UDColor.N00.withAlphaComponent(0.5)
        item.backgroundColor = UIColor.clear
        item.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        item.setTitleColor(UDColor.primaryContentLoading, for: .highlighted)
        item.titleLabel?.textAlignment = .left
        item.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        item.setTitle(BundleI18n.SKResource.Doc_Translate_ViewOriginal, for: .normal)
        return item
    }()
    private var seeOrignalTextWidth: CGFloat {
        let text = BundleI18n.SKResource.Doc_Translate_ViewOriginal
        let font = UIFont.systemFont(ofSize: 16)
        return text.boundingRect(with: CGSize(width: SKDisplay.activeWindowBounds.width, height: 44),
                                        options: .usesLineFragmentOrigin,
                                        attributes: [NSAttributedString.Key.font: font],
                                        context: nil).size.width
    }

    fileprivate lazy var translateBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(makeLanguageChangeVC), for: .touchUpInside)
        btn.setImage(UDIcon.translateOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        return btn
    }()

    fileprivate lazy var selectLanBtn: UIButton = {
        let lanBtn: UIButton
        lanBtn = UIButton()
        lanBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        lanBtn.setTitleColor(UDColor.textTitle, for: .normal)
        lanBtn.setTitleColor(UDColor.textPlaceholder, for: .highlighted)
        lanBtn.setTitle(BundleI18n.SKResource.Doc_Doc_LanguageJapanese, for: .normal)
        lanBtn.addTarget(self, action: #selector(makeLanguageChangeVC), for: .touchUpInside)
        if SKDisplay.pad {
            lanBtn.addTarget(self, action: #selector(selectTouchDown), for: .touchDown)
            lanBtn.addTarget(self, action: #selector(selectTouchCancel), for: .touchCancel)
            lanBtn.addTarget(self, action: #selector(selectTouchCancel), for: .touchDragExit)
        }
        return lanBtn
    }()

    fileprivate lazy var selectTranslateBtn: UIButton = {
        let btn: UIButton
        btn = UIButton()
        btn.addTarget(self, action: #selector(makeLanguageChangeVC), for: .touchUpInside)
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_expand_down_filled.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_expand_down_filled.ud.withTintColor(UDColor.iconN3), for: .highlighted)
        if SKDisplay.pad {
            btn.addTarget(self, action: #selector(selectTouchDown), for: .touchDown)
            btn.addTarget(self, action: #selector(selectTouchCancel), for: .touchCancel)
            btn.addTarget(self, action: #selector(selectTouchCancel), for: .touchDragExit)
        }
        return btn
    }()

    fileprivate lazy var segmentationView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    fileprivate lazy var iPadSelectView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    weak var delegate: BottomTranslateButtonDelegate?
    private var languages: [String]?
    private var displayLanguages: [String]?
    private var displayIndex: Int?
    private var recentSelectLanguages: [[String: String]]?
    private var isVersion: Bool?

    weak var hostViewController: UIViewController?
    
    private(set) var userResolver: UserResolver?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubviews()
    }

    convenience init(languages: [String],
                     displayLanguages: [String],
                     displayIndex: Int = 0,
                     recentSelectLanguages: [[String: String]],
                     hostViewController: UIViewController?,
                     userResolver: UserResolver,
                     isVersion: Bool? = false) {
        self.init()
        self.userResolver = userResolver
        self.languages = languages
        self.displayLanguages = displayLanguages
        self.recentSelectLanguages = recentSelectLanguages
        self.hostViewController = hostViewController
        self.isVersion = isVersion
        if displayIndex < 0 { //处理特殊情况,当displayIndex小于0，不显示选中选项。
            self.displayIndex = nil
        } else {
            self.displayIndex = displayIndex
        }
        updateSelectLanBtn(index: displayIndex)
    }

    private func setupSubviews() {
        self.backgroundColor = UDColor.bgFloat
        if SKDisplay.pad {
            addSubview(seeOrignalBtn)
            addSubview(iPadSelectView)
            iPadSelectView.addSubview(selectTranslateBtn)
            iPadSelectView.addSubview(selectLanBtn)
            addSubview(segmentationView)
            self.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.layer.ud.setShadowColor(UDColor.N900)
            self.layer.shadowRadius = 8
            self.layer.shadowOpacity = 0.1
            self.layer.cornerRadius = 4
        } else {
            addSubview(seeOrignalBtn)
            addSubview(translateBtn)
            addSubview(selectTranslateBtn)
            addSubview(selectLanBtn)
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.layer.ud.setShadowColor(UDColor.N1000)
            self.layer.shadowRadius = 4
            self.layer.shadowOpacity = 0.1
        }
        setupConstraints()
    }

    private func setupConstraints() {
        if SKDisplay.pad {
            iPadSelectView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.top.bottom.equalToSuperview()
            }
            selectLanBtn.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
            }
            selectTranslateBtn.snp.makeConstraints { (make) in
                make.centerY.right.equalToSuperview()
                make.left.equalTo(selectLanBtn.snp.right)
                make.width.height.equalTo(44)
            }
            segmentationView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(iPadSelectView.snp.right)
                make.width.equalTo(0.5)
                make.height.equalTo(16)
            }
            seeOrignalBtn.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(segmentationView.snp.right).offset(16)
                make.right.equalToSuperview().offset(-16)
                make.width.greaterThanOrEqualTo(seeOrignalTextWidth)
            }
            seeOrignalBtn.docs.addHighlight(with: UIEdgeInsets(top: 0, left: -12, bottom: 0, right: -12), radius: 4)
            iPadSelectView.docs.addHighlight(with: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4), radius: 4)
        } else {
            seeOrignalBtn.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(24)
                make.top.equalToSuperview().offset(0)
                make.height.equalTo(48)
            }
            selectTranslateBtn.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(0)
                make.height.equalTo(48)
            }
            selectLanBtn.snp.makeConstraints { (make) in
                make.right.equalTo(selectTranslateBtn.snp.left).offset(-8)
                make.top.equalToSuperview().offset(0)
                make.height.equalTo(48)
            }
            translateBtn.snp.makeConstraints { (make) in
                make.right.equalTo(selectLanBtn.snp.left).offset(-4)
                make.centerY.equalTo(selectLanBtn.snp.centerY)
                make.width.equalTo(20)
                make.height.equalTo(20)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickSeeOri() {
        self.delegate?.clickSeeOrignal()
    }

    @objc
    private func makeLanguageChangeVC() {
        guard let curLanuages = languages,
              let curDisplayLanguage = displayLanguages,
              let curRecentSelectLanguages = recentSelectLanguages,
              let browserVC = hostViewController as? BrowserViewController else {
            return
        }
        let languageCVC = SelectLanguageController(languages: curLanuages,
                                                   displayLanguages: curDisplayLanguage,
                                                   displayIndex: displayIndex,
                                                   recentSelectLanguages: curRecentSelectLanguages,
                                                   isFromVersion: self.isVersion)
        languageCVC.delegate = self
        if browserVC.docsInfo?.inherentType == .docX {
            languageCVC.supportOrentations = browserVC.supportedInterfaceOrientations
        }
        if SKDisplay.phone {
            languageCVC.modalPresentationStyle = .overFullScreen
        } else {
            languageCVC.setupPopover(sourceView: selectTranslateBtn,
                                     direction: .up)
        }
        self.selectLanBtn.isHighlighted = false
        self.selectTranslateBtn.isHighlighted = false
        self.cancelAutoDismissTimer()
        languageCVC.setUpSelectLanguage { [weak self] in
            guard let self = self else { return }
            let initialImage = BundleResources.SKResource.Common.Tool.icon_expand_down_filled.ud.withTintColor(UDColor.iconN2)
            if let rotateImage = initialImage.sk.rotate(radians: Float.pi) {
                self.selectTranslateBtn.setImage(rotateImage, for: .normal)
            }
        } dismissBlock: { [weak self] in
            guard let self = self else { return }
            self.selectTranslateBtn.setImage(BundleResources.SKResource.Common.Tool.icon_expand_down_filled.ud.withTintColor(UDColor.iconN2), for: .normal)
            self.startAutoDismissTimer()
        }
        userResolver?.navigator.present(
            languageCVC,
            from: browserVC,
            prepare: nil,
            animated: true)
    }

    @objc
    func selectTouchDown() {
        self.selectLanBtn.isHighlighted = true
        self.selectTranslateBtn.isHighlighted = true
    }

    @objc
    func selectTouchCancel() {
        self.selectLanBtn.isHighlighted = false
        self.selectTranslateBtn.isHighlighted = false
    }

    private func updateSelectLanBtn(index: Int) {
        guard index >= 0, index < displayLanguages?.count ?? 0 else {
            DocsLogger.info("BottomTranslateButton btnArray data error")
            selectLanBtn.setTitle(BundleI18n.SKResource.Doc_Translate_ChangeLanguage, for: .normal)
            return
        }
        
        guard let title = displayLanguages?[index] else {
            DocsLogger.info("BottomTranslateButton btnArray data error")
            return
        }
        selectLanBtn.setTitle(title, for: .normal)
    }
}

extension BottomTranslateButton {
    public func startAutoDismissTimer() {
        guard SKDisplay.pad else {
            return
        }
        let delay: Double = 3
        self.cancelAutoDismissTimer()
        self.perform(#selector(type(of: self).autoDimissSelf), with: nil, afterDelay: delay)
    }

    public func cancelAutoDismissTimer() {
        guard SKDisplay.pad else {
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoDimissSelf), object: nil)
    }

    @objc
    func autoDimissSelf() {
        guard SKDisplay.pad else {
            return
        }
        self.delegate?.autoDismissSelf()
    }
}

extension BottomTranslateButton: SelectLanuageControllerDelegate {
    func didSelectDiffLanguage(language: String, displayLanguage: String) {
        self.delegate?.bottomDidSelectDiffLanguage(language: language, displayLanguage: displayLanguage)
        self.selectLanBtn.setTitle(displayLanguage, for: .normal)
    }
}
