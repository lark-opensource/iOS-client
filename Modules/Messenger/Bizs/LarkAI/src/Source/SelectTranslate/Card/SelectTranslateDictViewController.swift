//
//  SelectTranslateDictViewController.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/2.
//

import Foundation
import LarkUIKit
import FigmaKit
import UIKit
import RxSwift
import AVFoundation
import LKCommonsLogging
import UniverseDesignToast
import ServerPB
import LarkContainer
import LarkStorage

private enum UI {
    static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    static let headerHeight: CGFloat = 48
    static let sendButtonHeight: CGFloat = 48
    static let sendButtonMargin: CGFloat = 16
}

final class SelectTranslateDictViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let logger = Logger.log(SelectTranslateDictViewController.self, category: "LarkAI")
    private let viewModel: SelectTranslateDictCardViewModel
    private var targetLanguage: String
    /// 翻译类型，后端传值，取值为：sentence/word
    private var translateType: String
    /// 划选的文本长度，后端传值
    private var translateLength: String
    private let disposeBag = DisposeBag()
    private var tableHeightConstraint = CGFloat.greatestFiniteMagnitude
    private var audioPlayer: AVAudioPlayer?
    private var selectTranslateAPI: SelectTranslateAPI

    private var isPlayBtnEmpty: Bool = false
    private var isPhoneticEmpty: Bool = false
    private lazy var tableView = self.createTableView()

    private lazy var selectTextTitle = ReplicableTextView()
    private lazy var playAudioButton: UIButton = {
        let button = UIButton()
        button.setImage(Resources.translate_card_pronunciation.ud.withTintColor(.ud.iconN2), for: .normal)
        button.addTarget(self, action: #selector(clickPlayBtn), for: .touchUpInside)
        return button
    }()
    private lazy var phoneticSignLabel: UILabel = UILabel()
    private lazy var logolLabel = UILabel()
    private lazy var phoneticStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        return stackView
    }()

    let userResolver: UserResolver
    init(resolver: UserResolver,
         viewModel: SelectTranslateDictCardViewModel,
         targetLanguage: String,
         translateType: String,
         translateLength: String) {
        self.userResolver = resolver
        self.viewModel = viewModel
        self.targetLanguage = targetLanguage
        self.translateType = translateType
        self.translateLength = translateLength
        self.selectTranslateAPI = RustSelectTranslateAPI(resolver: resolver)
        super.init(nibName: nil, bundle: nil)
        viewModel.viewController = self
        self.isPlayBtnEmpty = viewModel.selectTranslateDictModel.pronunciationFileInfo.fileKey.isEmpty
        self.isPhoneticEmpty = viewModel.selectTranslateDictModel.phoneticSign.isEmpty
        observeTableViewHeight()
        setLabelText()
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
    }

    private func setLabelText() {
        selectTextTitle.copyConfig = viewModel.copyConfig
        selectTextTitle.attributedText = NSAttributedString(
            string: viewModel.originTextString,
            attributes: [
                .foregroundColor: UIColor.ud.textTitle,
                .font: UIFont.ud.title2
            ]
        )

        phoneticSignLabel.attributedText = NSAttributedString(
            string: viewModel.selectTranslateDictModel.phoneticSign,
            attributes: [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )

        logolLabel.attributedText = NSAttributedString(
            string: BundleI18n.LarkAI.Lark_ASL_SelectTranslateQuoteDictionary_Source_CambridgeAdvancedLearners,
            attributes: [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UIFont.systemFont(ofSize: 12)
            ]
        )
        logolLabel.numberOfLines = 0
    }
    private func observeTableViewHeight() {
        UIView.animate(withDuration: 0, animations: {
        self.tableView.layoutIfNeeded()
        }) { [weak self] _ in
            self?.tableHeightConstraint = self?.tableView.contentSize.height ?? 0
            self?.updateUI(tableViewHeight: self?.tableHeightConstraint ?? 0)
            self?.view.setNeedsLayout()
        }
    }

    private func updateUI(tableViewHeight: CGFloat) {
        tableView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(phoneticStackView.snp.bottom)
            $0.height.equalTo(tableHeightConstraint)
        }

        self.view.setNeedsLayout()
    }

    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))

        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 40
        tableView.estimatedSectionFooterHeight = 10
        tableView.estimatedSectionHeaderHeight = 10

        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false

        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = .ud.bgFloat
        tableView.isScrollEnabled = false
        tableView.bounces = false
        tableView.lu.register(cellSelf: DictSimpleDefinitionTableViewCell.self)
        tableView.lu.register(cellSelf: DictEnglishDefinitionTableViewCell.self)
        tableView.lu.register(cellSelf: DictExampleSentenceTableViewCell.self)
        return tableView
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.viewModel.items.count {
            return 0
        }
        return self.viewModel.items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= self.viewModel.items.count {
            return UITableViewCell()
        }
        if indexPath.row >= self.viewModel.items[indexPath.section].count {
           return UITableViewCell()
        }
        let item = self.viewModel.items[indexPath.section][indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? BaseSelectTranslateCardCell {
            cell.item = item
            return cell
        }
        let cell = BaseSelectTranslateCardCell(style: .default, reuseIdentifier: item.cellIdentifier)
        cell.item = item
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section >= self.viewModel.footerViews.count {
            return nil
        }
        return self.viewModel.footerViews[section]()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section >= self.viewModel.headerViews.count {
            return nil
        }
        return self.viewModel.headerViews[section]()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.items.count
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    @objc
    func clickPlayBtn() {
        let extraParam = ["target": "none", "function_type": "pronunciation"]
        SelectTranslateTracker.selectTranslateCardClick(resultType: "success",
                                                        clickType: "function",
                                                        wordID: viewModel.params["wordID"],
                                                        messageID: viewModel.params["messageID"],
                                                        chatID: viewModel.params["chatID"],
                                                        fileID: viewModel.params["fileID"],
                                                        fileType: viewModel.params["fileType"],
                                                        srcLanguage: viewModel.params["srcLanguage"],
                                                        tgtLanguage: viewModel.params["tgtLanguage"],
                                                        cardSouce: viewModel.params["cardSource"],
                                                        translateType: self.translateType,
                                                        translateLength: self.translateLength,
                                                        extraParam: extraParam)
        let audioKey = viewModel.selectTranslateDictModel.pronunciationFileInfo.fileKey
        let fsUnit = viewModel.selectTranslateDictModel.pronunciationFileInfo.fsUnit
        selectTranslateAPI.fetchResource(fileKey: audioKey, fsUnit: fsUnit)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                let absPathStr = AbsPath(response.resource.path)
                if absPathStr.exists, !absPathStr.isDirectory {
                    do {
                        let data = try Data.read(from: absPathStr)
                        self?.audioPlayer = try AVAudioPlayer(data: data)
                        Self.logger.info("INFO: play audio success!")
                    } catch {
                        Self.logger.error("ERROR: play audio error")
                    }
                } else {
                    Self.logger.error("ERROR: play audio error")
                }
                guard let audioPlayer = self?.audioPlayer else { return }
                audioPlayer.delegate = self
                if audioPlayer.isPlaying {
                    audioPlayer.pause()
                } else {
                    audioPlayer.prepareToPlay()
                    audioPlayer.play()
                }
                self?.playAudioButton.setImage(Resources.translate_card_pronunciation.ud.withTintColor(.ud.primaryContentDefault), for: .normal)
                self?.playAudioButton.setNeedsLayout()
            }, onError: { [weak self] _ in
                guard let window = self?.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: window)
            }).disposed(by: disposeBag)
    }
}

extension SelectTranslateDictViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Self.logger.info("did finish playing")
        playAudioButton.setImage(Resources.translate_card_pronunciation.ud.withTintColor(.ud.iconN2), for: .normal)
        playAudioButton.setNeedsLayout()
    }
}
private extension SelectTranslateDictViewController {
    /// 布局子试图
    private func setupSubViews() {
        let contentView = UIView()
        contentView.backgroundColor = .ud.bgFloat
        contentView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 8.0)

        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.addSubview(selectTextTitle)
        selectTextTitle.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.leading.top.equalToSuperview().offset(16)
        }

        contentView.addSubview(phoneticStackView)
        phoneticStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(selectTextTitle.snp.bottom).offset(8)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        phoneticStackView.addArrangedSubview(playAudioButton)
        phoneticStackView.addArrangedSubview(phoneticSignLabel)
        playAudioButton.setContentHuggingPriority(.required, for: .horizontal)
        playAudioButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        if isPlayBtnEmpty {
            playAudioButton.isHidden = true
        }
        if isPhoneticEmpty {
            phoneticSignLabel.isHidden = true
        }
        contentView.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(phoneticStackView.snp.bottom)
            $0.height.equalTo(tableHeightConstraint)
        }

        contentView.addSubview(logolLabel)
        logolLabel.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.bottom.equalToSuperview().offset(-16)
        }
    }
}
