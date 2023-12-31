//
//  MeetingDetailJoinedDeviceHeaderComponent.swift
//  ByteViewTab
//
//  Created by Tobb Huang on 2023/9/15.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewCommon

class MeetingDetailJoinedDeviceHeaderComponent: MeetingDetailHeaderComponent {

    private var deviceNames: [String] = []

    lazy var joinedDeviceLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.numberOfLines = 0
        return label
    }()

    override func setupViews() {
        super.setupViews()
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.multideviceOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.top.equalToSuperview().offset(3)
            make.left.equalToSuperview()
        }

        addSubview(joinedDeviceLabel)
        joinedDeviceLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.bottom.right.equalToSuperview()
        }
    }

    override var shouldShow: Bool {
        !deviceNames.isEmpty && viewModel?.isMeetingEnd == false
    }

    override func updateViews() {
        super.updateViews()
        var title: String = ""
        if deviceNames.count > 1 {
            title = I18n.View_G_JoinedonOtherDevices_Desc("\(deviceNames.count)")
        } else if let name = deviceNames.first {
            title = I18n.View_G_AlreadyJoinedOnThisTypeOfDevice_Desc(name)
        }
        // nolint-next-line: magic number
        let config: VCFontConfig = .init(fontSize: 14, lineHeight: 22, fontWeight: .regular)
        joinedDeviceLabel.attributedText = .init(string: title, config: config, textColor: .ud.textTitle)
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.participantAbbrInfos.addObserver(self)
    }
}

extension MeetingDetailJoinedDeviceHeaderComponent: MeetingDetailParticipantAbbrInfoObserver {
    func didReceive(data: [ParticipantAbbrInfo]) {
        viewModel?.getJoinedDeviceNames(callback: { [weak self] deviceNames in
            Util.runInMainThread {
                self?.deviceNames = deviceNames
                self?.updateViews()
            }
        })
    }
}
