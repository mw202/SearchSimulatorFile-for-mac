//
//  MainViewController.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/4.
//

import Cocoa

class MainViewController: NSViewController {

    @IBOutlet weak var textFieldPath: NSTextField!
    @IBOutlet weak var buttonRefresh: NSButton!
    @IBOutlet weak var outlineViewDirectory: NSOutlineView!
    
    @IBOutlet weak var textFieldSearchId: NSTextField!
    @IBOutlet weak var tableViewFile: NSTableView!
    @IBOutlet var menuFile: NSMenu!
    @IBOutlet weak var menuItemOpenFile: NSMenuItem!
    @IBOutlet weak var menuItemOpenFolder: NSMenuItem!
    @IBOutlet weak var labelFileCount: NSTextField!
    
    private let kFilterId = "\(Bundle.main.bundleIdentifier ?? "com").filter.identifier"
    private var files: [DirectoryTreeModel]? {
        willSet {
            labelFileCount.stringValue = "\(newValue?.count ?? 0) 个文件"
        }
    }
    private var sortDescriptor: NSSortDescriptor?
    private var devicesDirectory = ""
    private var deviceSetFile: String {
        return "\(devicesDirectory)/\(RuntimeInfo.deviceSetFileName)"
    }
    private var runtimes: [RuntimeInfo]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        files = []
        devicesDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Developer/CoreSimulator/Devices").path ?? ""
        
        setupUI()
        
        loadDeviceSet()
        
        outlineViewDirectory.reloadData()
        tableViewFile.reloadData()
    }
    
    // MARK: -
    
    func decoderPlistFile(_ url: URL) -> Dictionary<String, Any>? {
        if let dataDevicesSet = try? Data(contentsOf: url) {
            return try? PropertyListSerialization.propertyList(from: dataDevicesSet, options: [], format: nil) as? Dictionary<String, Any>
        }
        
        return nil
    }
    
    func loadDeviceSet(_ filterId: String? = nil) {
        runtimes = []
        if let dicDevicesSet = decoderPlistFile(URL(fileURLWithPath: deviceSetFile)) {
            if let devices = dicDevicesSet["DefaultDevices"] as? [String: Any] {
                for (key, value) in devices {
                    let runtime = RuntimeInfo()
                    runtime.iOS = key.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                    if let v = value as? Dictionary<String, String> {
                        for (_, f) in v.enumerated() {
                            let folder = "\(devicesDirectory)/\(f.value)"
                            let deviceFile = "\(folder)/\(DeviceInfo.deviceFileName)"
                            if let dicDevice = decoderPlistFile(URL(fileURLWithPath: deviceFile)) {
                                let device = DeviceInfo(dicDevice)
                                runtime.deviceInfo.append(device)
                                let appFolder = "\(folder)/data/Containers/Data/Application/"
                                
                                let fileManager = FileManager.default
                                let keys: [URLResourceKey] = [.creationDateKey, .isHiddenKey, .isDirectoryKey, .parentDirectoryURLKey, .fileSizeKey, .nameKey, .isPackageKey, .effectiveIconKey, .pathKey]
                                
                                do {
                                    let contents = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: appFolder), includingPropertiesForKeys: nil)
                                    for content in contents {
                                        let resource = try? content.resourceValues(forKeys: Set(keys))
                                        let item = DirectoryTreeModel(resource)
                                        if item.isDirectory && !item.isPackage {
                                            let metaFile = "\(item.fullPath)/\(ApplicationInfo.metaDataFile)"
                                            if let dicMeta = decoderPlistFile(URL(fileURLWithPath: metaFile)) {
                                                let application = ApplicationInfo(dicMeta)
                                                application.fullPath = item.fullPath
                                                
                                                if let filter = filterId, filter.count > 0 {
                                                    if application.identifier.contains(filter) {
                                                        device.application.append(application)
                                                    }
                                                } else {
                                                    device.application.append(application)
                                                }
                                            }
                                        }
                                    }
                                    device.application.sort(by: {a1, a2 in
                                        return a1.identifier < a2.identifier
                                    })
                                } catch {
                                    //
                                }
                                
                            }
                        }
                        runtime.deviceInfo = runtime.deviceInfo.filter({ $0.application.count > 0 })
                        runtime.deviceInfo.sort(by: {d1, d2 in
                            return d1.deviceName < d2.deviceName
                        })
                    }
                    runtimes?.append(runtime)
                }
            }
        }
        runtimes = runtimes?.filter({ $0.deviceInfo.count > 0 })
        runtimes?.sort(by: { r1, r2 in
            return r1.iOS < r2.iOS
        })
    }
    
    func setupUI() {
        tableViewFile.menu = menuFile
        
        textFieldPath.stringValue = devicesDirectory
        
        textFieldSearchId.delegate = self
        textFieldSearchId.stringValue = UserDefaults.standard.value(forKey: kFilterId) as? String ?? ""
        
        // 排序
        let sortName = NSSortDescriptor(key: "name", ascending: true)
        let sortDate = NSSortDescriptor(key: "createDate", ascending: false)
        let sortSize = NSSortDescriptor(key: "size", ascending: true)
        tableViewFile.tableColumns.safeObject(index: 0)?.sortDescriptorPrototype = sortName
        tableViewFile.tableColumns.safeObject(index: 1)?.sortDescriptorPrototype = sortDate
        tableViewFile.tableColumns.safeObject(index: 2)?.sortDescriptorPrototype = sortSize
    }
    
    func SearchSimulatorFile(_ url: URL) -> [DirectoryTreeModel] {
        var items: [DirectoryTreeModel] = []

        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.creationDateKey, .isHiddenKey, .isDirectoryKey, .parentDirectoryURLKey, .fileSizeKey, .nameKey, .isPackageKey, .effectiveIconKey, .pathKey]

        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for content in contents {
                let resource = try? content.resourceValues(forKeys: Set(keys))
                let item = DirectoryTreeModel(resource)
                items.append(item)
            }
        } catch {
            //
        }
        
        return sortedFile(items) ?? []
    }
    
    func sortedFile(_ items: [DirectoryTreeModel]?) -> [DirectoryTreeModel]? { 
        // sortedArray(using sortDescriptors: [NSSortDescriptor]) 闪退
        return items?.sorted { (c1, c2) -> Bool in
            var b = true
            // 默认名字排序
            let sd = self.sortDescriptor ?? NSSortDescriptor(key: "name", ascending: false)
            
            var b1 = true
            if sd.key == "name" {
                if sd.ascending {
                    b1 = (c1.name > c2.name)
                } else {
                    b1 = (c1.name < c2.name)
                }
                b = b && b1
            }
            if sd.key == "createDate" {
                if sd.ascending {
                    b1 = (c1.createDate ?? Date() > c2.createDate ?? Date())
                } else {
                    b1 = (c1.createDate ?? Date() < c2.createDate ?? Date())
                }
                b = b && b1
            }
            if sd.key == "size" {
                if sd.ascending {
                    b1 = (c1.size ?? 0 > c2.size ?? 0)
                } else {
                    b1 = (c1.size ?? 0 < c2.size ?? 0)
                }
                b = b && b1
            }
            
            return b
        }
    }
    
    func openUrl(_ index: Int, isDirectory: Bool = false) {
        guard index >= 0 else {
            return
        }
        
        if let item = files?.safeObject(index: index) {
            var url = URL(fileURLWithPath: item.fullPath)
            if isDirectory {
                url = url.deletingLastPathComponent()
            }
            
            NSWorkspace.shared.open(url)
        }
    }
    
    func searchChildren(_ object: Any?, reloadFile: Bool) {
        var path = ""
        if let item = object as? ApplicationInfo {
            path = item.fullPath
            item.files.removeAll()
        }
        if let item = object as? DirectoryTreeModel {
            path = item.fullPath
            item.children?.removeAll()
        }
        files?.removeAll()
        if path.count > 0 {
            files = SearchSimulatorFile(URL(fileURLWithPath: path))
            if let f = files, let item = object as? ApplicationInfo {
                item.files.append(contentsOf: f)
            }
            if let f = files, let item = object as? DirectoryTreeModel {
                item.children?.append(contentsOf: f)
            }
        }
        //outlineViewDirectory.reloadItem(object)
        // 只在选中时刷新文件表格，仅仅只是展开三角不需要刷新
        if reloadFile {
            tableViewFile.reloadData()
        }
    }
    
    // MARK: - Click
    
    @IBAction func folderDoubleClick(_ sender: NSOutlineView) {
    }
    
    @IBAction func fileDoubleClick(_ sender: NSTableView) {
        let index = tableViewFile.selectedRow
        openUrl(index, isDirectory: false)
    }
    
    @IBAction func clickRefresh(_ sender: Any) {
        runtimes?.removeAll()
        
        loadDeviceSet()
        
        outlineViewDirectory.reloadData()
        tableViewFile.reloadData()
    }
    
    @IBAction func clickOpenFile(_ sender: Any) {
        let index = tableViewFile.clickedRow
        openUrl(index, isDirectory: false)
    }
    
    @IBAction func clickOpenFolder(_ sender: Any) {
        let index = tableViewFile.clickedRow
        openUrl(index, isDirectory: true)
    }
    
    @IBAction func clickSearchId(_ sender: Any) {
        let id = textFieldSearchId.stringValue
        if id.count == 0 {
            clickRefresh(AnyObject.self)
        }
        guard let runtimes = runtimes else { return }
        for r in runtimes {
            for d in r.deviceInfo {
                for a in d.application {
                    if a.identifier.contains(id) {
                        // 注意展开顺序，否则会出现与预想不一致的情形
                        outlineViewDirectory.expandItem(r)
                        outlineViewDirectory.expandItem(d)
                        //outlineViewDirectory.expandItem(a)
                    }
                }
            }
        }
    }
    
    @IBAction func clickFilterId(_ sender: Any) {
        UserDefaults.standard.setValue(textFieldSearchId.stringValue, forKey: kFilterId)
        UserDefaults.standard.synchronize()
        
        runtimes?.removeAll()
        
        loadDeviceSet(textFieldSearchId.stringValue)
        
        outlineViewDirectory.reloadData()
        tableViewFile.reloadData()
    }
}

extension MainViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return runtimes?.count ?? 0
        }
        if let info = item as? RuntimeInfo {
            return info.deviceInfo.count
        }
        if let info = item as? DeviceInfo {
            return info.application.count
        }
        if let info = item as? ApplicationInfo {
            return info.files.count
        }
        if let info = item as? DirectoryTreeModel {
            return info.children?.count ?? 0
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return runtimes?.safeObject(index: index) ?? RuntimeInfo()
        }
        if let info = item as? RuntimeInfo {
            return info.deviceInfo.safeObject(index: index) ?? DeviceInfo()
        }
        if let info = item as? DeviceInfo {
            return info.application.safeObject(index: index) ?? ApplicationInfo()
        }
        if let info = item as? ApplicationInfo {
            return info.files.safeObject(index: index) ?? DirectoryTreeModel()
        }
        if let info = item as? DirectoryTreeModel {
            return info.children?.safeObject(index: index) ?? DirectoryTreeModel()
        }
        return RuntimeInfo()
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        var value = ""
        if tableColumn == outlineView.tableColumns.safeObject(index: 0) {
            if let info = item as? RuntimeInfo {
                value = info.iOS
            }
            if let info = item as? DeviceInfo {
                value = info.deviceName
            }
            if let info = item as? ApplicationInfo {
                value = info.identifier
            }
            if let info = item as? DirectoryTreeModel {
                value = info.name
            }
        }
        if tableColumn == outlineView.tableColumns.safeObject(index: 1) {
            if let info = item as? DeviceInfo {
                value = info.udid
            }
        }
        
        return value
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("DirectoryTreeFolderTableCellView")
        var view = outlineView.makeView(withIdentifier: identifier, owner: self) as? DirectoryTreeFolderTableCellView
        if view == nil {
            view = DirectoryTreeFolderTableCellView()
        }
        
        return view
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let info = item as? RuntimeInfo {
            return info.deviceInfo.count > 0
        }
        if let info = item as? DeviceInfo {
            return info.application.count > 0
        }
        if let info = item as? ApplicationInfo {
            return true
        }
        if let info = item as? DirectoryTreeModel {
            return info.isDirectory
        }
        return false
    }
    
    func outlineViewItemWillExpand(_ notification: Notification) {
        /*
        let view = notification.object as? NSOutlineView
        if let row = view?.selectedRow { // clickedRow
            let item = view?.item(atRow: row) as? DirectoryTreeModel
            if let path = item?.fullPath {
                SearchSimulatorFile(URL(fileURLWithPath: path), parent: item)
                files = sortedFile(item?.children)
                tableViewFile.reloadData()
            }
        }
        */
        
        let info = notification.userInfo
        
        searchChildren(info?["NSObject"], reloadFile: false)
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 32
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let view = notification.object as? NSOutlineView
        /*
        let columns = view?.selectedColumnIndexes // ?
        let column = view?.selectedColumn ?? 0
        let rows = view?.selectedRowIndexes // ?
        let row = view?.selectedRow ?? -1
        let model = view?.item(atRow: row)
        */
        
        if let row = view?.selectedRow,
           let item = view?.item(atRow: row) {
            searchChildren(item, reloadFile: true)
        }
    }
}

extension MainViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return files?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier = ""
        if tableColumn == tableView.tableColumns.safeObject(index: 0) {
            cellIdentifier = "DirectoryTreeFileNameTableCellView"
        }
        if tableColumn == tableView.tableColumns.safeObject(index: 1) {
            cellIdentifier = "DirectoryTreeFileDateTableCellView"
        }
        if tableColumn == tableView.tableColumns.safeObject(index: 2) {
            cellIdentifier = "DirectoryTreeFileSizeTableCellView"
        }
        let identifier = NSUserInterfaceItemIdentifier(cellIdentifier)
        
        let cell = tableView.makeView(withIdentifier: identifier, owner: nil)
        return cell
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        // 如果不允许同时多个key排序，则只取第一个
        sortDescriptor = tableView.sortDescriptors.first
        
        files = sortedFile(files)
        tableViewFile.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        //
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return files?.safeObject(index: row)
    }
}

extension MainViewController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let index = tableViewFile.clickedRow
        menuItemOpenFile.isEnabled = index >= 0
        menuItemOpenFolder.isEnabled = index >= 0
    } 
}

extension MainViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            if let _ = control as? NSTextField {
//                clickSearchId(AnyObject.self)
                clickFilterId(AnyObject.self)
            }
        default: return false
        }
        return true
    }
}

extension Array {
    subscript (safeObject index: Int) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
    
    func safeObject(index: Int) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
}
