//
//  AppDelegate.swift
//  SearchSimulatorFile
//
//  Created by LiYing on 2024/5/4.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        NSApplication.shared.mainWindow?.setFrameAutosaveName("Main")
        #if !DEBUG
        NSApplication.shared.mainWindow?.center()
        #endif
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

