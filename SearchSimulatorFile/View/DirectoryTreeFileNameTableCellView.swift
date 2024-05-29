//
//  DirectoryTreeFileNameTableCellView.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/6.
//

import Cocoa

class DirectoryTreeFileNameTableCellView: NSTableCellView {

    @IBOutlet weak var imageViewIcon: NSImageView!
    @IBOutlet weak var labelName: NSTextField!
    
    override var objectValue: Any? {
        didSet {
            if let value = objectValue as? DirectoryTreeInfo {
                labelName.stringValue = value.name
                imageViewIcon.image = value.icon
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
