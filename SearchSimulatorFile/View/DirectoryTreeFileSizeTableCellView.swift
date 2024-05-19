//
//  DirectoryTreeFileSizeTableCellView.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/6.
//

import Cocoa

class DirectoryTreeFileSizeTableCellView: NSTableCellView {

    @IBOutlet weak var labelSize: NSTextField!
    
    override var objectValue: Any? {
        didSet {
            if let value = objectValue as? DirectoryTreeModel {
                labelSize.stringValue = value.size?.convertToFileSize() ?? "--"
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

extension SignedInteger {
    func convertToFileSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}
