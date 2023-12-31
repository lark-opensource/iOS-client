//
//  PolicyEngineExpressionDebugViewController.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/29.
//

import Foundation
import ByteDanceKit
import LarkExpressionEngine
import LarkPolicyEngine
import LarkEMM
import LarkSensitivityControl
import LarkContainer
import LarkRustClient
import RustPB
import SwiftyJSON
import LarkSecurityCompliance

final class PolicyEngineExpressionDebugViewController: UIViewController {
    
    let expressionTextView = SCDebugTextView()
    let contextTextView = SCDebugTextView()
    let outputTextView = SCDebugTextView()
    let repeatTextView = SCDebugTextView()
    var useRustExpr = false
    var disableCache = false
    private let pasteboardConfig = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
    @Provider
    private var serviceImpl: PolicyEngineSnCService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
    }
    
    func buildView() {
        view.backgroundColor = .gray
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(didClickClearBtn)),
            UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(didClickValidate)),
        ]
        
        let emptyButton = UIButton()
        emptyButton.addTarget(self, action: #selector(didClickEmpty), for: .touchUpInside)
        view.addSubview(emptyButton)
        emptyButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let nativeEngineLabel = UILabel()
        nativeEngineLabel.text = "Native"
        nativeEngineLabel.font = .systemFont(ofSize: 18)
        nativeEngineLabel.textColor = .black
        view.addSubview(nativeEngineLabel)
        nativeEngineLabel.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(view.snp.topMargin).offset(8)
        }
        
        let engineSwitch = UISwitch()
        engineSwitch.layer.cornerRadius = 15.5
        engineSwitch.layer.masksToBounds = true
        engineSwitch.backgroundColor = .red
        engineSwitch.addTarget(self, action: #selector(didSwitchEngine(sw:)), for: .valueChanged)
        view.addSubview(engineSwitch)
        engineSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(nativeEngineLabel.snp.centerY)
            make.left.equalTo(nativeEngineLabel.snp.right).offset(8)
            make.width.equalTo(49)
            make.height.equalTo(31)
        }
        
        let rustEngineLabel = UILabel()
        rustEngineLabel.text = "Rust"
        rustEngineLabel.font = .systemFont(ofSize: 18)
        rustEngineLabel.textColor = .black
        view.addSubview(rustEngineLabel)
        rustEngineLabel.snp.makeConstraints { make in
            make.left.equalTo(engineSwitch.snp.right).offset(8)
            make.centerY.equalTo(nativeEngineLabel)
        }
        
        let disableCacheSwitch = UISwitch()
        disableCacheSwitch.addTarget(self, action: #selector(didSwitchDisableCache(sw:)), for: .valueChanged)
        disableCacheSwitch.backgroundColor = .red
        disableCacheSwitch.layer.cornerRadius = 15.5
        disableCacheSwitch.layer.masksToBounds = true
        view.addSubview(disableCacheSwitch)
        disableCacheSwitch.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.centerY.equalTo(engineSwitch)
            make.width.equalTo(49)
            make.height.equalTo(31)
        }
        
        let disableCacheLabel = UILabel()
        disableCacheLabel.text = "禁用缓存"
        disableCacheLabel.font = .systemFont(ofSize: 18)
        disableCacheLabel.textColor = .black
        view.addSubview(disableCacheLabel)
        disableCacheLabel.snp.makeConstraints { make in
            make.right.equalTo(disableCacheSwitch.snp.left).offset(-8)
            make.centerY.equalTo(disableCacheSwitch)
        }
        
        let repeatLabel = UILabel()
        repeatLabel.text = "重复次数"
        repeatLabel.font = .systemFont(ofSize: 18)
        repeatLabel.textColor = .black
        view.addSubview(repeatLabel)
        repeatLabel.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(nativeEngineLabel.snp.bottom).offset(20)
            make.height.equalTo(30)
        }
        
        repeatTextView.isEditable = true
        repeatTextView.layer.cornerRadius = 4
        repeatTextView.layer.shadowColor = UIColor.gray.cgColor
        repeatTextView.layer.shadowRadius = 2
        repeatTextView.layer.shadowOpacity = 1
        repeatTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        repeatTextView.backgroundColor = .white
        repeatTextView.layer.borderWidth = 1
        repeatTextView.layer.borderColor = UIColor.black.cgColor
        repeatTextView.text = "1"
        view.addSubview(repeatTextView)
        repeatTextView.snp.makeConstraints { make in
            make.centerY.equalTo(repeatLabel)
            make.rightMargin.equalToSuperview()
            make.left.equalTo(repeatLabel.snp.right).offset(8)
            make.height.equalTo(repeatLabel)
        }
        
        let policyLabel = UILabel()
        policyLabel.text = "表达式"
        policyLabel.font = .systemFont(ofSize: 18)
        policyLabel.textColor = .black
        view.addSubview(policyLabel)
        policyLabel.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(repeatLabel.snp.bottom).offset(12)
        }
        
        let copyPolicyBtn = UIButton()
        copyPolicyBtn.setTitle("复制", for: .normal)
        copyPolicyBtn.layer.borderColor = UIColor.gray.cgColor
        copyPolicyBtn.layer.borderWidth = 2
        copyPolicyBtn.layer.cornerRadius = 4
        copyPolicyBtn.backgroundColor = .greenSea
        copyPolicyBtn.addTarget(self, action: #selector(didClickCopyPolicy), for: .touchUpInside)
        view.addSubview(copyPolicyBtn)
        copyPolicyBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(policyLabel)
            make.width.equalTo(60)
        }
        
        let pastePolicyBtn = UIButton()
        pastePolicyBtn.setTitle("粘贴", for: .normal)
        pastePolicyBtn.layer.borderColor = UIColor.gray.cgColor
        pastePolicyBtn.layer.borderWidth = 2
        pastePolicyBtn.layer.cornerRadius = 4
        pastePolicyBtn.backgroundColor = .greenSea
        pastePolicyBtn.addTarget(self, action: #selector(didClickPastePolicy), for: .touchUpInside)
        view.addSubview(pastePolicyBtn)
        pastePolicyBtn.snp.makeConstraints { make in
            make.right.equalTo(copyPolicyBtn.snp.left).offset(-5)
            make.top.bottom.equalTo(policyLabel)
            make.width.equalTo(60)
        }
        
        expressionTextView.isEditable = true
        expressionTextView.layer.cornerRadius = 4
        expressionTextView.layer.shadowColor = UIColor.gray.cgColor
        expressionTextView.layer.shadowRadius = 2
        expressionTextView.layer.shadowOpacity = 1
        expressionTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        expressionTextView.backgroundColor = .white
        expressionTextView.layer.borderWidth = 1
        expressionTextView.layer.borderColor = UIColor.black.cgColor
        expressionTextView.text =
                                """
                                [test_mode] && {[test_tenant_id]} hasIn {1, 2, 123} && [test_channel] == "debug"
                                """

        view.addSubview(expressionTextView)
        expressionTextView.snp.makeConstraints { make in
            make.top.equalTo(policyLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(120)
        }
        
        let contextLabel = UILabel()
        contextLabel.text = "参数信息"
        contextLabel.font = .systemFont(ofSize: 18)
        contextLabel.textColor = .black
        view.addSubview(contextLabel)
        contextLabel.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(expressionTextView.snp.bottom).offset(12)
        }
        
        let copyContextBtn = UIButton()
        copyContextBtn.setTitle("复制", for: .normal)
        copyContextBtn.layer.borderColor = UIColor.gray.cgColor
        copyContextBtn.layer.borderWidth = 2
        copyContextBtn.layer.cornerRadius = 4
        copyContextBtn.backgroundColor = .greenSea
        copyContextBtn.addTarget(self, action: #selector(didClickCopyContext), for: .touchUpInside)
        view.addSubview(copyContextBtn)
        copyContextBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(contextLabel)
            make.width.equalTo(60)
        }
        
        let pasteContextBtn = UIButton()
        pasteContextBtn.setTitle("粘贴", for: .normal)
        pasteContextBtn.layer.borderColor = UIColor.gray.cgColor
        pasteContextBtn.layer.borderWidth = 2
        pasteContextBtn.layer.cornerRadius = 4
        pasteContextBtn.backgroundColor = .greenSea
        pasteContextBtn.addTarget(self, action: #selector(didClickPasteContext), for: .touchUpInside)
        view.addSubview(pasteContextBtn)
        pasteContextBtn.snp.makeConstraints { make in
            make.right.equalTo(copyContextBtn.snp.left).offset(-5)
            make.top.bottom.equalTo(contextLabel)
            make.width.equalTo(60)
        }
        
        contextTextView.isEditable = true
        contextTextView.layer.cornerRadius = 4
        contextTextView.layer.shadowColor = UIColor.gray.cgColor
        contextTextView.layer.shadowRadius = 2
        contextTextView.layer.shadowOpacity = 1
        contextTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        contextTextView.backgroundColor = .white
        contextTextView.layer.borderWidth = 1
        contextTextView.layer.borderColor = UIColor.black.cgColor
        contextTextView.text =
                            """
                            {
                                "test_mode": true,
                                "test_tenant_id": 123,
                                "test_channel": "debug",
                            }
                            """
        view.addSubview(contextTextView)
        contextTextView.snp.makeConstraints { make in
            make.top.equalTo(contextLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(120)
        }
        
        let outputLabel = UILabel()
        outputLabel.text = "输出"
        outputLabel.font = .systemFont(ofSize: 18)
        outputLabel.textColor = .black
        view.addSubview(outputLabel)
        outputLabel.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(contextTextView.snp.bottom).offset(12)
        }
        
        let copyOutputtBtn = UIButton()
        copyOutputtBtn.setTitle("复制", for: .normal)
        copyOutputtBtn.layer.borderColor = UIColor.gray.cgColor
        copyOutputtBtn.layer.borderWidth = 2
        copyOutputtBtn.layer.cornerRadius = 4
        copyOutputtBtn.backgroundColor = .greenSea
        copyOutputtBtn.addTarget(self, action: #selector(didClickCopyOutput), for: .touchUpInside)
        view.addSubview(copyOutputtBtn)
        copyOutputtBtn.snp.makeConstraints { make in
            make.rightMargin.equalToSuperview()
            make.top.bottom.equalTo(outputLabel)
            make.width.equalTo(60)
        }
        
        outputTextView.isEditable = false
        outputTextView.layer.cornerRadius = 4
        outputTextView.layer.shadowColor = UIColor.gray.cgColor
        outputTextView.layer.shadowRadius = 2
        outputTextView.layer.shadowOpacity = 1
        outputTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        outputTextView.backgroundColor = .white
        outputTextView.layer.borderWidth = 1
        outputTextView.layer.borderColor = UIColor.black.cgColor
        view.addSubview(outputTextView)
        outputTextView.snp.makeConstraints { make in
            make.top.equalTo(outputLabel.snp.bottom).offset(12)
            make.leftMargin.rightMargin.equalToSuperview()
            make.bottom.equalTo(view.snp.bottomMargin)
        }
    }
    
    @objc
    private func didClickEmpty() {
        expressionTextView.resignFirstResponder()
        contextTextView.resignFirstResponder()
        repeatTextView.resignFirstResponder()
    }
    
    @objc
    private func didClickCopyPolicy() {
        SCPasteboard.general(pasteboardConfig).string = expressionTextView.text
    }
    
    @objc
    private func didClickPastePolicy() {
        expressionTextView.text = SCPasteboard.general(pasteboardConfig).string
    }
    
    @objc
    private func didClickCopyContext() {
        SCPasteboard.general(pasteboardConfig).string = contextTextView.text
    }
    
    @objc
    private func didClickCopyOutput() {
        SCPasteboard.general(pasteboardConfig).string = outputTextView.text
    }
    
    @objc
    private func didClickPasteContext() {
        contextTextView.text = SCPasteboard.general(pasteboardConfig).string
    }
    
    @objc
    private func didClickClearBtn() {
        expressionTextView.text = ""
        contextTextView.text = ""
        outputTextView.text = ""
    }
    
    @objc
    private func didSwitchEngine(sw: UISwitch) {
        useRustExpr = sw.isOn
    }
    
    @objc
    private func didSwitchDisableCache(sw: UISwitch) {
        disableCache = sw.isOn
    }
    
    @objc
    private func didClickValidate() {
        let expression = expressionTextView.text
        guard let expression = expression else {
            return
        }
        var params = JSON()
        if let context = contextTextView.text {
            params = JSON(parseJSON: context)
        }
        
        let repeated = repeatTextView.text ?? "1"
        guard let repeated = Int(repeated) else {
            return
        }
        do {
            let param = params.dictionary ?? [:]
            let contextParams = param.mapValues {
                convertJsonToAny(value: $0)
            }
            let exprExcutorWrapper = ExprExcutorWrapper(service: serviceImpl, useRust: self.useRustExpr, uuid: UUID().uuidString) as ExprExcutor
            let env = ExpressionEnv(contextParams: contextParams)
            var result: LarkPolicyEngine.ExprEvalResult? = nil
            for i in 0...repeated {
                if i == 0 {
                    result = try exprExcutorWrapper.evaluate(expr: expression, env: env)
                } else {
                    _ = try exprExcutorWrapper.evaluate(expr: expression, env: env)
                }
            }

            if self.useRustExpr {
                outputTextView.text = """
                useRustExpr: \(self.useRustExpr) \n
                ---------------------
                expression: \(expression) \n
                ---------------------
                parameters: \(params) \n
                ---------------------
                result result: \(String(describing: result)) \n
                """
            } else {
                outputTextView.text = """
                useRustExpr: \(self.useRustExpr) \n
                ---------------------
                expression: \(expression) \n
                ---------------------
                parameters: \(params) \n
                ---------------------
                result result: \(String(describing: result)) \n
                """
            }
        } catch {
            outputTextView.text = """
            error: \(error)
            """
        }
    }
}

func convertJsonToAny(value: JSON) -> Any {
    switch value.type {
    case .bool: return value.boolValue
    case .number:
        if value.stringValue.contains(where: { $0 == "." }) {
            return value.doubleValue
        } else {
            return value.int64Value
        }
    case .string: return value.stringValue
    case .array: return convertJsonToArrayValue(value: value)
    case .null: return NSNull()
    default: return ""
    }
}

func convertJsonToArrayValue(value: JSON) -> Any {
    return value.arrayValue.map { item in
        convertJsonToAny(value: item)
    }
}

func switchRustExprValue(value: Security_V1_ExprValue.OneOf_Value?) -> Any {
    var resultValue: Any
    switch value {
    case .stringValue(let value):
        resultValue = value
    case .doubleValue(let value):
        resultValue = value
    case .longValue(let value):
        resultValue = value
    case .boolValue(let value):
        resultValue = value
    case .arrayValue(let value):
        var array: [Any] = []
        for i in value.value {
            let tempValue = switchRustExprValue(value: i.value)
            array.append(tempValue)
        }
        resultValue = array
    default:
        resultValue = ""
    }
    return resultValue
}

struct ErrorInfo1 {
    let code: Int
    let larkErrorCode: Int
    let debugMessage: String
    let displayMessage: String
    let userErrTitle: String?
    let requestID: String?
    let ttLogId: String?
}

struct ErrorInfo2: Error {
    let code: Int
    let larkErrorCode: Int
    let debugMessage: String
    let displayMessage: String
    let userErrTitle: String?
    let requestID: String?
    let ttLogId: String?
}

struct ExprEvalResult {
    let totalCost: UInt64
    let execCost: UInt64
    let parseCost: UInt64
    let firstResult: Any
    var hitCache: Bool? = nil
}

struct ExprEvalError: Error {
    let reason: String
}

fileprivate func nativeExpressionRun(expr: String, param: JSON, repeated: Int, cache: Bool) throws -> ExprEvalResult {
    var firstResult: Any = false
    var totalCost = UInt64(0)
    var execCost = UInt64(0)
    var parseCost = UInt64(0)
    let startTime = CACurrentMediaTime()
    for i in 0...repeated {
        let env = ExpressionDebugEnv(dict: param.dictionaryObject ?? [:])
        LKRuleEngineLogger.register(LKRuleEngineDebugInjectServiceImpl.shared)
        // setup monitor
        LKRuleEngineReporter.register(LKRuleEngineDebugInjectServiceImpl.shared)
        let response: LKREExprResponse = LKREExprRunner().execute(expr, with: env, uuid: nil)
        if response.code != 0 {
            throw ExprEvalError(reason: response.message)
        }
        if i == 0 {
            firstResult = response.result
        }
        parseCost += UInt64(response.parseCost * Double(NSEC_PER_SEC))
        execCost += UInt64(response.execCost * Double(NSEC_PER_SEC))
    }
    let duration = CACurrentMediaTime() - startTime
    totalCost = UInt64(duration * Double(NSEC_PER_SEC))
    return ExprEvalResult(totalCost: totalCost, execCost: execCost, parseCost: parseCost, firstResult: firstResult)
}

fileprivate func rustExpressionRun(expr: String, param: JSON, repeated: Int, cache: Bool) throws -> ExprEvalResult {
    let param = param.dictionary ?? [:]
    var firstResult = Security_V1_ExprValue()
    var hitCache: Bool? = nil
    var totalCost = UInt64(0)
    var execCost = UInt64(0)
    var parseCost = UInt64(0)
    @Provider var rustClient: GlobalRustService
    let startTime = CACurrentMediaTime()
    for i in 0...repeated {
        var request = Security_V1_ExpressionEvalRequest()
        request.enableCache = cache
        request.expression = expr
        request.paramters = try param.mapValues({ value in
            try Security_V1_ExprValue(value: value)
        })
        let response = try rustClient.sync(message: request) as Security_V1_ExpressionEvalResponse
        if i == 0 {
            firstResult = response.result
            hitCache = response.hitCache
        }
        parseCost += response.parseCost
        execCost += response.execCost
    }
    let duration = CACurrentMediaTime() - startTime
    totalCost = UInt64(duration * Double(NSEC_PER_SEC))
    return ExprEvalResult(totalCost: totalCost, execCost: execCost, parseCost: parseCost, firstResult: firstResult, hitCache: hitCache)
}

extension Security_V1_ExprValue {
    init(value: JSON) throws {
        self.init()
        switch value.type {
        case .bool: self.value = .boolValue(value.boolValue)
        case .number:
            if value.stringValue.contains(where: { $0 == "." }) {
                self.value = .doubleValue(value.doubleValue)
            } else {
                self.value = .longValue(value.int64Value)
            }
        case .string: self.value = .stringValue(value.stringValue)
        case .array: self.value = .arrayValue(try ArrayValue(value: value))
        case .null: self.value = .nullValue(Security_V1_ExprValue.NullValue())
        default: throw ExprEvalError(reason: "unknow value :\(value)")
        }
    }
}

extension Security_V1_ExprValue.ArrayValue {
    init(value: JSON) throws {
        self.init()
        self.value = try value.arrayValue.map({ item in
            try Security_V1_ExprValue(value: item)
        })
    }
}

final class ExpressionDebugEnv:NSObject, LKREExprEnvProtocol {
    func hasEnvValue(ofKey key: String) -> Bool {
        dict.keys.contains(key)
    }
    
    func envValue(ofKey key: String) -> Any? {
        return dict[key]
    }
    
    func resetCost() {
        
    }
    
    func cost() -> CFTimeInterval {
        return 0
    }
    
    let dict: [AnyHashable: Any]
    
    init(dict: [AnyHashable: Any]) {
        self.dict = dict
    }
}

@objc
final class LKRuleEngineDebugInjectServiceImpl: NSObject, LKRuleEngineLoggerProtocol, LKRuleEngineReporterProtocol {

    static let shared = LKRuleEngineDebugInjectServiceImpl()


    func log(with level: LKRuleEngineLogLevel, message: String, file: String, line: Int, function: String) {
        
    }

    func log(_ event: String, metric: [String: Any], category: [String: Any]) {
        
    }
}
