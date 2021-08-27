//
//  RecorderView.swift
//  RecorderView
//
//  Created by Javier de Martín Gil on 27/8/21.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreServices
import AVFoundation

struct RecorderView: View {

    @EnvironmentObject var settings: Settings
    
    var body: some View {
        NavigationView {
            
            List {
                
                Text("Create a `SHCustomCatalog` from either recordings from your microphone or from audio files. You can mix both and create a custom catalog from both imported audio files and recordings.")
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(.secondary)
                
                Section(header: Text("Import files")) {
                    NavigationLink(destination: {
                        ImportFromFileView()
                    }, label: {
                        Label("Add audio from file", systemImage: "folder.fill")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.primary)
                    })
                }

                #if !targetEnvironment(macCatalyst) && !os(macOS)
                // Check if app is running on MacOS as "Designed for iPad" and has
                // audio inputs available
                if let inputs = AVAudioSession.sharedInstance().inputDataSources, inputs.isEmpty == false {
                Section(header: Text("Record audio from your microphone")) {
                    NavigationLink(destination: {
                        ImportFromRecordView()
                    }, label: {
                        Label("Add audio from microphone", systemImage: "music.mic")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.primary)
                    })
                }
                }
                #endif
            }
            .navigationTitle(Text("Recorder"))
        }
    }
}
