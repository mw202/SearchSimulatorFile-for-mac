//
//  DirectoryTreeModel.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/4.
//

import Cocoa

class DirectoryTreeInfo {
    var name: String = ""
    var icon: NSImage?
    var fullPath: String = ""
    var createDate: Date?
    var size: Int?
    var parent: DirectoryTreeInfo?
    var children: [DirectoryTreeInfo]?
    var isDirectory: Bool = false
    var isHidden: Bool = false
    var isPackage: Bool = false
    
    init() {}
    
    init(_ resource: URLResourceValues?) {
        let name = resource?.name ?? "Unknown"
        let icon = resource?.effectiveIcon as? NSImage
        let fullPath = resource?.path
        let date = resource?.creationDate ?? Date()
        let size = resource?.fileSize ?? 0
        let isDirectory = resource?.isDirectory ?? false
        let isHidden = resource?.isHidden ?? false
        let isPackage = resource?.isPackage ?? false
        
        self.name = name
        self.icon = icon
        self.fullPath = fullPath ?? ""
        self.createDate = date
        self.size = size
        self.parent = nil
        self.children = []
        self.isDirectory = isDirectory
        self.isHidden = isHidden
        self.isPackage = isPackage
    }
}

class ApplicationInfo {
    var identifier: String = ""
    var fullPath: String = ""
    var UUID: String = ""
    var size: Int = 0
    var files: [DirectoryTreeInfo] = []
    
    static let metaDataFile = ".com.apple.mobile_container_manager.metadata.plist"
    static let kMetaIdentifier = "MCMMetadataIdentifier"
    static let kMetaUUID = "MCMMetadataUUID"
    static let kMetaInfo = "MCMMetadataInfo"
    static let kSize = "StaticDiskUsage"
    
    init() {}
    
    init(_ dic: Dictionary<String, Any>) {
        self.identifier = dic[Self.kMetaIdentifier] as? String ?? ""
        self.UUID = dic[Self.kMetaUUID] as? String ?? ""
        if let info = dic[Self.kMetaInfo] as? Dictionary<String, Any> {
            self.size = info[Self.kSize] as? Int ?? 0
        }
    }
}

class DeviceInfo {
    var udid: String = ""
    var deviceName: String = "" // com.apple.CoreSimulator.SimDeviceType.iPad--5th-generation-
    var folder: String = "" // 9197A59A-2830-48E8-8528-D7C0D36070BA
    var isDelete: Bool = false
    var state: Int = 0
    var application: [ApplicationInfo] = []
    
    static let deviceFileName = "device.plist"
    static let kUDID = "UDID"
    static let kName = "name"
    static let kType = "deviceType"
    static let kIsDeleted = "isDeleted"
    static let kState = "state"
    
    init() {}
    
    init(_ dic: Dictionary<String, Any>) {
        self.udid = dic[Self.kUDID] as? String ?? ""
        self.deviceName = dic[Self.kName] as? String ?? ""
        self.isDelete = dic[Self.kIsDeleted] as? Bool ?? false
        self.state = dic[Self.kState] as? Int ?? 0
    }
}

class RuntimeInfo {
    var iOS: String = "" // com.apple.CoreSimulator.SimRuntime.iOS-10-3
    var deviceInfo: [DeviceInfo] = []
    
    static let deviceSetFileName = "device_set.plist"
    static let kDefaultDevices = "DefaultDevices"
}
