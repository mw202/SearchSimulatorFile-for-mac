//
//  DirectoryTreeFolderTableCellView.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/6.
//

import Cocoa

class DirectoryTreeFolderTableCellView: NSTableCellView {

    @IBOutlet weak var labelFolderName: NSTextField!
    
    override var objectValue: Any? {
        didSet {
            labelFolderName.stringValue = objectValue as? String ?? ""
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
}
