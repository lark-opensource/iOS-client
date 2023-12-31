//
//  WebBrowserDebugTool.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/3/24.
//

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

#if DEBUG || BETA || ALPHA
import Foundation
import LarkDebugExtensionPoint
import EENavigator
import UIKit
import WebKit
import LKCommonsLogging
import LarkEnv

public class WebBrowserDebugItem: NSObject,DebugCellItem,UITableViewDelegate,UITableViewDataSource {
    public var title: String = "WebBrowser debug Config"
    public var detail: String = "detail"
    public var type: DebugCellType = .disclosureIndicator
    
    private var textField: UITextField?
    private var webBrwoserDebugController: UIViewController?
    private var vConsoleS: UISwitch?
    private var addHeaderS: UISwitch?
    private var memoryrPesureS: UISwitch?
    private var memoryrPesureSValue : Bool = false
    
    private var memoryrPesureSlider: UISlider?
    static var memoryCache: [String] = [String]()
    
    public static let vConsoleDebugKey: String = "webBrowser_debug_vConsole_key"
    private static let addHeaderDebugKey: String = "webBrowser_debug_addHeader_key"
    private static var vConsoleCurrentState = UserDefaults.standard.bool(forKey: vConsoleDebugKey)
    static var enbaleAddHeaderState = UserDefaults.standard.bool(forKey: addHeaderDebugKey)
    static private let logger = Logger.webBrowserLog(WebBrowserDebugItem.self, category: "WebBrowserDebugItem")

    deinit{
        print("WebBrowserDebugItem dealloc")
    }
    
    public func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let controller = UIViewController.init()
        controller.title = "WebBrowser debug Config"
        self.webBrwoserDebugController = controller
        controller.view.backgroundColor = UIColor.white
        let configTableview = UITableView.init(frame: controller.view.bounds)
        controller.view.addSubview(configTableview)
        configTableview.delegate = self
        configTableview.dataSource = self
        Navigator.shared.push(controller, from: debugVC)// user:global
    }
    
 
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let tableFooterView = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
        let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: tableFooterView.btd_width, height: 30))
        label.isUserInteractionEnabled = true
        label.textColor = UIColor(red: 89/255.0, green: 126/255.0, blue: 254/255.0, alpha: 1.0)
        label.text = "click here to get more info from internal document."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        let tapR = UITapGestureRecognizer.init(target: self, action: #selector(tapSectionFooterForMoreInformation(tapRecognizer:)))
        label.addGestureRecognizer(tapR)
        tableFooterView.addSubview(label)
        return tableFooterView
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "enbale VConsole(need VPN)"
            let vConsoleS = UISwitch()
            vConsoleS.setOn(Self.vConsoleCurrentState, animated: false)
            vConsoleS.addTarget(self, action: #selector(switchButtonDidClick(aSwitch:)), for: .valueChanged)
            self.vConsoleS = vConsoleS
            cell.accessoryView = vConsoleS
        case 1:
            cell.textLabel?.text = "enable add header for request"
            let addHeaderS = UISwitch()
            addHeaderS.setOn(Self.enbaleAddHeaderState, animated: false)
            addHeaderS.addTarget(self, action: #selector(switchButtonDidClick(aSwitch:)), for: .valueChanged)
            self.addHeaderS = addHeaderS
            cell.accessoryView = addHeaderS
        case 2:
       
            let inputTextfield = UITextField.init(frame: CGRect(x: 20, y:2, width: 270, height: 46))
            self.textField = inputTextfield
            inputTextfield.placeholder = "http://www.baidu.com"
            inputTextfield.leftView = UIView.init(frame: CGRect(x: 0, y:0, width: 5, height: 40))
            inputTextfield.leftViewMode = .always
            inputTextfield.borderStyle = .roundedRect
            inputTextfield.layer.borderWidth = 1
            inputTextfield.layer.borderColor = UIColor.lightGray.cgColor
            cell.contentView.addSubview(inputTextfield)
            cell.addSubview(inputTextfield)
            
            let button = UIButton(frame: CGRect.init(x: tableView.bounds.width-98, y:3 , width:88, height: 44))
            button.layer.cornerRadius = 5
            button.layer.masksToBounds = true
            button.backgroundColor = UIColor(red: 50/255.0, green: 191/255.0, blue: 71/255.0, alpha: 1.0)
            button.setTitleColor(UIColor.white, for: .normal)
            button.addTarget(self, action: #selector(openUrlInSystemWebBrowser(button:)), for: .touchUpInside)
            button.setTitle("Pure", for: .normal)
            cell.contentView.addSubview(inputTextfield)
            cell.contentView.addSubview(button)
        case 3:
            cell.textLabel?.text = "mempory presure"
//            let addHeaderS = UISwitch()
//            addHeaderS.setOn(self.memoryrPesureSValue, animated: false)
//            addHeaderS.addTarget(self, action: #selector(switchButtonDidClick(aSwitch:)), for: .valueChanged)
            let slider=UISlider()
            slider.minimumValue = 0  //最小值
            slider.maximumValue = 5000  //最大值
            slider.value = 0  //当前默认值
            slider.isContinuous = false
            slider.addTarget(self, action:#selector(memorySliderValueChanged(slider:)), for:.valueChanged)
            self.memoryrPesureSlider = slider
            cell.accessoryView = slider
        default:
            cell.textLabel?.text = ""
        }
        cell.selectionStyle = .none
        return cell
    }

    @objc
    func switchButtonDidClick(aSwitch:UISwitch){
        let value = aSwitch.isOn
        if (aSwitch == self.vConsoleS){
            Self.vConsoleCurrentState = value
            UserDefaults.standard.set(value, forKey:Self.vConsoleDebugKey)
            if value == true {
                self.prepareVConsoleResource()
            }
        }else if (aSwitch == self.addHeaderS){
            Self.enbaleAddHeaderState = value
            UserDefaults.standard.set(value, forKey:Self.addHeaderDebugKey)
        } else {
            //do nothing
        }
    }
    
    @objc
    func tapSectionFooterForMoreInformation(tapRecognizer:UITapGestureRecognizer){
        let docStr = "https://bytedance.feishu.cn/docx/LbbKdlvXXo4ib2xz2pqcACLfnVf"
        let controller = UIViewController.init()
        controller.view.backgroundColor = UIColor.white
        let webview = WKWebView.init(frame: controller.view.bounds)
        controller.view.addSubview(webview)
        if let url = URL.init(string: docStr),let fromVc = self.webBrwoserDebugController{
            webview.load(URLRequest(url:url))
            Navigator.shared.push(controller, from:fromVc)// user:global
        }
    }
    
    static public func enbaleVConsoleIfInDebugEnvironment(userController:WKUserContentController) {
        if Self.vConsoleCurrentState == true {
            let fileManager = FileManager.default
            let documentPath =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let jsFilePath = documentPath.appendingPathComponent("webBrowser/vconsole.min.js")
            if fileManager.fileExists(atPath: jsFilePath) {
                let fileContent = try? String.init(contentsOfFile: jsFilePath, encoding: .utf8)
                if let jsContent = fileContent {
                    let script = WKUserScript.init(source: jsContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    userController.addUserScript(script)
                }
            }
        }
    }
    
    static public func enbaleAddHeaderIfInDebugEnvironment(request:inout URLRequest) {
        if Self.enbaleAddHeaderState == true {
            if (EnvManager.env.isStaging) {
                request.setValue("1", forHTTPHeaderField: "x-use-boe")
            }
            
            let boeFdValue = UserDefaults.standard.string(forKey: "BOEFdKey")
            if let boeFd = boeFdValue?.components(separatedBy: ":") {
                if boeFd.count == 2 {
                    let key = boeFd[0]
                    let value = boeFd[1]
                    request.setValue(value, forHTTPHeaderField: "Rpc-Persist-Dyecp-Fd-\(key)")
                }
            }
            
            if let xttEnv = UserDefaults.standard.string(forKey: "x-tt-env") {
                if xttEnv.count > 0 {
                    request.setValue(xttEnv, forHTTPHeaderField: "x-tt-env")
                }
            }
        }
    }
    
    func prepareVConsoleResource(){
        //检测vConsole js文件是否存在
        let fileManager = FileManager.default
        let documentPathTemp =  NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let documentPath =  documentPathTemp.appendingPathComponent("webBrowser")
        if !fileManager.fileExists(atPath: documentPath) {
            _ = try? fileManager.createDirectory(atPath: documentPath, withIntermediateDirectories: true)
        }
        let jsFilePath = (documentPath as NSString).appendingPathComponent("vconsole.min.js")
        if !fileManager.fileExists(atPath: jsFilePath) {
            if let url:URL = URL(string: "http://tosv.byted.org/obj/openplatform-client-test-cn/vconsole.min.js") {
                let session = URLSession.shared
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                let task = session.dataTask(with: request as URLRequest) {(
                    data, response, error) in
                    guard var data = data, let _:URLResponse = response, error == nil else {
                        return
                    }
                let extraJsString = "\nlet vConsole = new VConsole();\nconsole.log(\"Let start lark debug!\");"
                let extraData = extraJsString.data(using: .utf8)!
                data.append(extraData)
                let isSuccess =  fileManager.createFile(atPath: jsFilePath, contents: data)
                if (isSuccess){
                    Self.logger.info("config vConsole successfully")
                }
                }
                task.resume()
            }
        }else{
            Self.logger.info("vconsole.min.js has already existed")
        }
    }
                             

    @objc
    func openUrlInSystemWebBrowser(button:UIButton){
        guard let urlString = self.textField?.text,let fromVc = self.webBrwoserDebugController else{
            return
        }
        let controller = UIViewController.init()
        controller.view.backgroundColor = UIColor.white
        let webview = WKWebView.init(frame: controller.view.bounds)
        controller.view.addSubview(webview)
        if let url = URL.init(string: urlString){
            webview.load(URLRequest(url:url))
            Navigator.shared.push(controller, from:fromVc )// user:global
        }else{
            Self.logger.info("please check the url")
        }
    }
    
    @objc
    func memorySliderValueChanged(slider:UISlider){
//        memoryCache.removeAll()
        let loop = Int(slider.value)
        DispatchQueue.global().async {
            for i in (0...loop) {
                for j in (0...loop) {
                    Self.memoryCache.append(UUID().uuidString)
                }
            }
        }
    }
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.textField?.resignFirstResponder()
    }
}
#endif
