//
//  AudioOutputActionSheet.swift
//  ByteView
//
//  Created by kiri on 2022/11/10.
//

import Foundation
import LarkMedia
import ByteViewTracker
import UniverseDesignIcon
import ByteViewUI

protocol AudioOutputActionSheetDelegate: AnyObject {
    func audioOutputActionSheet(_ actionSheet: UIViewController, didSelect item: AudioOutputPickerItem)
    func audioOutputActionSheetWillAppear(_ actionSheet: UIViewController)
    func audioOutputActionSheetWillDisappear(_ actionSheet: UIViewController)
    func audioOutputActionSheetDidAppear(_ actionSheet: UIViewController)
    func audioOutputActionSheetDidDisappear(_ actionSheet: UIViewController)
}

extension AudioOutputActionSheetDelegate {
    func audioOutputActionSheetWillAppear(_ actionSheet: UIViewController) {}
    func audioOutputActionSheetWillDisappear(_ actionSheet: UIViewController) {}
    func audioOutputActionSheetDidAppear(_ actionSheet: UIViewController) {}
    func audioOutputActionSheetDidDisappear(_ actionSheet: UIViewController) {}
}

final class AudioOutputActionSheet: PuppetPresentedViewController, UITableViewDataSource, UITableViewDelegate {

    struct Config {
        var offset: CGFloat = 0
        var cellWidth: CGFloat = 351
        var cellMaxWidth: CGFloat?
        var directions: UIPopoverArrowDirection? = [.down]
        var margins: UIEdgeInsets?

        static let `default` = Config()
    }

    private let tableView = UITableView()
    private let cancelButton = UIButton(type: .custom)
    private let cancelButtonBgView = UIView()
    private let scene: AudioOutputPickerScene
    private let output: AudioOutput
    private let isMuted: Bool
    private let isHeadsetConnected: Bool
    private let items: [AudioOutputPickerItem]
    private var isPopover = false
    weak var delegate: AudioOutputActionSheetDelegate?
    /// - parameter isHeadsetConnected: true: 切换音频设备-静音/取消静音, false: 扬声器-听筒-静音
    init(scene: AudioOutputPickerScene, isHeadsetConnected: Bool, output: AudioOutput, isMuted: Bool) {
        self.scene = scene
        self.output = output
        self.isMuted = isMuted
        self.isHeadsetConnected = isHeadsetConnected
        if isHeadsetConnected {
            self.items = [.picker, isMuted ? .unmute : .mute]
        } else if Display.phone {
            self.items = [.speaker, .receiver, .mute]
        } else {
            self.items = [.speaker, .mute]
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.addSubview(tableView)

        self.tableView.backgroundColor = .clear
        if isHeadsetConnected {
            self.tableView.register(AudioOutputHeadsetCell.self, forCellReuseIdentifier: "AudioOutputHeadsetCell")
            self.tableView.register(AudioOutputMuteCell.self, forCellReuseIdentifier: "AudioOutputMuteCell")
        } else {
            self.tableView.register(AudioOutputSelectCell.self, forCellReuseIdentifier: "AudioOutputSelectCell")
        }
        // nolint-next-line: magic number'
        self.tableView.layer.cornerRadius = 12
        self.tableView.rowHeight = 48
        // enable-lint: magic number
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isScrollEnabled = false

        let cancelTitle = NSAttributedString(string: I18n.View_G_CancelButton, config: .h4, alignment: .center, textColor: UIColor.ud.textTitle)
        self.cancelButton.setAttributedTitle(cancelTitle, for: .normal)
        // nolint-next-line: magic number
        self.cancelButton.layer.cornerRadius = 12
        self.cancelButton.layer.masksToBounds = true
        self.cancelButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.bgBody), for: .normal)
        self.cancelButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.fillHover), for: .highlighted)
        self.cancelButton.addTarget(self, action: #selector(didCancel(_:)), for: .touchUpInside)
        // nolint-next-line: magic number
        self.cancelButtonBgView.layer.cornerRadius = 12
        self.cancelButtonBgView.backgroundColor = UIColor.ud.bgBody
    }

    func show(from: UIViewController, anchorView: UIView?, config: Config) {
        var popoverConfig: DynamicModalPopoverConfig?
        let cellWidth: CGFloat
        let width = getActionSheetCellWidth(config: config)
        let defaultCellWidth: CGFloat = 351
        if let cellMaxWidth = config.cellMaxWidth {
            cellWidth = width < cellMaxWidth ? width : cellMaxWidth
        } else {
            cellWidth = width < defaultCellWidth ? width : defaultCellWidth
        }

        if let anchorView = anchorView {
            popoverConfig = DynamicModalPopoverConfig(
                sourceView: anchorView,
                sourceRect: CGRect(x: anchorView.bounds.minX,
                                   y: anchorView.bounds.minY + config.offset,
                                   width: anchorView.bounds.width,
                                   height: anchorView.bounds.height),
                backgroundColor: UIColor.ud.bgFloat,
                popoverSize: CGSize(width: cellWidth, height: 48 * CGFloat(items.count)),
                popoverLayoutMargins: config.margins ?? .zero,
                permittedArrowDirections: config.directions
            )
        }
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        from.presentDynamicModal(self, regularConfig: regularConfig, compactConfig: compactConfig)
        VCTracker.post(name: .vc_meeting_loudspeaker_view, params: [.location: scene.trackText])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.audioOutputActionSheetWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.audioOutputActionSheetWillDisappear(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.audioOutputActionSheetDidAppear(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.audioOutputActionSheetDidDisappear(self)
    }

    func dismiss() {
        let scene = self.scene
        self.dismiss(animated: true, completion: {
            VCTracker.post(name: .vc_meeting_loudspeaker_view, params: [.click: "other", .location: scene.trackText])
        })
    }

    private func updateStyle() {
        if isPopover {
            cancelButtonBgView.removeFromSuperview()
            cancelButton.removeFromSuperview()
            tableView.snp.remakeConstraints { make in
                make.top.left.right.equalTo(view.safeAreaLayoutGuide)
                make.height.equalTo(items.count * 48)
            }
        } else {
            view.addSubview(cancelButtonBgView)
            view.addSubview(cancelButton)
            tableView.snp.remakeConstraints { make in
                make.left.right.equalTo(view.safeAreaLayoutGuide).inset(12)
                make.top.equalTo(view.safeAreaLayoutGuide)
                make.height.equalTo(items.count * 48)
            }
            cancelButtonBgView.snp.remakeConstraints { make in
                make.edges.equalTo(cancelButton)
            }
            cancelButton.snp.remakeConstraints { make in
                make.left.right.equalTo(tableView)
                make.top.equalTo(tableView.snp.bottom).offset(12)
                make.height.equalTo(48)
            }
        }
        tableView.reloadData()
    }

    private func getActionSheetCellWidth(config: Config) -> CGFloat {
        guard isHeadsetConnected else { return config.cellWidth }
        let width: CGFloat
        let redundancy: CGFloat = 0.5
        if isMuted {
            let mutedEdge: CGFloat =  64
            width = I18n.View_MV_SelectAudioDevice_Button.vc.boundingWidth(height: 24, config: .h4) + mutedEdge + redundancy
        } else {
            let unMutedEdge: CGFloat =  100
            width = I18n.View_MV_SwitchAudioDevice_Button.vc.boundingWidth(height: 24, config: .h4) + I18n.View_G_Bluetooth.vc.boundingWidth(height: 24, config: .h4) + unMutedEdge + redundancy
        }
        let cellRealWidth: CGFloat = width < config.cellWidth ? config.cellWidth : width
        return cellRealWidth
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.row]
        let identifier = self.isHeadsetConnected ? item.cellIdentifier : "AudioOutputSelectCell"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? BaseAudioOutputCell {
            cell.updateBackground(isPopover: self.isPopover)
            cell.updateContent(item: item, output: self.output, isMuted: self.isMuted)
            cell.separatorLine.isHidden = indexPath.row == self.items.count - 1
            return cell
        }
        fatalError("AudioOutputHeadsetActionSheet create cell failed for \(indexPath)")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didSelectActionSheetItem(self.items[indexPath.row])
    }

    @objc private func didCancel(_ sender: Any?) {
        self.didSelectActionSheetItem(.cancel)
    }

    private func didSelectActionSheetItem(_ item: AudioOutputPickerItem) {
        Logger.audio.info("[\(scene)] didSelectActionSheetItem \(item), isHeadsetConnected = \(isHeadsetConnected)")
        self.delegate?.audioOutputActionSheet(self, didSelect: item)
        self.dismiss(animated: true)
        if !self.isHeadsetConnected {
            VCTracker.post(name: .vc_meeting_loudspeaker_view, params: [.click: item.trackText, .location: scene.trackText])
        }
        DispatchQueue.global().async {
            let isBluetoothConnected = LarkAudioSession.shared.isBluetoothConnected
            VCTracker.post(name: .vc_meeting_loudspeaker_click, params: [.click: item.trackText, "is_bluetooth_on": isBluetoothConnected])
        }
    }
}

extension AudioOutputActionSheet: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        self.isPopover = Display.pad && isRegular
        self.updateStyle()
    }
}

extension AudioOutputActionSheet: PanChildViewControllerProtocol {

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        let itemHeight: CGFloat = CGFloat(48 * items.count)
        if isPopover {
            return .contentHeight(itemHeight)
        } else {
            // nolint-next-line: magic number
            let offset: CGFloat = VCScene.safeAreaInsets.bottom > 0 ? 2 : 12
            return .contentHeight(itemHeight + 60 + offset)
        }
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            // nolint-next-line: magic number
            return .maxWidth(width: 375)
        }
        return .fullWidth
    }

    var showDragIndicator: Bool {
        false
    }

    var panScrollable: UIScrollView? {
        tableView
    }

    var showBarView: Bool {
        false
    }

    func configurePanWareContentView(_ contentView: UIView) {
        contentView.backgroundColor = .clear
    }
}

private class BaseAudioOutputCell: UITableViewCell {
    let separatorLine = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        self.backgroundView?.addSubview(separatorLine)
        separatorLine.backgroundColor = UIColor.ud.lineDividerDefault
        separatorLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() { }
    func updateContent(item: AudioOutputPickerItem, output: AudioOutput, isMuted: Bool) {}
    func updateBackground(isPopover: Bool) {
        self.backgroundView?.backgroundColor = isPopover ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover
    }
}

private final class AudioOutputHeadsetCell: BaseAudioOutputCell {
    let iconView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let indicatorView = UIImageView()

    override func setupViews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(indicatorView)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        subtitleLabel.setContentHuggingPriority(.required, for: .horizontal)

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
        }
        indicatorView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.height.width.equalTo(16)
            make.centerY.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints { make in
            make.right.equalTo(indicatorView.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        iconView.image = UDIcon.getIconByKey(.speakerSwitchOutlined, iconColor: UIColor.ud.iconN1)
        indicatorView.image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: UIColor.ud.iconN3)
        titleLabel.textColor = UIColor.ud.textTitle
        subtitleLabel.textColor = UIColor.ud.textPlaceholder
    }

    override func updateContent(item: AudioOutputPickerItem, output: AudioOutput, isMuted: Bool) {
        if isMuted {
            titleLabel.attributedText = NSAttributedString(string: I18n.View_MV_SelectAudioDevice_Button, config: .h4, lineBreakMode: .byTruncatingTail)
            subtitleLabel.isHidden = true
            indicatorView.isHidden = true
        } else {
            titleLabel.attributedText = NSAttributedString(string: I18n.View_MV_SwitchAudioDevice_Button, config: .h4, lineBreakMode: .byTruncatingTail)
            subtitleLabel.attributedText = NSAttributedString(string: output.i18nText, config: .h4, lineBreakMode: .byTruncatingTail)
            subtitleLabel.isHidden = false
            indicatorView.isHidden = false
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            if isMuted {
                make.right.equalToSuperview().inset(16)
            } else {
                make.right.equalTo(subtitleLabel.snp.left).offset(-12)
            }
        }
    }
}

private final class AudioOutputMuteCell: BaseAudioOutputCell {
    let iconView = UIImageView()
    let titleLabel = UILabel()

    override func setupViews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
        }
        iconView.image = UDIcon.getIconByKey(.speakerMuteOutlined, iconColor: UIColor.ud.iconN1)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        titleLabel.textColor = UIColor.ud.textTitle
    }

    override func updateContent(item: AudioOutputPickerItem, output: AudioOutput, isMuted: Bool) {
        let text = isMuted ? I18n.View_G_Unmute : I18n.View_MV_MuteButton
        titleLabel.attributedText = NSAttributedString(string: text, config: .h4)
    }
}

private final class AudioOutputSelectCell: BaseAudioOutputCell {
    let iconView = UIImageView()
    let titleLabel = UILabel()
    let indicatorView = UIImageView()

    // disable-lint: duplicated code
    override func setupViews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(indicatorView)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
        }
        indicatorView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
        }
        indicatorView.image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: UIColor.ud.primaryContentDefault)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalTo(indicatorView.snp.left).offset(-12)
        }
        titleLabel.textColor = UIColor.ud.textTitle
    }
    // enable-lint: duplicated code

    override func updateContent(item: AudioOutputPickerItem, output: AudioOutput, isMuted: Bool) {
        switch item {
        case .speaker:
            let isHiddenIndicator: Bool = isMuted || output != .speaker
            iconView.image = UDIcon.getIconByKey(.speakerOutlined, iconColor: isHiddenIndicator ? .ud.iconN1 : .ud.functionInfoContentDefault)
            titleLabel.attributedText = NSAttributedString(string: AudioOutput.speaker.i18nText, config: isHiddenIndicator ? .h4 : .h3, textColor: isHiddenIndicator ? .ud.textTitle : .ud.functionInfoContentDefault)
            indicatorView.isHidden = isHiddenIndicator
        case .receiver:
            let isHiddenIndicator = isMuted || output != .receiver
            iconView.image = UDIcon.getIconByKey(.earOutlined, iconColor: isHiddenIndicator ? .ud.iconN1 : .ud.functionInfoContentDefault)
            titleLabel.attributedText = NSAttributedString(string: AudioOutput.receiver.i18nText, config: isHiddenIndicator ? .h4 : .h3, textColor: isHiddenIndicator ? .ud.textTitle : .ud.functionInfoContentDefault)
            indicatorView.isHidden = isHiddenIndicator
        case .mute:
            let isHiddenIndicator = !isMuted
            iconView.image = UDIcon.getIconByKey(.speakerMuteOutlined, iconColor: isHiddenIndicator ? .ud.iconN1 : .ud.functionInfoContentDefault)
            titleLabel.attributedText = NSAttributedString(string: I18n.View_MV_MuteButton, config: isHiddenIndicator ? .h4 : .h3, textColor: isHiddenIndicator ? .ud.textTitle : .ud.functionInfoContentDefault)
            indicatorView.isHidden = !isMuted
        default:
            assertionFailure("\(item) not supported")
        }
    }
}

private extension AudioOutputPickerItem {
    var cellIdentifier: String {
        switch self {
        case .picker:
            return "AudioOutputHeadsetCell"
        case .mute, .unmute:
            return "AudioOutputMuteCell"
        default:
            return "AudioOutputSelectCell"
        }
    }
}
