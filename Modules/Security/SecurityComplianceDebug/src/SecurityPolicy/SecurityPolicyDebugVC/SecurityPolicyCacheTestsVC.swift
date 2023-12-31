//
//  SecurityPolicyCacheTests.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/6/20.
//

import UIKit
import LarkSecurityCompliance
import UniverseDesignToast
import LarkSecurityComplianceInterface

class SecurityPolicyCacheTestsVC: UITableViewController {
    
    private var cache: FIFOCache!
 
    enum Tests: String, CaseIterable {
        case clear = "清理数据"
        case testWriteCache = "数据写入测试"
        case testGetCache = "数据读取测试(构造1000条key)"
        case testGetCacheAll = "数据读取测试(读取所有数据)"
        case testMigrateDataToBigger = "修改size，增大10"
        case testMigrateDataToSmaller = "修改size，减少10"
    }
    
    static let testUID = "215412544212235412"
    static let testPointKey = "POINT_KEY"
    
    let array = Tests.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cache = FIFOCache(userID: Self.testUID, maxSize: 100, cacheKey: Self.testPointKey)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        array.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = array[indexPath.row].rawValue
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let test = array[indexPath.row]
        switch test {
        case .clear:
            cache.cleanAll()
            cache = FIFOCache(userID: Self.testUID, maxSize: 100, cacheKey: Self.testPointKey)
            showAlert(title: "清理成功", message: nil)
            
        case .testWriteCache:
            for i in 1 ..< 1000 {
                cache.write(value: "testdata_\(i)", forKey: "cache_key_\(i)")
            }
            showAlert(title: "写入一千条数据成功", message: nil)
            
        case .testGetCache:
            var results = [String]()
            for i in 1 ..< 1000 {
                if let str: String = cache.read(forKey: "cache_key_\(i)") {
                    results.append(str)
                }
            }
            showAlert(title: "读取数据成功", message: results.description)
            
        case .testMigrateDataToBigger:
            UDToast.showLoading(with: "数据迁移中", on: UIWindow.ud.keyWindow!)
            FIFOCache.writeCacheQueue.async {
                let count = self.cache.max
                self.cache = FIFOCache(userID: Self.testUID, maxSize: count + 10, cacheKey: Self.testPointKey)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let all: [String] = self.cache.getAllRealCache()
                    UDToast.removeToast(on: UIWindow.ud.keyWindow!)
                    self.showAlert(title: "数据迁移成功+10", message: all.joined(separator: "\n"))
                }
            }
            
        case .testMigrateDataToSmaller:
            UDToast.showLoading(with: "数据迁移中", on: UIWindow.ud.keyWindow!)
            FIFOCache.writeCacheQueue.async {
                let count = self.cache.max
                self.cache = FIFOCache(userID: Self.testUID, maxSize: count - 10, cacheKey: Self.testPointKey)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let all: [String] = self.cache.getAllRealCache()
                    UDToast.removeToast(on: UIWindow.ud.keyWindow!)
                    self.showAlert(title: "数据迁移成功-10", message: all.joined(separator: "\n"))
                }
            }
            
        case .testGetCacheAll:
            let all: [String] = cache.getAllRealCache()
            showAlert(title: "数据读取成功", message: all.description)

        }
    }
    
    
    private func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "我知道了", style: .default))
        self.present(alert, animated: true)
    }
}
