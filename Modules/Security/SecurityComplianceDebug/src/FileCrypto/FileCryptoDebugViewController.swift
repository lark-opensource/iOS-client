//
//  FileCryptoDebugViewController.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/9/8.
//

import Foundation
import LarkContainer
import LarkRustClient
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import RustPB
import UIKit
import UniverseDesignColor
import LarkAccountInterface
import CryptoSwift

final class FileCryptoDebugViewController: UIViewController, FileCryptoDebugHandle {
   
    func handle() {
        guard let from else { return }
        userResolver.navigator.push(self, from: from)
    }
    
    
    enum CryptType {
        case clear
        case stream
        case path
    }

    let tableView = UITableView(frame: .zero, style: .plain)

    var items: [ItemType]?

    let label: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.numberOfLines = 0
        return label
    }()

    @ScopedProvider private var rustService: RustService?
    @ScopedProvider private var settings: Settings?

    var type: CryptType = .clear
    var blockCount: Int?
    var blockSize: Int?

    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("testCipherPerf")
    
    let userResolver: UserResolver
    weak var from: UIViewController?
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.from = viewController
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
        loadMenu()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setupCipherMode(isBlockMode: !(settings?.enableStreamCipherMode ?? false))
    }

    private func buildView() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.register(FileCryptoDebugInputBoxCell.self, forCellReuseIdentifier: FileCryptoDebugInputBoxCell.cellTableIdentifier)
        tableView.register(FileCryptoDebugCheckBoxCell.self, forCellReuseIdentifier: FileCryptoDebugCheckBoxCell.cellTableIdentifier)
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.lessThanOrEqualTo(200)
        }

        let testButton = UIButton()
        testButton.setTitle("开始测试", for: .normal)
        testButton.layer.borderColor = UIColor.ud.staticBlack.cgColor
        testButton.setTitleColor(.black, for: .normal)
        view.addSubview(testButton)
        testButton.sizeToFit()
        testButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-50)
        }
        testButton.addTarget(self, action: #selector(testPref), for: .touchUpInside)

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(testButton.snp.top).offset(-40)
        }
    }

    private func loadMenu() {
        items = [
            .checkBox("加密模式", "流加密", "块加密", "不加密") { [weak self] title in
                if title == "流加密" {
                    self?.type = .stream
                } else if title == "块加密" {
                    self?.type = .path
                } else {
                    self?.type = .clear
                }
            },
            .inputBox("块数量", .number) { [weak self] output in
                switch output {
                case let .number(num):
                    self?.blockCount = num
                default:
                    self?.blockCount = nil
                }
            },
            .inputBox("块大小（kb）", .number) { [weak self] output in
                switch output {
                case let .number(num):
                    self?.blockSize = num * 1024
                default:
                    self?.blockSize = nil
                }
            }
        ]
    }

    @objc
    func testPref() {
        guard let blockCount = blockCount else {
            Alerts.showAlert(from: self, title: "请填写块数量", content: nil, actions: [.init(title: "确定", style: .cancel, handler: nil)])
            return
        }
        guard let blockSize = blockSize else {
            Alerts.showAlert(from: self, title: "请填写块大小", content: nil, actions: [.init(title: "确定", style: .cancel, handler: nil)])
            return
        }
        label.text = ""
        switch type {
        case .stream:
            testStream(blockCount: blockCount, blockSize: blockSize)
        case .clear:
            testClear(blockCount: blockCount, blockSize: blockSize)
        case .path:
            testPath(fileSize: blockSize * blockCount)
        }
    }

    func testPath(fileSize: Int) {
        setupCipherMode(isBlockMode: true)
        // 测试写入
        let data = Data(repeating: 25, count: fileSize)
        let cipher = CryptoPath(userResolver: userResolver)
        let writeBegin = CFAbsoluteTimeGetCurrent()
        do {
            try data.write(to: filePath)
            try cipher.encrypt(filePath.path)
        } catch {
            label.text = "文件写入失败：\(error)"
            return
        }
        let writeEnd = CFAbsoluteTimeGetCurrent()

        let cacheReadBegin = CFAbsoluteTimeGetCurrent()
        do {
            // 有缓存的情况
            let decryptPath = try cipher.decrypt(filePath.path)
            _ = try Data(contentsOf: URL(fileURLWithPath: decryptPath))
        } catch {
            label.text = "有缓存文件读取失败：\(error)"
            return
        }
        let cacheReadEnd = CFAbsoluteTimeGetCurrent()
        // 删除缓存
        do {
            let decryptPath = try cipher.decrypt(filePath.path)
            try FileManager.default.removeItem(atPath: decryptPath)
        } catch {
            label.text = "缓存文件删除失败：\(error)"
            return
        }
        // 没有缓存
        let noCacheReadBegin = CFAbsoluteTimeGetCurrent()
        do {
            // 有缓存的情况
            let decryptPath = try cipher.decrypt(filePath.path)
            _ = try Data(contentsOf: URL(fileURLWithPath: decryptPath))
        } catch {
            label.text = "无缓存文件读取失败：\(error)"
            return
        }
        let noCacheReadEnd = CFAbsoluteTimeGetCurrent()

        label.text =
            """
            测试完成，测试结果如下：
            文件大小：\(fileSize / 1024)kb
            文件写入耗时：\((writeEnd - writeBegin) * 1000)ms
            有缓存文件读取耗时: \((cacheReadEnd - cacheReadBegin) * 1000)ms
            无缓存文件读取耗时: \((noCacheReadEnd - noCacheReadBegin) * 1000)ms
            """
        print(">>>>>>>>>",#function, label.text ?? "")
    }
    
    func testClear(blockCount: Int, blockSize: Int) {
        setupCipherMode(isBlockMode: false)
        // 测试写入
        let data = Data(repeating: 25, count: blockSize)
        if FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.removeItem(atPath: filePath.path)
        }
        FileManager.default.createFile(atPath: filePath.path, contents: Data())
        let writeBegin = CFAbsoluteTimeGetCurrent()
        do {
            let writeHandle = try SCFileHandle(path: filePath.path, option: .write)
            
            for _ in 0 ..< blockCount {
                try writeHandle.write(contentsOf: data)
            }
            try writeHandle.close()
        } catch {
            label.text = "文件写入失败：\(error)"
            return
        }
        let writeEnd = CFAbsoluteTimeGetCurrent()

        let readBegin = CFAbsoluteTimeGetCurrent()
        do {
            let readHandle = try SCFileHandle(path: filePath.path, option: .read)
            for _ in 0 ..< blockCount {
                _ = try readHandle.read(upToCount: Int(blockSize))
            }
            try readHandle.close()
        } catch {
            label.text = "文件读取失败：\(error)"
            return
        }
        let readEnd = CFAbsoluteTimeGetCurrent()

        label.text =
            """
            测试完成，测试结果如下：
            文件大小：\(blockSize * blockCount / 1024)kb
            文件写入耗时：\((writeEnd - writeBegin) * 1000)ms
            文件读取耗时: \((readEnd - readBegin) * 1000)ms
            """
        
        print(">>>>>>>>>",#function, label.text ?? "")
    }

    func testStream(blockCount: Int, blockSize: Int) {
        setupCipherMode(isBlockMode: false)
        // 测试写入
        let data = Data(repeating: 25, count: blockSize)
        print("数据1: \(data.bytes.prefix(10))")
        @Provider var cryptoService: FileCryptoService
        @Provider var passportService: PassportService
        let cipher = CryptoStream(enableStreamCipherMode: true,
                                  deviceKey: FileCryptoDeviceKey.deviceKey(),
                                  uid: passportService.foregroundUser?.userID ?? "",
                                  did: passportService.deviceID,
                                  userResolver: userResolver)
        let writeBegin = CFAbsoluteTimeGetCurrent()
        do {
            let output = try cipher.encrypt(to: filePath.path)
            try output.open(shouldAppend: false)
            for _ in 0 ..< blockCount {
                try output.write(data: data)
            }
            try output.close()
        } catch {
            label.text = "文件写入失败：\(error)"
            return
        }
        let writeEnd = CFAbsoluteTimeGetCurrent()

        let readBegin = CFAbsoluteTimeGetCurrent()
        do {
            let input = try cipher.decrypt(from: filePath.path)
            try input.open(shouldAppend: false)
            for _ in 0 ..< blockCount {
                let data = try input.read(maxLength: UInt32(blockSize))
                print("数据： \(data.bytes.prefix(10))")
            }
            try input.close()
        } catch {
            label.text = "文件读取失败：\(error)"
            return
        }
        let readEnd = CFAbsoluteTimeGetCurrent()

        label.text =
            """
            测试完成，测试结果如下：
            文件大小：\(blockSize * blockCount / 1024)kb
            文件写入耗时：\((writeEnd - writeBegin) * 1000)ms
            文件读取耗时: \((readEnd - readBegin) * 1000)ms
            """
        
        print(">>>>>>>>>",#function, label.text ?? "")
    }

    func setupCipherMode(isBlockMode: Bool) {
        guard let rustService else { return }
        print("set crypto downgrade mode begin: \(isBlockMode)")
        var updateFileSettingRequest = Security_V1_UpdateFileSettingRequest()
        updateFileSettingRequest.downgrade = isBlockMode
        _ = rustService.async(message: updateFileSettingRequest)
            .subscribe(onNext: { (_: Security_V1_UpdateFileSettingResponse) in
                print("set crypto downgrade mode end: \(isBlockMode)")
            })
    }
}

extension FileCryptoDebugViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = items?[indexPath.row] else {
            return UITableViewCell()
        }
        switch item {
        case let .inputBox(title, input, outputBlock):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FileCryptoDebugInputBoxCell.cellTableIdentifier, for: indexPath) as? FileCryptoDebugInputBoxCell else {
                return UITableViewCell()
            }
            cell.update(title: title, inputType: input, textChangeBlock: outputBlock)
            return cell
        case let .checkBox(title, choise1, choise2, choise3, block):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FileCryptoDebugCheckBoxCell.cellTableIdentifier, for: indexPath) as? FileCryptoDebugCheckBoxCell else {
                return UITableViewCell()
            }
            cell.update(title: title, choise1: choise1, choise2: choise2, choise3: choise3, clickBlock: block)
            return cell
        }
    }
}

enum ItemType {
    typealias Title = String
    typealias ChoiseTitle = String
    enum InputType {
        case number
        case string
    }

    enum OutputType {
        case number(Int)
        case string(String)
    }

    case checkBox(Title, ChoiseTitle, ChoiseTitle, ChoiseTitle, (ChoiseTitle) -> Void)
    case inputBox(Title, InputType, (OutputType) -> Void)
}

final class FileCryptoDebugCheckBoxCell: UITableViewCell {
    static let cellTableIdentifier = "FileCryptoDebugCheckBoxCell"

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    var clickBlock: ((String) -> Void)?

    let checkBox1 = UIButton()
    let checkBox2 = UIButton()
    let checkBox3 = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.height.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }

        contentView.addSubview(checkBox1)
        checkBox1.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.75)
            make.height.centerY.equalToSuperview()
        }

        contentView.addSubview(checkBox2)
        checkBox2.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.25)
            make.height.centerY.equalToSuperview()
        }
        
        contentView.addSubview(checkBox3)
        checkBox3.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.75)
            make.height.centerY.equalToSuperview()
        }
    }

    func update(title: String, choise1: String, choise2: String, choise3: String, clickBlock: @escaping (String) -> Void) {
        self.clickBlock = clickBlock
        titleLabel.text = title

        checkBox1.setTitle(choise1, for: .normal)
        checkBox1.setTitleColor(.green, for: .selected)
        checkBox1.setTitleColor(.gray, for: .normal)
        checkBox1.addTarget(self, action: #selector(choiseBtnClicked(btn:)), for: .touchUpInside)

        checkBox2.setTitle(choise2, for: .normal)
        checkBox2.setTitleColor(.green, for: .selected)
        checkBox2.setTitleColor(.gray, for: .normal)
        checkBox2.addTarget(self, action: #selector(choiseBtnClicked(btn:)), for: .touchUpInside)
        
        checkBox3.setTitle(choise3, for: .normal)
        checkBox3.setTitleColor(.green, for: .selected)
        checkBox3.setTitleColor(.gray, for: .normal)
        checkBox3.addTarget(self, action: #selector(choiseBtnClicked(btn:)), for: .touchUpInside)
    }

    @objc
    func choiseBtnClicked(btn: UIButton) {
        checkBox1.isSelected = false
        checkBox2.isSelected = false
        checkBox3.isSelected = false

        btn.isSelected = true
        clickBlock?(btn.title(for: .normal) ?? "")
    }
}

final class FileCryptoDebugInputBoxCell: UITableViewCell, UITextFieldDelegate {
    static let cellTableIdentifier = "FileCryptoDebugInputBoxCell"

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    var textChangeBlock: ((ItemType.OutputType) -> Void)?

    let inputBox = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.height.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }

        contentView.addSubview(inputBox)
        inputBox.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalToSuperview().offset(-20)
            make.top.bottom.equalToSuperview()
        }
    }

    func update(title: String, inputType: ItemType.InputType, textChangeBlock: @escaping (ItemType.OutputType) -> Void) {
        titleLabel.text = title
        switch inputType {
        case .number:
            inputBox.keyboardType = .numberPad
            inputBox.placeholder = "请输入整数"
        case .string:
            inputBox.keyboardType = .default
        }
        inputBox.delegate = self
        inputBox.returnKeyType = .done
        let toolbar = UIToolbar()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done,
                                         target: self, action: #selector(doneButtonTapped))

        toolbar.setItems([flexSpace, doneButton], animated: true)
        toolbar.sizeToFit()
        #if !os(visionOS)
        inputBox.inputAccessoryView = toolbar
        #endif
        self.textChangeBlock = textChangeBlock
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if inputBox.keyboardType == .numberPad {
            textChangeBlock?(.number(Int(textField.text ?? "0") ?? 0))
        } else {
            textChangeBlock?(.string(textField.text ?? ""))
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc
    func doneButtonTapped() {
        inputBox.resignFirstResponder()
    }
}
