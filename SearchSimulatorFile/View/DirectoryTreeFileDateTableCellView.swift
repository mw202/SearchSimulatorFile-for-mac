//
//  DirectoryTreeFileDateTableCellView.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/6.
//

import Cocoa

class DirectoryTreeFileDateTableCellView: NSTableCellView {

    @IBOutlet weak var labelCreateDate: NSTextField!
    
    override var objectValue: Any? {
        didSet {
            if let value = objectValue as? DirectoryTreeModel {
                var dateStr = "Unknown"
                if let d = value.createDate {
                    let fd = DateFormatter()
                    fd.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    dateStr = fd.string(from: d)
                }
                labelCreateDate.stringValue = dateStr
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
