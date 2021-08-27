//
//  ContentView.swift
//  Shared
//
//  Created by Javier de Martín Gil on 27/8/21.
//

import SwiftUI
import AVFoundation

struct ContentView: View {

    /// Shared instance of `SHCatalogCreator` to all of the subviews
    @StateObject var creator = SHCatalogCreator()

    @StateObject var settings = Settings()

    var body: some View {
        TabView {
            RecorderView()
                .tabItem {
                    Image(systemName: "waveform.path")
                    Text("Recorder")
                }
                .tag(1)

            // Only show the tester tab
            // AVAudioSession.sharedInstance().inputDataSources

            #if !targetEnvironment(macCatalyst) && !os(macOS)

            // Check if app is running on MacOS as "Designed for iPad" and has
            // audio inputs available
            if let inputs = AVAudioSession.sharedInstance().inputDataSources, inputs.isEmpty == false {
            TesterView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Player")
                }
                .tag(2)
            }
            #endif
        }
        .environmentObject(settings)
        .environmentObject(creator)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
