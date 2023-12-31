import Foundation
import SKInfra
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import LarkUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignSwitch
import UIKit
import UniverseDesignNotice
import UniverseDesignButton
import ByteWebImage
// 升级面板模式
enum AdPermUpdateVCMode {
    case updated, canUpdata
}
// 升级面板title部件
class AdPermUpdateTitle: UIView {
    let vcMode: AdPermUpdateVCMode
    lazy var title: UILabel = {
        var view = UILabel()
        if vcMode == .canUpdata {
            view.text = BundleI18n.SKResource.Bitable_AdvancedPermission_YouCanUpgradeAdvancedPermission_Title
        } else {
            view.text = BundleI18n.SKResource.Bitable_AdvancedPermission_AdvancedPermissionUpgraed_Title
        }
        view.font = UDFont.title3
        view.textColor = UDColor.textTitle
        view.textAlignment = .center
        return view
    }()
    lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    init(vcMode: AdPermUpdateVCMode) {
        self.vcMode = vcMode
        super.init(frame: .zero)
        addSubview(title)
        addSubview(line)
        title.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        line.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// 升级面板tableview，由于设计要求需要动态设置高度，需要继承并且传递layoutSubviews的信号
class AdPermTableView: UITableView {
    weak var dele: AdPermTableViewDelegate?
    override func layoutSubviews() {
        super.layoutSubviews()
        dele?.get(size: contentSize)
    }
}
protocol AdPermTableViewDelegate: AnyObject {
    func get(size: CGSize)
}
// 升级面板Tableview header部分
class AdPermTableHeader: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        var view = UILabel()
        view.textColor = UDColor.textTitle
        view.font = UDFont.headline
        return view
    }()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundColor = UDColor.bgFloatOverlay
        contentView.backgroundColor = UDColor.bgFloatOverlay
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// 升级面板TableView Cell部分
class AdPermTableCell: UITableViewCell {
    lazy var imgView = UIImageView()
    lazy var titleLabel: UILabel = {
        var view = UILabel()
        view.textColor = UDColor.textTitle
        view.font = UDFont.body1
        return view
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(imgView)
        contentView.addSubview(titleLabel)
        selectionStyle = .none
        imgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-10)
            make.width.height.equalTo(16)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(imgView.snp.right).offset(4)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// 按照不同模式封装的Button部分
class AdPermButton: UIView {
    let vcMode: AdPermUpdateVCMode
    weak var dele: AdPermButtonDelegate?
    lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    lazy var knownButton: UDButton = {
        var cfg = UDButtonUIConifg.textGray
        var view = UDButton(cfg)
        view.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonGotIt, for: .normal)
        return view
    }()
    @objc func clickKnwonButton() {
        dele?.clickKnwonButton()
    }
    var waitButton: UIButton = {
        var cfg = UDButtonUIConifg.textBlue
        var view = UDButton(cfg)
        view.setTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_Later_Button, for: .normal)
        return view
    }()
    @objc func clickWaitButton() {
        dele?.clickWaitButton()
    }
    var updateButton: UIButton = {
        var cfg = UDButtonUIConifg.primaryBlue
        var view = UDButton(cfg)
        view.setTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_UpgradeNow_Button, for: .normal)
        return view
    }()
    @objc func clickUpdateButton() {
        dele?.clickUpdateButton()
    }
    init(vcMode: AdPermUpdateVCMode, dele: AdPermButtonDelegate) {
        self.vcMode = vcMode
        self.dele = dele
        super.init(frame: .zero)
        addSubview(line)
        line.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        if vcMode == .canUpdata {
            addSubview(waitButton)
            addSubview(updateButton)
            waitButton.snp.makeConstraints { make in
                make.top.equalTo(line.snp.bottom)
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(16)
                make.height.equalTo(48)
            }
            updateButton.snp.makeConstraints { make in
                make.top.equalTo(line.snp.bottom)
                make.left.equalTo(waitButton.snp.right).offset(16)
                make.right.equalToSuperview().offset(-16)
                make.width.equalTo(waitButton.snp.width)
                make.height.equalTo(48)
            }
        } else {
            addSubview(knownButton)
            knownButton.snp.makeConstraints { make in
                make.top.equalTo(line.snp.bottom)
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(48)
            }
        }
        knownButton.addTarget(self, action: #selector(clickKnwonButton), for: .touchUpInside)
        waitButton.addTarget(self, action: #selector(clickWaitButton), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(clickUpdateButton), for: .touchUpInside)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
protocol AdPermButtonDelegate: AnyObject {
    func clickKnwonButton()
    func clickWaitButton()
    func clickUpdateButton()
}
protocol AdPermUpdateVCDelegate: AnyObject {
    func clickUpdateButton(vc: UIViewController)
    func clickLaterButton(vc: UIViewController)
    func clickKnownButton(vc: UIViewController)
}
// 升级面板，设计稿参考 https://www.figma.com/file/9PkalHA7nfES0Y7eQbMNZ8/高级权限下千人一面?t=zJ8Pt1nSlJ9W66nw-0
class AdPermUpdateVC: UIViewController, AdPermTableViewDelegate, AdPermButtonDelegate {
    let vcMode: AdPermUpdateVCMode
    let info: EffectFormulaInfo
    weak var dele: AdPermUpdateVCDelegate?
    var showTableView: Bool {
        !info.formulaInfo.isEmpty
    }
    lazy var containerView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 12.0
        view.layer.maskedCorners = .top
        view.layer.masksToBounds = true
        return view
    }()
    lazy var updateTitleView: AdPermUpdateTitle = {
        let view = AdPermUpdateTitle(vcMode: vcMode)
        return view
    }()
    var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        let img = UDIcon.getIconByKey(.imageOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN3)
        let imgView = UIImageView(image: img)
        view.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        return view
    }()
    var imageView: ByteImageView = {
        let view = ByteImageView()
        return view
    }()
    lazy var desLabel: UILabel = {
        var view = UILabel()
        view.numberOfLines = 0
        view.font = UDFont.body0
        view.textColor = UDColor.textCaption
        if vcMode == .canUpdata {
            view.text = BundleI18n.SKResource.Bitable_AdvancedPermission_UpgradeToLetAllMemberCanViewReferencedData_Description
        } else {
            view.text = BundleI18n.SKResource.Bitable_AdvancedPermission_AllMemberCanViewReferencedData_Description
        }
        return view
    }()
    lazy var tableView: UITableView = {
        var view = AdPermTableView()
        view.dele = self
        view.delegate = self
        view.dataSource = self
        view.register(AdPermTableHeader.self, forHeaderFooterViewReuseIdentifier: "AdPermTableHeader")
        view.register(AdPermTableCell.self, forCellReuseIdentifier: "AdPermTableCell")
        view.layer.borderWidth = 0.5
        view.layer.ud.setBorderColor(UDColor.lineBorderCard)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    lazy var buttons: AdPermButton = {
        let view = AdPermButton(vcMode: vcMode, dele: self)
        return view
    }()
    func clickKnwonButton() {
        dele?.clickKnownButton(vc: self)
    }
    func clickWaitButton() {
        dele?.clickLaterButton(vc: self)
    }
    func clickUpdateButton() {
        dele?.clickUpdateButton(vc: self)
    }
    func get(size: CGSize) {
        tableView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.lessThanOrEqualTo(size.height)
        }
    }
    init(
        vcMode: AdPermUpdateVCMode,
        info: EffectFormulaInfo,
        dele: AdPermUpdateVCDelegate?
    ) {
        self.vcMode = vcMode
        self.info = info
        self.dele = dele
        super.init(nibName: nil, bundle: nil)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        let urlString = AdPermImageURLHelper().url?.absoluteString ?? ""
        imageView.bt.setLarkImage(with: .default(key: urlString)) { result in
            switch result {
            case .success:
                self.emptyView.isHidden = true
            case .failure(let error):
                DocsLogger.error("loading gif error, url: \(urlString)", error: error)
            }
        }
    }
    func setupViews() {
        if !SKDisplay.pad {
            view.backgroundColor = UDColor.bgMask
        }
        view.addSubview(containerView)
        containerView.addArrangedSubview(updateTitleView)
        containerView.addArrangedSubview(imageView)
        containerView.addArrangedSubview(desLabel)
        if showTableView {
            containerView.addArrangedSubview(tableView)
        }
        containerView.addArrangedSubview(buttons)
        containerView.spacing = 16
        containerView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            if SKDisplay.pad {
                make.height.lessThanOrEqualToSuperview()
            } else {
                make.height.lessThanOrEqualToSuperview().multipliedBy(0.9)
            }
        }
        updateTitleView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(imageView.snp.width).multipliedBy(221.0/343.0)
        }
        imageView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        desLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        if showTableView {
            tableView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(180)
            }
        }
        buttons.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            if !SKDisplay.pad {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }
}
extension AdPermUpdateVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        36
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        36
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "AdPermTableHeader") as? AdPermTableHeader
        view?.titleLabel.text = info.formulaInfo[section].name
        return view
    }
}
extension AdPermUpdateVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        info.formulaInfo[section].formulaFieldInfo.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdPermTableCell", for: indexPath)
        if let tableCell = cell as? AdPermTableCell {
            let udIconType = info.formulaInfo[indexPath.section].formulaFieldInfo[indexPath.row].type.iconImage
            tableCell.imgView.image = UDIcon.getIconByKey(udIconType)
            tableCell.titleLabel.text = info.formulaInfo[indexPath.section].formulaFieldInfo[indexPath.row].name
        }
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        info.formulaInfo.count
    }
}
// 前端数据结构部分
struct ProUpdateEffectData: Codable {
    var effectFormulaInfo: EffectFormulaInfo
}
struct EffectFormulaInfo: Codable {
    var formulaCount: Int
    var formulaInfo: [EffectFormulaDetailInfo]
}
struct EffectFormulaDetailInfo: Codable {
    var name: String
    var formulaFieldInfo: [EffectFormulaDetailFieldInfo]
}
struct EffectFormulaDetailFieldInfo: Codable {
    var type: AdPermFieldUIType
    var name: String
}
enum ProUpdateEffectDataError: String, Error {
    case hasNoResult
    case inValidJSONObject
    case dataWithJSONObjectOrDecode
}
// Pod依赖关系导致无法依赖到skbitable，建议后期把bitable相关逻辑从common全部上升到bitable，放common太臃肿
enum AdPermFieldUIType: String, Codable {
    case notSupport = "NotSupport"
    case text = "Text"
    case number = "Number"
    case singleSelect = "SingleSelect"
    case multiSelect = "MultiSelect"
    case dateTime = "DateTime"
    case checkbox = "Checkbox"
    case user = "User"
    case phone = "Phone"
    case url = "Url"
    case attachment = "Attachment"
    case singleLink = "SingleLink"
    case lookup = "Lookup"
    case formula = "Formula"
    case duplexLink = "DuplexLink"
    case location = "Location"
    case createTime = "CreatedTime"
    case lastModifyTime = "ModifiedTime"
    case createUser = "CreatedUser"
    case lastModifyUser = "ModifiedUser"
    case autoNumber = "AutoNumber"
    case barcode = "Barcode"
    case currency = "Currency"
    case progress = "Progress"
    var iconImage: UDIconType {
        switch self {
        case .notSupport: return .maybeOutlined
        case .text: return .styleOutlined
        case .number: return .numberOutlined
        case .singleSelect: return .downRoundOutlined
        case .multiSelect: return .multipleOutlined
        case .dateTime, .lastModifyTime, .createTime: return .calendarLineOutlined
        case .checkbox: return .todoOutlined
        case .user, .createUser, .lastModifyUser: return .memberOutlined
        case .phone: return .callOutlined
        case .url: return .linkCopyOutlined
        case .attachment: return .attachmentOutlined
        case .singleLink: return .sheetOnedatareferenceOutlined
        case .lookup: return .lookupOutlined
        case .formula: return .formulaOutlined
        case .duplexLink: return .sheetDatareferenceOutlined
        case .autoNumber: return .numberedListNewOutlined
        case .location: return .localOutlined
        case .barcode: return .barcodeOutlined
        case .currency:
            return DocsSDK.currentLanguage == .zh_CN ? .currencyYuanOutlined : .currencyDollarOutlined
        case .progress: return .bitableProgressOutlined
        }
    }
}
// gif url处理
struct AdPermImageURLHelper {
    var path: String {
        switch DocsSDK.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            return "/ccm/static_resource/scm_upload/ccm_bitable_permission_update_gif_CN.gif"
        case .en_US:
            return "/ccm/static_resource/scm_upload/ccm_bitable_permission_update_gif_EN.gif"
        case .ja_JP:
            return "/ccm/static_resource/scm_upload/ccm_bitable_permission_update_gif_JP.gif"
        default:
            return "/ccm/static_resource/scm_upload/ccm_bitable_permission_update_gif_EN.gif"
        }
    }
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        if let domains = CCMKeyValue.globalUserDefault.stringArray(forKey: UserDefaultKeys.adPermImageOverloadStaticDomainKey) {
            components.host = domains.first ?? ""
        } else {
            DocsLogger.error("get domain by ad_perm_image_overload_static_domain error")
        }
        components.path = path
        return components.url
    }
}
