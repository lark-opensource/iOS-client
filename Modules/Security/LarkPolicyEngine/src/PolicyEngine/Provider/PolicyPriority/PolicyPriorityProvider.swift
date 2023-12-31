//
//  PolicyPriorityProvider.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/19.
//

import Foundation
import LarkSnCService
import LarkExpressionEngine

final class PolicyPriorityProvider {
    private let policyProvider: PolicyProvider
    private let factorProvider: SubjectFactorProvider
    private let service: SnCService
    private weak var actionSender: ProviderDelegate?
    private let excutor: ExprExcutor
    
    var priorityData: PolicyPriorityData?
    
    init(policyProvider: PolicyProvider, factorProvider: SubjectFactorProvider, service: SnCService) {
        self.policyProvider = policyProvider
        self.factorProvider = factorProvider
        self.service = service
        let setting = Setting(service: service)
        self.excutor = ExprExcutorWrapper(service: service, useRust: setting.isUseRustExpressionEngine, uuid: UUID().uuidString)
        self.priorityData = readFromCache()
    }
}

// MARK: - Build Priority
extension PolicyPriorityProvider {
    
    private func rebuildPolicyPriority() {
        guard let policies = policyProvider.selectAllPolicy() else {
            service.logger?.info("Cancel update policy priority while policy not fetch successfully.")
            clearPriorityData()
            return
        }

        guard let userID = Int64(service.environment?.userId ?? "") else {
            service.logger?.error("Fail to get user id while rebuild policy priority.")
            clearPriorityData()
            return
        }
        let subjectInfo = factorProvider.getSubjectFactorDict()
        guard let groupIdList = subjectInfo[FactorKey.groupID.rawValue] as? [Int64],
              let deptIDPaths = subjectInfo[FactorKey.deptIDPaths.rawValue] as? [[Int64]],
              let deptIdsWithParent = subjectInfo[FactorKey.deptID.rawValue] as? [Int64] else {
            service.logger?.error("Fail to get user id while rebuild policy priority. subject info: \(String(describing: subjectInfo))")
            clearPriorityData()
            return
        }
        
        let policyMap: PolicyMap = policies.mapValues { PolicyInfo(version: $0.version, filterCondition: $0.filterCondition.rawExpression) }
        logMsg(level: .info, "Begin update policy priority. policy list: \(policyMap), subjectInfo: \(String(describing: subjectInfo))")
        do {
            let (userFlag, user) = try rebuildUserPolicy(userID: userID, policies: policyMap)
            let (groupFlag, group) = try rebuildUserGroupPolicy(groupIds: groupIdList, policies: policyMap)
            let (deptFlag, dept) = try rebuildDeptPolicy(deptIDs: deptIdsWithParent, deptPath: deptIDPaths, policies: policyMap)
            let (tenantFlag, tenant) = try rebuildTenantPolicy(policies: policyMap)
            
            if userFlag || groupFlag || deptFlag || tenantFlag {
                let priorityData = PolicyPriorityData(user: user, userGroup: group, department: dept, tenant: tenant)
                service.logger?.info("Policy priority data did update: \(priorityData)")
                self.priorityData = priorityData
                saveToCache(priorityInfo: priorityData)
            } else {
                service.logger?.info("Policy priority data has no change at this update time.")
            }
        } catch {
            // exception, delete all cache
            service.logger?.error("Throw an exception while update policy priority data. error: \(error)")
            clearPriorityData()
        }
        
    }
    
    /// return (isUpdate, newData)
    private func rebuildUserPolicy(userID: Int64, policies: PolicyMap) throws -> (Bool, UserPolicyData) {
        let forceUpdate = priorityData?.user == nil
        let priorityData = (priorityData?.user) ?? UserPolicyData(policyMap: [:])
        let excutorEnv = buildExpressionEnv(userID: userID)
        
        let (hasChange, policyMap) = try combinePolicyMap(old: priorityData.policyMap, new: policies, env: excutorEnv)
        
        return (hasChange || forceUpdate, UserPolicyData(policyMap: policyMap))
    }
    
    private func rebuildUserGroupPolicy(groupIds: [Int64], policies: PolicyMap) throws -> (Bool, UserGroupPolicyData) {
        
        let forceUpdate = priorityData?.userGroup == nil
        
        var priorityData = (priorityData?.userGroup) ?? UserGroupPolicyData(groupIdList: [], policyMap: [:])
        if !compareIntArray(left: groupIds, right: priorityData.groupIdList) {
            // group id has changed, need to rebuild all user group policies priority data
            priorityData = UserGroupPolicyData(groupIdList: groupIds, policyMap: [:])
        }
        let env = buildExpressionEnv(groupIDs: groupIds)
        
        let (hasChange, policyMap) = try combinePolicyMap(old: priorityData.policyMap, new: policies, env: env)
        
        return (hasChange || forceUpdate, UserGroupPolicyData(groupIdList: groupIds, policyMap: policyMap))
    }
    
    private func rebuildDeptPolicy(deptIDs: [Int64], deptPath: [[Int64]], policies: PolicyMap) throws -> (Bool, DeptPolicyData) {
        // build current dept ids priority data
        let forceUpdate = priorityData?.department == nil
        
        var priorityData = priorityData?.department ?? DeptPolicyData()
        
        if !compareIntArray(left: deptIDs, right: priorityData.userDeptIdsWithParent) || !compare2DIntArray(left: deptPath, right: priorityData.userDeptIDPaths) {
            // 部门 或 上下级发生变化
            logMsg(level: .info, "Dept has changed. will rebuild policy priority data.")
            priorityData = DeptPolicyData(userDeptIdsWithParent: deptIDs, userDeptIDPaths: deptPath, rootNode: try buildDeptNode(path: deptPath), policyMap: [:])
        }
        let env = buildExpressionEnv(deptIDs: deptIDs)
        
        let (hasChange, policyMap) = try combinePolicyMap(old: priorityData.policyMap, new: policies, env: env)
        
        guard hasChange else {
            return (hasChange || forceUpdate, priorityData)
        }
        
        // update tree
        var hasUpdateNodes: Set<Int64> = []
        var queue: [DeptNode] = [priorityData.rootNode]
        // bfs
        while let node = queue.first {
            if !queue.isEmpty {
                queue.removeFirst()
            }
            if hasUpdateNodes.contains(node.deptId) {
                continue
            }
            hasUpdateNodes.insert(node.deptId)
            queue.append(contentsOf: node.children.values)
            
            let env = buildExpressionEnv(deptIDs: [node.deptId])
            let (hasChange, nodePolicyMap) = try combinePolicyMap(old: node.policyMap, new: policyMap, env: env)
            guard hasChange else {
                continue
            }
            node.policyMap = nodePolicyMap
        }

        return (true, DeptPolicyData(userDeptIdsWithParent: deptIDs, userDeptIDPaths: deptPath, rootNode: priorityData.rootNode, policyMap: policies))
    }
    
    private func rebuildTenantPolicy(policies: PolicyMap) throws -> (Bool, TenantPolicyData) {
        let forceUpdate = priorityData?.tenant == nil
        let priorityData = (priorityData?.tenant) ?? TenantPolicyData(policyMap: [:])
        
        // DEFAULT_COMPANY_DEPT_ID = -1
        let excutorEnv = buildExpressionEnv(deptIDs: [DEFAULT_COMPANY_DEPT_ID])
        
        let (hasChange, policyMap) = try combinePolicyMap(old: priorityData.policyMap, new: policies, env: excutorEnv)
        
        return (hasChange || forceUpdate, TenantPolicyData(policyMap: policyMap))
    }
    
    // MARK: - Private Utils
    private func clearPriorityData() {
        self.priorityData = nil
        saveToCache(priorityInfo: nil)
        service.logger?.info("Did clear policy priority data.")
    }
    
    private func combinePolicyMap(old: PolicyMap, new: PolicyMap, env: ExpressionEnv) throws -> (Bool, PolicyMap) {
        // filter reserve list
        let reserve = new.filter { element in old.contains { $0 == element } }
        let append = new.filter { element in !old.contains { $0 == element } }

        // check newly
        let add = try append.filter { (_, policyInfo) in
            return try excute(expr: policyInfo.filterCondition, env: env)
        }
        // 策略集合有变化，但无新增，且保留部分的无变化
        if reserve.count == old.count && add.isEmpty {
            return (false, old)
        }
        return (true, reserve.merging(add) { f, _ in f })
    }

    private func compareIntArray(left: [Int64], right: [Int64]) -> Bool {
        guard left.count == right.count else {
            return false
        }
        
        let leftSet = Set(left)
        let rightSet = Set(right)
        
        return leftSet == rightSet
    }

    private func compare2DIntArray(left: [[Int64]], right: [[Int64]]) -> Bool {
        guard left.count == right.count else {
            return false
        }
        
        let leftSet = Set(left.map { Set($0) })
        let rightSet = Set(right.map { Set($0) })
        
        if leftSet != rightSet {
            return false
        }
        
        return true
    }
}

// MARK: - ExprExcutor
extension PolicyPriorityProvider {

    private func reportFailure(expr: String, code: UInt, reason: String) {
        self.service.monitor?.info(service: "expression_engine_exec_failure", category: [
            "code": code,
            "reason": reason,
            "expression": expr,
            "type": excutor.type().rawValue
        ])
    }
    
    func excute(expr: String, env: ExpressionEnv) throws -> Bool {
        do {
            let response = try excutor.evaluate(expr: expr, env: env)
            guard let result = response.result else {
                throw ExprEngineError(code: ExprErrorCode.unknown.rawValue, msg: "Result is not a bool value, real type: \(response.raw)")
            }
            return result
        } catch let err as ExprEngineError {
            reportFailure(expr: expr, code: err.code.rawValue, reason: err.msg)
            logMsg(level: .error, err.msg)
            throw err
        } catch {
            reportFailure(expr: expr, code: ExprErrorCode.unknown.rawValue, reason: error.localizedDescription)
            logMsg(level: .error, error.localizedDescription)
            throw error
        }
    }

    func logMsg(level: LogLevel,
                _ message: String,
                file: String = #fileID,
                line: Int = #line,
                function: String = #function) {
        service.logger?.log(level: level, "\(message)", file: file, line: line, function: function)
    }
}

// MARK: - Cache
extension PolicyPriorityProvider {
    
    private static let policyPriorityCacheKey = "PolicyPriorityCacheKey"
    
    private func readFromCache() -> PolicyPriorityData? {
        do {
            guard let priorityData: PolicyPriorityData = try service.storage?.get(key: Self.policyPriorityCacheKey) else {
                service.logger?.info("policy priority cache is empty.")
                return nil
            }
            return priorityData
        } catch {
            service.logger?.error("fail to get policy priority cache, error: \(error)")
            return nil
        }
    }
    
    private func saveToCache(priorityInfo: PolicyPriorityData?) {
        do {
            try service.storage?.set(priorityInfo, forKey: Self.policyPriorityCacheKey)
        } catch {
            service.logger?.error("fail to set policy priority cache, error: \(error)")
        }
    }
}

extension PolicyPriorityProvider: EventDriver {
    
    static let subscribeEvent: [InnerEvent] = [.policyUpdate, .subjectFactorUpdate]
    
    func receivedEvent(event: InnerEvent) {
        if Self.subscribeEvent.contains(event) {
            rebuildPolicyPriority()
        }
    }
}

// MARK: - Context
let FACTOR_DEFAULT_VALUE: Int64 = -404
let DEFAULT_COMPANY_DEPT_ID: Int64 = -1

fileprivate func buildExpressionEnv(userID: Int64 = FACTOR_DEFAULT_VALUE,
                               groupIDs: [Int64] = [FACTOR_DEFAULT_VALUE],
                               deptIDs: [Int64] = [FACTOR_DEFAULT_VALUE]) -> ExpressionEnv {
    return ExpressionEnv(contextParams: [
        FactorKey.userID.rawValue: userID,
        FactorKey.groupID.rawValue: groupIDs,
        FactorKey.deptID.rawValue: deptIDs
    ])
}

fileprivate func buildDeptNode(path: [[Int64]]) throws -> DeptNode {
    guard let rootId = path.first?.first else {
        throw CustomStringError("Dept path is empty.")
    }
    let rootNode = DeptNode(deptId: rootId)
    for depts in path {
        // double check.
        guard let firstDeptId = depts.first, firstDeptId == rootId else {
            throw CustomStringError("Dept path root id not match.")
        }
        var current = rootNode
        for dept in depts.suffix(from: 1) {
            let next = current.children[dept] ?? DeptNode(deptId: dept)
            current.children[dept] = next
            current = next
        }
    }
    return rootNode
}
