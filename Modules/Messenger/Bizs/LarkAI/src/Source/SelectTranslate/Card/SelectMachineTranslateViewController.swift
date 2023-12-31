//
//  SelectMachineTranslateViewController.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/11.
//
import Foundation
import LarkUIKit
import FigmaKit
import LarkContainer
import LarkSDKInterface
import UIKit
import LarkModel
import LarkMessengerInterface
import LarkEMM
import LarkSetting

private enum UI {
    static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    static let headerHeight: CGFloat = 48
    static let sendButtonHeight: CGFloat = 48
    static let sendButtonMargin: CGFloat = 16
    static let gradientViewWidth: CGFloat = 52
    static let labelPadding: CGFloat = 16
    static let originSectionFont: CGFloat = 14

}

final class SelectMachineTranslateViewController: UIViewController {

    let selectText: String
    let translateText: String
    let copyConfig: TranslateCopyConfig
    let userResolver: UserResolver
    var hasClickShowMoreBtn = false

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .ud.bgFloat
        view.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 8.0)
        return view
    }()
    private lazy var originTextTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = NSAttributedString(
            string: BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_SourceText,
            attributes: [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var translateTextTitle: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_Translation,
            attributes: [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )
        return label
    }()

    private lazy var originTextView: UITextView = {
        let textView = ReplicableTextView()
        textView.copyConfig = copyConfig
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineBreakMode = .byTruncatingTail
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22
        textView.attributedText = NSAttributedString(
            string: selectText,
            attributes: [
                .foregroundColor: UIColor.ud.textTitle,
                .font: UIFont.systemFont(ofSize: 16),
                .paragraphStyle: paragraphStyle
            ]
        )
        return textView
    }()

    private lazy var translateTextView: UITextView = {
        let label = ReplicableTextView()
        label.copyConfig = copyConfig
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22
        label.attributedText = NSAttributedString(
            string: translateText,
            attributes: [
                .foregroundColor: UIColor.ud.textTitle,
                .font: UIFont.systemFont(ofSize: 16),
                .paragraphStyle: paragraphStyle
            ]
        )
        return label
    }()

    lazy var gradientView: FKGradientView = {
        let gradientView = FKGradientView()
        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [.ud.bgFloat.withAlphaComponent(0.0), .ud.bgFloat.withAlphaComponent(1)]
        gradientView.direction = .leftToRight
        return gradientView
    }()

    lazy var showMoreBtn: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_ExpandText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.ud.textLinkNormal, for: .normal)
        button.backgroundColor = .ud.bgFloat
        button.addTarget(self, action: #selector(clickShowMoreBtn), for: .touchUpInside)
        return button
    }()

    init(userResolver: UserResolver, selectText: String, translateText: String, copyConfig: TranslateCopyConfig) {
        self.userResolver = userResolver
        self.selectText = selectText
        self.translateText = translateText
        self.copyConfig = copyConfig
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if enableExpandBtnShowByLayoutAgain(), !hasClickShowMoreBtn, showMoreBtn.isHidden, isTruncated(labelText: originTextView.text ?? "") {
            showMoreBtn.isHidden = false
            gradientView.isHidden = false
        }
    }

    @objc
    func clickShowMoreBtn() {
        originTextView.textContainer.maximumNumberOfLines = 100
        /// 修改textView的maximumNumberOfLines之后，uikit无感知，UI也不刷新，因此添加此行
        originTextView.invalidateIntrinsicContentSize()
        showMoreBtn.isHidden = true
        gradientView.isHidden = true
        hasClickShowMoreBtn = true
        view.setNeedsLayout()
    }
}

private extension SelectMachineTranslateViewController {
    /// 布局子试图
    private func setupSubViews() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.addSubview(originTextTitle)
        originTextTitle.snp.makeConstraints {
            $0.leading.top.equalToSuperview().offset(UI.labelPadding)
            $0.trailing.equalToSuperview().offset(-UI.labelPadding).priority(800)
        }
        contentView.addSubview(originTextView)
        originTextView.snp.makeConstraints {
            $0.top.equalTo(originTextTitle.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(UI.labelPadding)
            $0.trailing.equalToSuperview().offset(-UI.labelPadding)
        }

        if enableExpandBtnShowByLayoutAgain() || isTruncated(labelText: originTextView.text ?? "") {
            contentView.addSubview(showMoreBtn)
            showMoreBtn.snp.makeConstraints {
                $0.centerY.equalTo(originTextView.snp.centerY)
                $0.trailing.equalTo(originTextView.snp.trailing)
            }
            contentView.addSubview(gradientView)
            gradientView.snp.makeConstraints {
                $0.centerY.equalTo(originTextView.snp.centerY)
                $0.trailing.equalTo(showMoreBtn.snp.leading)
                $0.height.equalTo(showMoreBtn.snp.height)
                $0.width.equalTo(UI.gradientViewWidth)
            }
            if enableExpandBtnShowByLayoutAgain() {
                showMoreBtn.isHidden = true
                gradientView.isHidden = true
            }
        }
        contentView.addSubview(translateTextTitle)
        translateTextTitle.snp.makeConstraints {
            $0.top.equalTo(originTextView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(UI.labelPadding)
            $0.trailing.equalToSuperview().offset(-UI.labelPadding).priority(800)
        }
        contentView.addSubview(translateTextView)
        translateTextView.snp.makeConstraints {
            $0.top.equalTo(translateTextTitle.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(UI.labelPadding)
            $0.trailing.bottom.equalToSuperview().offset(-UI.labelPadding).priority(800)
        }
    }
    /// 判断文本标签的内容是否被截断
    private func isTruncated(labelText: String) -> Bool {
        /// 计算理论上显示所有文字需要的尺寸
        let labelFont = UIFont.systemFont(ofSize: 16)
        let rect = CGSize(width: view.frame.size.width - UI.labelPadding * 4, height: CGFloat.greatestFiniteMagnitude)
        let labelTextSize = (labelText as NSString)
            .boundingRect(with: rect, options: .usesLineFragmentOrigin,
                          attributes: [.font: labelFont], context: nil)
        //计算理论上需要的行数
        let labelTextLines = Int(ceil(CGFloat(labelTextSize.height) / labelFont.lineHeight))

        //是否需要截断
        return labelTextLines > 1
    }

    private func enableExpandBtnShowByLayoutAgain() -> Bool {
        let aslConfig = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = aslConfig?["enable_expand_btn_show_by_layout_again"] as? Bool {
            return enable
        }
        return true
    }
}
