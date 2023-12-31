//
//  MailReadTitleView.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/7/13.
//

import Foundation
import SnapKit
import UniverseDesignTag
import LarkWebviewNativeComponent
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import RxSwift
import UniverseDesignNotice
import UniverseDesignFont
import UniverseDesignTheme
import ThreadSafeDataStructure

protocol MailReadTitleViewDelegate: AnyObject {
    var imageService: MailImageService? { get }
    var configurationProvider: ConfigurationProxy? { get }
    func subjectTap(_ showPopover: Bool, customText: String?, popverTitle: String)
    func titleLabelsTapped()
    func flagTapped()
    func desiredHeightChanged(_ newHeight: CGFloat, completion: (() -> Void)?)
    func scrollTo(_ rect: CGRect)
	func subjectDidCopy()
    func notSpamTapped()
    func nativeTitleViewDidInsert()
    func bannerTermsAction()
    func bannerSupportAction()
}

struct TitleLayoutKey: Equatable, Hashable {
    var config: MailReadTitleViewConfig
    var width: CGFloat
    static func == (lhs: TitleLayoutKey, rhs: TitleLayoutKey) -> Bool {
        return lhs.config == rhs.config && lhs.width == rhs.width
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(config.title)
        hasher.combine(config.labels)
    }
}

struct MailReadTitleViewConfig: Equatable {
    
    static func == (lhs: MailReadTitleViewConfig, rhs: MailReadTitleViewConfig) -> Bool {
        return lhs.title == rhs.title &&
        lhs.fromLabel == rhs.fromLabel &&
        lhs.labels == rhs.labels &&
        lhs.isExternal == rhs.isExternal &&
        lhs.translatedInfo?.translatedTitle == rhs.translatedInfo?.translatedTitle &&
        lhs.translatedInfo?.onlyTranslation == rhs.translatedInfo?.onlyTranslation &&
        lhs.coverImageInfo?.subjectCover == rhs.coverImageInfo?.subjectCover &&
        lhs.keyword == rhs.keyword &&
        lhs.subjects == rhs.subjects &&
        lhs.spamMailTip == rhs.spamMailTip &&
        lhs.needBanner == rhs.needBanner
    }
    
    typealias TranslatedTitleInfo = (translatedTitle: String, onlyTranslation: Bool)
    /// 封面信息
    struct CoverImageInfo {
        var subjectCover: MailSubjectCover
    }

    let title: String
    let fromLabel: String
    let labels: [MailClientLabel]
    let isExternal: Bool
    let translatedInfo: TranslatedTitleInfo?
    let coverImageInfo: CoverImageInfo?
    let keyword: String
    let subjects: [String]
    let spamMailTip: String
    let needBanner: Bool

    var titleType: MailReadTitleView.TitleType {
        return coverImageInfo == nil ? .normalTitle : .coverTitle
    }

    static var test: Bool = true

    init(title: String,
         fromLabel: String,
         labels: [MailClientLabel],
         isExternal: Bool,
         translatedInfo: TranslatedTitleInfo?,
         coverImageInfo: CoverImageInfo?,
         spamMailTip: String,
         needBanner: Bool = false,
         keyword: String = "",
         subjects: [String] = []) {
        self.title = title
        self.fromLabel = fromLabel
        self.labels = labels
        self.isExternal = isExternal
        self.translatedInfo = translatedInfo
        self.coverImageInfo = coverImageInfo
        self.spamMailTip = spamMailTip
        self.needBanner = needBanner
        self.keyword = keyword
        self.subjects = subjects
    }
}

class MailReadTitleView: UIView, MailCoverDisplayViewDelegate, MailTextViewCopyDelegate {
    
    
    enum TitleType {
        case normalTitle
        case coverTitle
    }

    var disposeBag = DisposeBag()

    private var titleType: TitleType
    private var needLayoutLabels = true
    private let titleLabel = MailBaseTextView()
    private var initCoverViewFlag = false
    var initSpamNoticeFlag = false
    var config: MailReadTitleViewConfig?
    private lazy var coverTitleView: MailCoverDisplayView = {
        let view = MailCoverDisplayView(frame: .zero, priorityEnable: false)
        view.delegate = self
        view.copyDelegate = self
        view.isEditable = false
        return view
    }()
    private(set) var threadID = ""
    private(set) var filteredLabels = [MailClientLabel]()
    private(set) var fromLabel = ""
    private(set) var labelTags = [MailReadTag]()
    private(set) var observation: NSKeyValueObservation?
    private var labelHeight: CGFloat?
    private(set) var translatedInfo: MailReadTitleViewConfig.TranslatedTitleInfo?
    private(set) var title: String?
    private(set) var isExternal = false
    private(set) var coverImageInfo: MailReadTitleViewConfig.CoverImageInfo?
    private(set) lazy var coverVM = MailCoverDisplayViewModel(scene: .MailRead,
                                                              photoProvider: OfficialCoverPhotoDataProvider(configurationProvider: delegate?.configurationProvider, imageService: delegate?.imageService))
    private var currentLabelInfos = [LabelDisplayInfo]()
    private var keyword = ""
    private var subjects: [String] = []
    private let spamMailTip: String
    private var titleHighlight = false
    private(set) lazy var spamNotice: UIView = {
        let attrStr = NSMutableAttributedString(
            string: spamMailTip,
            attributes: [.foregroundColor: UIColor.ud.textTitle]
        )
        var config = UDNoticeUIConfig(type: .info, attributedText: attrStr)
        config.leadingButtonText = BundleI18n.MailSDK.Mail_NotSpam_Button
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        return view
    }()

    private lazy var bannerView = FilePreviewBannerView()
    private var needBanner: Bool

    
    private var shouldShowSpamNotice: Bool {
        MailReadTitleView.newSpamPolicyEnable && fromLabel == Mail_LabelId_Spam && !spamMailTip.isEmpty
    }
    static let darkModeEnable = FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true))
    static let newSpamPolicyEnable = FeatureManager.open(.newSpamPolicy, openInMailClient: true)
    static var layoutMap = ThreadSafeDataStructure.SafeDictionary<TitleLayoutKey, TitleViewSizeInfo>(synchronization: .readWriteLock)

    var showingPopover = false
    /// 通过 updateDesiredSize 更新，并调用 js 更新容器高度
    private(set) var desiredSize: CGSize = .zero
    var lastLayoutSize: CGSize?
    var lastSpamBannerHeight: CGFloat = 0

    weak var delegate: MailReadTitleViewDelegate?

    required convenience init() {
        self.init(config: MailReadTitleViewConfig(title: "",
                                                  fromLabel: "",
                                                  labels: [],
                                                  isExternal: false,
                                                  translatedInfo: nil,
                                                  coverImageInfo: nil,
                                                  spamMailTip: ""),
                  containerWidth: UIScreen.main.bounds.width,
                  delegate: nil)
    }

    func updateDesiredSize(_ newSize: CGSize, completion: (() -> Void)? = nil) {
        let oldSize = desiredSize
        desiredSize = newSize
        if oldSize.height == 0 || newSize.height != oldSize.height {
            delegate?.desiredHeightChanged(newSize.height, completion: completion)
        } else {
            completion?()
        }
    }

    init(config: MailReadTitleViewConfig,
         containerWidth: CGFloat,
         delegate: MailReadTitleViewDelegate?) {
        self.fromLabel = config.fromLabel
        self.delegate = delegate
        self.title = config.title
        self.isExternal = config.isExternal
        self.translatedInfo = config.translatedInfo
        self.coverImageInfo = config.coverImageInfo
        // 如果有封面信息要用封面标题布局
        self.titleType = config.titleType
        self.keyword = config.keyword
        self.subjects = config.subjects
        // 垃圾邮件顶部提示
        self.spamMailTip = config.spamMailTip
        self.needBanner = config.needBanner
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        if MailReadTitleView.darkModeEnable, #available(iOS 13.0, *) {
            backgroundColor = UDColor.readMsgListBG
        } else {
            backgroundColor = UIColor.ud.bgBase.alwaysLight
        }

        if shouldShowSpamNotice {
            initSpamNotice()
        }

        if self.needBanner {
            addSubview(bannerView)
            bannerView.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
            }
            bannerView.termsAction = self.delegate?.bannerTermsAction
            bannerView.supportAction = self.delegate?.bannerSupportAction
        }

        titleLabel.copyDelegate = self
        titleLabel.font = MailReadTitleView.titleFont
        titleLabel.isEditable = false
        titleLabel.textContainerInset = .zero
        titleLabel.contentInset = .zero
        titleLabel.contentInsetAdjustmentBehavior = .never
        titleLabel.textContainer.lineFragmentPadding = 0
        titleLabel.backgroundColor = .clear
        titleLabel.isScrollEnabled = false
        addSubview(titleLabel)

        

        if titleType == .coverTitle {
            titleLabel.isHidden = true
            initCoverView()
        } else {
            titleLabel.isHidden = false
        }

        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTitleTap)))
        updateUI(config: config)
    }
    
    func initCoverView() {
        initCoverViewFlag = true
        coverTitleView.bind(viewModel: coverVM)
        addSubview(coverTitleView)
        coverTitleView.textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleCoverTitleTap)))
        coverTitleView.subTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleCoverTitleTap)))
        coverTitleView.isHidden = false
    }
    func initSpamNotice() {
        initSpamNoticeFlag = true
        spamNotice.isHidden = false
        addSubview(spamNotice)
        spamNotice.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.greaterThanOrEqualTo(44)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if titleType == .coverTitle {
            layoutSubviewsCover()
        } else {
            layoutSubviewsNormal()
        }
    }

    func textViewDidCopy() {
        delegate?.subjectDidCopy()
    }

    private func layoutSubviewsNormal() {
        if lastLayoutSize != bounds.size {
            needLayoutLabels = true
        }
        if shouldShowSpamNotice && lastSpamBannerHeight != spamNotice.frame.height {
            needLayoutLabels = true
        }
        layoutLabelTags()
        var inset = MailReadTitleView.titleLabelInsets()

        if shouldShowSpamNotice {
            inset.top += spamNotice.frame.height
        }
        if needBanner {
            inset.top += bannerView.frame.height
        }

        let labelSize: CGSize
        if let labelHeight = labelHeight {
            labelSize = CGSize(width: bounds.width - inset.left - inset.right, height: labelHeight)
            titleLabel.frame = CGRect(x: inset.left, y: inset.top, width: labelSize.width, height: labelSize.height)
        } else {
            labelSize = titleLabel.sizeThatFits(CGSize(width: bounds.width - inset.left - inset.right, height: .greatestFiniteMagnitude))
        }
        titleLabel.frame = CGRect(x: inset.left, y: inset.top, width: labelSize.width, height: labelSize.height)
    }

    private func layoutSubviewsCover() {
        let config = MailReadTitleViewConfig(title: title ?? "",
                                             fromLabel: fromLabel,
                                             labels: filteredLabels,
                                             isExternal: isExternal,
                                             translatedInfo: translatedInfo,
                                             coverImageInfo: coverImageInfo,
                                             spamMailTip: spamMailTip,
                                             needBanner: needBanner,
                                             keyword: keyword,
                                             subjects: subjects)
        let layoutInfo = Self.calcViewSizeAndLabelsFrame(config: config,
                                                         attributedString: nil,
                                                         containerWidth: frame.width)

        
        var originY:CGFloat = 0
        if shouldShowSpamNotice {
            let spamHeight = spamNotice.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude)).height
            originY = spamHeight
        }
        originY += needBanner ? bannerView.frame.height : 0
        self.coverTitleView.frame = CGRect(x: 0, y: originY, width: layoutInfo.viewSize.width,
                                           height: layoutInfo.labelHeight)

        updateDesiredSize(layoutInfo.viewSize)

        for tag in labelTags {
            tag.removeFromSuperview()
        }
        labelTags.removeAll()

        for info in layoutInfo.labelInfos {
            let tag = MailReadTag(text: info.labelName,
                                  isLTR: info.isLTR,
                                  textColor: info.textColor,
                                  backgroundColor: info.bgColor)
            tag.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tagTapped(_:))))
            tag.frame = CGRect(origin: CGPoint(x: info.frame.origin.x, y: info.frame.origin.y + originY),
                               size: info.frame.size)
            labelTags.append(tag)
            addSubview(tag)
        }
        needLayoutLabels = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTitleTap() {
        if let translatedInfo = translatedInfo, translatedInfo.onlyTranslation, let attributedTitle = titleLabel.attributedText {
            showingPopover = !showingPopover
            let attrString = NSMutableAttributedString(attributedString: attributedTitle)
            let range = (attrString.string as NSString).range(of: attrString.string)
            attrString.addAttributes([.backgroundColor: UIColor.ud.N900.withAlphaComponent(0.1)], range: range)
            titleLabel.attributedText = attrString
            delegate?.subjectTap(showingPopover, customText: nil,
                                 popverTitle: BundleI18n.MailSDK.Mail_Translations_OriginalText)
            setNeedsLayout()
        }
    }

    private enum TitlePopoverType {
        case none ///
        case original
        case originalAndTranslated
        case translatedAndOriginal
    }

    private func judgeTitlePopoverType() -> TitlePopoverType {
        var type = TitlePopoverType.none
        // 有翻译的情况下
        if let translatedInfo = translatedInfo {
            // 只显示译文
            if translatedInfo.onlyTranslation {
                if coverTitleView.isTextFolding {
                    type = .translatedAndOriginal
                } else {
                    type = .original
                }
            } else {
                if coverTitleView.isTextFolding {
                    type = .originalAndTranslated
                }
            }
        } else {
            // 没有翻译的情况下，没展示完，要展示
            if coverTitleView.isTextFolding {
                type = .original
            }
        }
        return type
    }

    @objc
    /// 点击封面标题的，不确定后续是否分化逻辑。所以先开另一个函数
    private func handleCoverTitleTap() {
        let type = judgeTitlePopoverType()
        if type != .none {
            showingPopover = !showingPopover
            var popverTitleTitle = BundleI18n.MailSDK.Mail_Translations_OriginalText
            if type == .original {
                if let translatedInfo = translatedInfo, !translatedInfo.translatedTitle.isEmpty {
                    popverTitleTitle = BundleI18n.MailSDK.Mail_Translations_OriginalText
                } else {
                    popverTitleTitle = BundleI18n.MailSDK.Mail_Cover_MobileSubjectDetails
                }
            } else if type == .translatedAndOriginal {
                popverTitleTitle = BundleI18n.MailSDK.Mail_Cover_MobileSubjectDetailsSourceText
            } else if type == .originalAndTranslated {
                popverTitleTitle = BundleI18n.MailSDK.Mail_Cover_MobileSubjectDetails
            }

            if coverTitleView.currentTextType == .attributeTextAndSubText {
                if let attributedTitle = coverTitleView.textView.attributedText,
                    let subAttributedTitle = coverTitleView.subTextView.attributedText {
                    let attrString = NSMutableAttributedString(attributedString: attributedTitle)
                    let range = (attrString.string as NSString).range(of: attrString.string)
                    attrString.addAttributes([.backgroundColor: UIColor.ud.N900.withAlphaComponent(0.1)], range: range)
                    let subAttrString = NSMutableAttributedString(attributedString: subAttributedTitle)
                    let subRange = (subAttrString.string as NSString).range(of: subAttrString.string)
                    subAttrString.addAttributes([.backgroundColor: UIColor.ud.N900.withAlphaComponent(0.1)],
                                                range: subRange)
                    self.coverTitleView.updateContent(title: attrString, subTitle: subAttrString)
                    let text = attributedTitle.string + "\n" + subAttributedTitle.string
                    delegate?.subjectTap(showingPopover,
                                         customText: text,
                                         popverTitle: popverTitleTitle)
                    setNeedsLayout()
                }
            } else {
                if let attributedTitle = coverTitleView.textView.attributedText {
                    var text: String? = ""
                    if type == .original {
                        text = title
                    } else if type == .translatedAndOriginal {
                        text = (translatedInfo?.translatedTitle ?? "") + "\n" + (title ?? "")
                    } else if type == .originalAndTranslated {
                        text = (title ?? "") + "\n" + (translatedInfo?.translatedTitle ?? "")
                    }

                    let attrString = NSMutableAttributedString(attributedString: attributedTitle)
                    let range = (attrString.string as NSString).range(of: attrString.string)
                    attrString.addAttributes([.backgroundColor: UIColor.ud.N900.withAlphaComponent(0.1)], range: range)
                    self.coverTitleView.updateContent(attrString)
                    delegate?.subjectTap(showingPopover, customText: text,
                                         popverTitle: popverTitleTitle)
                    setNeedsLayout()
                }
            }
        }
    }

    func dismissCoverTitleBackground() {
        if var info = coverImageInfo {
            let (text, subText, isHighlighted) = MailReadTitleView.coverTitleAttributedString(title: self.title ?? "",
                                                               translatedInfo: self.translatedInfo,
                                                               customColor: info.subjectCover.subjectColor)
            self.titleHighlight = isHighlighted
            if let sub = subText {
                self.coverTitleView.updateContent(title: text, subTitle: sub)
            } else {
                self.coverTitleView.updateContent(text)
            }
        }
    }

    func updateUI(config: MailReadTitleViewConfig) {
        self.config = config
        self.titleType = config.titleType
        if titleType == .coverTitle {
            titleLabel.isHidden = true
            if coverTitleView.superview == nil {
                initCoverView()
            } else {
                coverTitleView.isHidden = false
            }
        } else {
            if initCoverViewFlag {
                coverTitleView.isHidden = true
            }
            titleLabel.isHidden = false
        }
        if shouldShowSpamNotice {
            if !initSpamNoticeFlag {
                initSpamNotice()
            } else {
                spamNotice.isHidden = false
            }
        } else if initSpamNoticeFlag {
            spamNotice.isHidden = true
        }
        self.coverImageInfo = config.coverImageInfo
        self.title = config.title
        self.keyword = config.keyword
        self.subjects = config.subjects

        var translatedInfo = config.translatedInfo
        if let translatedTitle = translatedInfo?.translatedTitle {
            translatedInfo?.translatedTitle = translatedTitle.components(separatedBy: .newlines).joined(separator: " ")
        }
        if let translatedInfo = translatedInfo, !translatedInfo.translatedTitle.isEmpty {
            self.translatedInfo = translatedInfo
        } else {
            self.translatedInfo = nil
        }

        let attributedText: NSAttributedString
        if let info = coverImageInfo {
            let (text, subText, isHighlighted) = MailReadTitleView.coverTitleAttributedString(title: self.title ?? config.title,
                                                                               translatedInfo: self.translatedInfo,
                                                                               customColor: coverImageInfo?.subjectCover.subjectColor ?? Self.getTitleColor(title ?? ""),
                                                                               keyword: keyword, subjects: subjects)
            self.titleHighlight = isHighlighted
            self.coverVM.updateCoverState(.loading(info.subjectCover))
            if let sub = subText {
                self.coverTitleView.updateContent(title: text, subTitle: sub)
            } else {
                self.coverTitleView.updateContent(text)
            }
            attributedText = text
            titleLabel.attributedText = text
        } else {
            let text = MailReadTitleView.titleAttributedString(title: self.title ?? config.title,
                                                               translatedInfo: self.translatedInfo,
                                                               customColor: coverImageInfo?.subjectCover.subjectColor ?? Self.getTitleColor(title ?? ""),
                                                               keyword: keyword, subjects: subjects)
            attributedText = text
        }

        let updateAttributedText = { [weak self] in
            guard let self = self else { return }
            self.titleLabel.attributedText = attributedText
            self.updateLabels(config.labels, fromLabel: config.fromLabel, isExternal: config.isExternal)
        }

        if bounds.width != 0 {
            // 先更新jsheader高度，再更新native title文字，避免跳动明显
            let info = MailReadTitleView.calcViewSizeAndLabelsFrame(config: config,
                                                                    attributedString: attributedText,
                                                                    containerWidth: bounds.width)
            labelHeight = info.labelHeight
            updateDesiredSize(info.viewSize) {
                updateAttributedText()
            }
        } else {
            // bounds.width为0时size计算不准确，直接更新text
            updateAttributedText()
        }
    }

    func updateLabels(_ labels: [MailClientLabel], fromLabel: String, isExternal: Bool) {
        self.fromLabel = fromLabel
        self.isExternal = isExternal
        filteredLabels = labels.filter({ $0.id != Mail_LabelId_UNREAD && $0.id != Mail_LabelId_Unknow })
        forceLayout()
    }

    private func forceLayout() {
        needLayoutLabels = true
        setNeedsLayout()
    }

    @objc
    func tagTapped(_ ges: UITapGestureRecognizer) {
        delegate?.titleLabelsTapped()
    }

    @objc
    func flagTapped(_ ges: UITapGestureRecognizer) {
        delegate?.flagTapped()
    }

    func sizeToFit(with newSize: CGSize) -> CGSize {
        let config = MailReadTitleViewConfig(title: titleLabel.text ?? "",
                                             fromLabel: fromLabel,
                                             labels: filteredLabels,
                                             isExternal: isExternal,
                                             translatedInfo: translatedInfo,
                                             coverImageInfo: coverImageInfo,
                                             spamMailTip: spamMailTip,
                                             needBanner: needBanner,
                                             keyword: keyword,
                                             subjects: subjects)
        return MailReadTitleView.calcViewSizeAndLabelsFrame(config: config,
                                                            attributedString: titleLabel.attributedText,
                                                            containerWidth: newSize.width).viewSize
    }

    func updateNativeTitleUI(searchKey: String?, locateIdx: Int?) {
        let searchKey = searchKey?.lowercased()

        let titleStr = title ?? ""

        if titleType == .coverTitle { // 是封面的layout
            let (titleAttr, subAttr, isHighlighted) = MailReadTitleView
                .coverTitleAttributedString(title: titleStr,
                                            translatedInfo: translatedInfo,
                                            customColor: coverImageInfo?.subjectCover.subjectColor ?? Self.getTitleColor(titleStr),
                                            keyword: keyword)
            self.titleHighlight = isHighlighted
            let (attr, selectedRange) = addSearchKeyword(attributeText: titleAttr,
                                                         searchKey: searchKey, locateIdx: locateIdx)

            if let sub = subAttr {
                let (subAttr, subSelectedRange) = addSearchKeyword(attributeText: sub,
                                                             searchKey: searchKey, locateIdx: locateIdx)
                self.coverTitleView.updateContent(title: attr, subTitle: subAttr)
                if let selectedRange = selectedRange, let rect = rectForRangeInCoverTitle(range: selectedRange) {
                    let locateRect = coverTitleView.textView.convert(rect, to: self)
                    delegate?.scrollTo(locateRect)
                } else if let selectedRange = subSelectedRange, let rect = rectForRangeInCoverTitle(range: selectedRange) {
                    let locateRect = coverTitleView.subTextView.convert(rect, to: self)
                    delegate?.scrollTo(locateRect)
                }
            } else {
                self.coverTitleView.updateContent(attr)
                if let selectedRange = selectedRange, let rect = rectForRangeInCoverTitle(range: selectedRange) {
                    let locateRect = coverTitleView.textView.convert(rect, to: self)
                    delegate?.scrollTo(locateRect)
                }
            }
        } else { // 正常标题的layout
            let titleStr = title ?? ""
            let titleAttr = MailReadTitleView.titleAttributedString(title: titleStr,
                                                                    translatedInfo: translatedInfo,
                                                                    customColor: coverImageInfo?.subjectCover.subjectColor ?? Self.getTitleColor(titleStr),
                                                                    keyword: keyword)
            let (attr, selectedRange) = addSearchKeyword(attributeText: titleAttr,
                                                         searchKey: searchKey, locateIdx: locateIdx)
            titleLabel.attributedText = attr
            if let selectedRange = selectedRange, let rect = rectForRangeInTitle(range: selectedRange) {
                let locateRect = titleLabel.convert(rect, to: self)
                delegate?.scrollTo(locateRect)
            }
        }
        forceLayout()
    }

    private func addSearchKeyword(attributeText: NSAttributedString,
                                  searchKey: String?,
                                  locateIdx: Int?) -> (NSAttributedString, NSRange?) {
        let attr = NSMutableAttributedString(attributedString: attributeText)
        var selectedRange: NSRange?
        if let searchKey = searchKey, !searchKey.isEmpty {
            let string = attr.string as NSString
            var searchRange = NSRange(location: 0, length: string.length)
            var foundRange: NSRange?
            var currnetIdx = 0
            while searchRange.location < string.length {
                searchRange.length = string.length - searchRange.location
                foundRange = string.range(of: searchKey, options: [.caseInsensitive], range: searchRange)
                if let foundRange = foundRange, foundRange.location != NSNotFound {
                    let color: UIColor
                    if currnetIdx == locateIdx {
                        selectedRange = foundRange
                        color = UDColor.O350
                    } else {
                        color = UDColor.O200
                    }
                    // UX：搜索时无论当前是否darkMode，文字一律设置为黑色
                    attr.addAttributes([.backgroundColor: color, .foregroundColor: UIColor.ud.N900.alwaysLight], range: foundRange)
                    searchRange.location = foundRange.location + foundRange.length
                    currnetIdx += 1
                } else {
                    break
                }
            }
        }
        return (attr, selectedRange)
    }

    private func layoutLabelTags() {
        guard needLayoutLabels,
              let text = titleLabel.text,
              let attributedString = titleLabel.attributedText else {
            return
        }
        lastLayoutSize = bounds.size
        let config = MailReadTitleViewConfig(title: text,
                                             fromLabel: fromLabel,
                                             labels: filteredLabels,
                                             isExternal: isExternal,
                                             translatedInfo: translatedInfo,
                                             coverImageInfo: coverImageInfo,
                                             spamMailTip: spamMailTip,
                                             needBanner: needBanner,
                                             keyword: keyword,
                                             subjects: subjects)
        let (viewSize,
             titleHeight,
             labelInfos) = MailReadTitleView.calcViewSizeAndLabelsFrame(config: config,
                                                                        attributedString: attributedString,
                                                                        containerWidth: bounds.width)

        var spamHeight: CGFloat = 0
        if shouldShowSpamNotice {
            spamHeight = spamNotice.bounds.height
        }

        labelHeight = titleHeight
        updateDesiredSize(viewSize)

        if currentLabelInfos != labelInfos || lastSpamBannerHeight != spamHeight {
            currentLabelInfos = labelInfos
            lastSpamBannerHeight = spamHeight

            for tag in labelTags {
                tag.removeFromSuperview()
            }
            labelTags.removeAll()
            currentLabelInfos = labelInfos
            var originY = spamHeight
            originY += needBanner ? bannerView.frame.height : 0

            for info in labelInfos {
                let tag = MailReadTag(text: info.labelName,
                                      isLTR: info.isLTR,
                                      textColor: info.textColor,
                                      backgroundColor: info.bgColor)
                tag.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tagTapped(_:))))
                tag.frame = CGRect(origin: CGPoint(x: info.frame.origin.x, y: info.frame.origin.y + originY),
                                   size: info.frame.size)
                labelTags.append(tag)
                addSubview(tag)
            }
        }

        needLayoutLabels = false
    }

    static func titleAttributes(_ titleColor: UIColor) -> [NSAttributedString.Key: Any]? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        return [.font: titleFont,
                .kern: -0.5,
                .foregroundColor: titleColor,
                .paragraphStyle: paragraphStyle]
    }


    /// 计算无封面标题时的选中位置
    /// - Parameter range: range description
    /// - Returns: description
    private func rectForRangeInTitle(range: NSRange) -> CGRect? {
        guard let title = titleLabel.text, !title.isEmpty else { return nil }
        guard range.location + range.length <= (title as NSString).length else { return nil }
        guard let attributedString = titleLabel.attributedText else { return nil }
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: titleLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }


    /// 有封面标题时的选中位置
    /// - Parameter range: range description
    /// - Returns: description
    private func rectForRangeInCoverTitle(range: NSRange) -> CGRect? {
        guard let title = title, !title.isEmpty else { return nil }
        guard range.location + range.length <= (title as NSString).length else { return nil }
        guard let attributedString = coverTitleView.textView.attributedText else { return nil }
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: coverTitleView.textView.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }

    func didTapReloadCover(_ cover: MailSubjectCover?) {
        coverVM.updateCoverState(.loading(cover))
    }

    func isTitleHighlighted() -> Bool {
        return self.titleHighlight
    }

    func focusNextInputView(currentView: UIView) {}
    
    func subjectViewChangeText() {}

    func registerTabKey(currentView: UIView) {}

    func unregisterTabKey(currentView: UIView) {}

    // MARK: Layout相关
    typealias TitleViewSizeInfo = (viewSize: CGSize, labelHeight: CGFloat, labelInfos: [LabelDisplayInfo])

    /// 计算获得view相关尺寸
    static func calcViewSizeAndLabelsFrame(config: MailReadTitleViewConfig,
                                           attributedString: NSAttributedString?,
                                           containerWidth: CGFloat) -> TitleViewSizeInfo {
        let layoutkey = TitleLayoutKey(config: config, width: containerWidth)
        if MailMessageListViewsPool.fpsOpt {
            if let info = MailReadTitleView.layoutMap[layoutkey] {
                return info
            }
        }
        var info: TitleViewSizeInfo
        if config.titleType == .coverTitle {
            info = MailReadTitleViewCoverTitleLayout.calcViewSizeAndLabelsFrame(config: config,
                                                                                attributedString: attributedString,
                                                                                containerWidth: containerWidth)
        } else {
            info = MailReadTitleViewNormalLayout.calcViewSizeAndLabelsFrame(config: config,
                                                                            attributedString: attributedString,
                                                                            containerWidth: containerWidth)
        }

        if MailReadTitleView.newSpamPolicyEnable,
           config.fromLabel == Mail_LabelId_Spam,
           !config.spamMailTip.isEmpty
        {
            let height = UDNotice.calNoticeHeight(text: config.spamMailTip,
                                                  actionText: BundleI18n.MailSDK.Mail_NotSpam_Button,
                                                  containerWidth: containerWidth)

            info.viewSize.height += height
        }

        if config.needBanner {
            let height = UDNotice.calNoticeHeight(text: BundleI18n.MailSDK.Mail_UserAgreementViolated_Banner(BundleI18n.MailSDK.Mail_UserAgreementViolated_UserAgreement_Banner()),
                                                  actionText: BundleI18n.MailSDK.Mail_UserAgreementViolated_ContactSupport_Button,
                                                  containerWidth: containerWidth)
            info.viewSize.height += height
        }
        if MailMessageListViewsPool.fpsOpt {
            MailReadTitleView.layoutMap[layoutkey] = info
        }
        return info
    }
}

extension MailReadTitleView: NativeComponentAble {
    var nativeView: UIView {
        return self
    }

    static var tagName: String {
        return "lk-native-title"
    }

    func willInsertComponent(params: [String: Any]) {
    }

    func didInsertComponent(params: [String: Any]) {
        delegate?.nativeTitleViewDidInsert()
        self.translatesAutoresizingMaskIntoConstraints = true
        if let scrollView = self.superview as? UIScrollView {
            self.frame = CGRect(x: 0, y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height)
            observation = scrollView.observe(\.contentSize, options: [.new, .old], changeHandler: { _, change in
                if let new = change.newValue {
                    self.frame = CGRect(x: 0, y: 0, width: new.width, height: new.height)
                }
            })
        }
    }

    func updateCompoent(params: [String: Any]) {

    }

    func willBeRemovedComponent(params: [String: Any]) {

    }
}

// MARK: 通用布局参数

extension MailReadTitleView {
    static let titleFont = UIFont.systemFont(ofSize: 20, weight: .medium)
    static let flagIconSize = CGSize(width: 20, height: 20)
    static let flagIconRightMargin: CGFloat = 16
    static func titleLabelInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    static func getTitleColor(_ title: String) -> UIColor {
        if MailReadTitleView.darkModeEnable, #available(iOS 13.0, *) {
            return UIColor.ud.textTitle
        } else {
            return UIColor.ud.textTitle.alwaysLight
        }

    }

    static func titleAttributedString(title: String,
                                      translatedInfo: MailReadTitleViewConfig.TranslatedTitleInfo?,
                                      customColor: UIColor? = nil,
                                      keyword: String? = nil,
                                      subjects: [String] = []) -> NSAttributedString {
        let titleColor = customColor ?? getTitleColor(title)
        let titleAttributedString: NSMutableAttributedString
        if let translatedInfo = translatedInfo {
            if translatedInfo.onlyTranslation {
                titleAttributedString = NSMutableAttributedString(string: translatedInfo.translatedTitle, attributes: titleAttributes(titleColor))
            } else {
                // 加分隔符
                let title = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes(titleColor))
                let translated = NSAttributedString(string: translatedInfo.translatedTitle, attributes: titleAttributes(titleColor))
                title.append(translated)
                titleAttributedString = title
            }
        } else {
            titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes(titleColor))
        }

        if let wholeKeyword = keyword, !wholeKeyword.isEmpty {
            addKeywordHighlight(text: titleAttributedString, keyword: wholeKeyword)
        }
        for filterSubject in subjects {
            addKeywordHighlight(text: titleAttributedString, keyword: filterSubject)
        }

        return titleAttributedString
    }

    @discardableResult
    private static func addKeywordHighlight(text: NSMutableAttributedString,
                                            keyword: String) -> (NSMutableAttributedString, Bool) {
        var isHighlighted = false
        let wholeKeyword = keyword
        wholeKeyword.split(separator: " ").forEach { sub in
            let subKeyword = String(sub)
            let string = text.string as NSString
            var searchRange = NSRange(location: 0, length: string.length)
            var foundRange: NSRange?
            var currnetIdx = 0
            while searchRange.location < string.length {
                searchRange.length = string.length - searchRange.location
                foundRange = string.range(of: subKeyword, options: [.caseInsensitive], range: searchRange)
                if let foundRange = foundRange, foundRange.location != NSNotFound {
                    let color = UDColor.colorfulSunflower
                    let textColor = UIColor.ud.N900.alwaysLight
                    text.addAttributes([.backgroundColor: color, .foregroundColor: textColor], range: foundRange)
                    searchRange.location = foundRange.location + foundRange.length
                    currnetIdx += 1
                    isHighlighted = true
                } else {
                    break
                }
            }
        }
        return (text, isHighlighted)
    }

    static func coverTitleAttributedString(title: String,
                                      translatedInfo: MailReadTitleViewConfig.TranslatedTitleInfo?,
                                      customColor: UIColor? = nil,
                                      keyword: String? = nil,
                                      subjects: [String] = []) -> (NSAttributedString, NSAttributedString?, Bool) {
        let titleColor = customColor ?? getTitleColor(title)
        var titleAttributedString: NSMutableAttributedString
        var subTitleAttributeString: NSMutableAttributedString?
        var isTitleHighlighted = false
        if let translatedInfo = translatedInfo {
            if translatedInfo.onlyTranslation {
                titleAttributedString = NSMutableAttributedString(string: translatedInfo.translatedTitle, attributes: titleAttributes(titleColor))
            } else {
                titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes(titleColor))
                subTitleAttributeString = NSMutableAttributedString(string: translatedInfo.translatedTitle,
                                                             attributes: titleAttributes(titleColor))
            }
        } else {
            titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes(titleColor))
        }

        if let wholeKeyword = keyword, !wholeKeyword.isEmpty {
            (titleAttributedString, isTitleHighlighted) = addKeywordHighlight(text: titleAttributedString, keyword: wholeKeyword)
            if let sub = subTitleAttributeString {
                (subTitleAttributeString, isTitleHighlighted) = addKeywordHighlight(text: sub, keyword: wholeKeyword)
            }
        }
        for filterSubject in subjects {
            (titleAttributedString, isTitleHighlighted) = addKeywordHighlight(text: titleAttributedString, keyword: filterSubject)
        }

        return (titleAttributedString, subTitleAttributeString, isTitleHighlighted)
    }
}

extension MailReadTitleView: UDNoticeDelegate {
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) { }

    func handleTrailingButtonEvent(_ button: UIButton) { }

    func handleLeadingButtonEvent(_ button: UIButton) {
        delegate?.notSpamTapped()
    }
}

private extension UDNotice {
    static func calNoticeHeight(text: String, actionText: String, containerWidth: CGFloat) -> CGFloat {
        let verticalPadding: CGFloat = 12
        let horizontalPadding: CGFloat = 72
        var textViewHeight: CGFloat = 20
        let textWidth = text.getTextWidth(font: UDFont.body2(.fixed), height: textViewHeight)
        let actionTextWidth = actionText.getTextWidth(font: UDFont.body2(.fixed), height: textViewHeight)
        let needWrap = horizontalPadding + textWidth + actionTextWidth > containerWidth
        let font = UDFont.body2(.fixed)
        let lineHeightMultipler = 1.055
        let baselineOffset = 2.2
        let textHeight = text.getTextHeight(font: font, width: containerWidth - 66)
        let numberOfLines = (textHeight / font.lineHeight).rounded()
        textViewHeight = max(ceil(textHeight * lineHeightMultipler + baselineOffset * numberOfLines), textViewHeight)
        return verticalPadding * 2 + textViewHeight + (needWrap ? 24 : 0)
    }
}
