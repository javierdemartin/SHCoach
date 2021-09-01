//
//  ImportFromRecordView.swift
//  ImportFromRecordView
//
//  Created by Javier de Martín Gil on 28/8/21.
//

import SwiftUI

#if !os(macOS) || !targetEnvironment(macCatalyst)
struct ImportFromRecordView: View {
    
    /// 
    @EnvironmentObject var creator: SHCatalogCreator
    
    @State var isRecording: Bool = false
    
    @State var capturedCustomSignatures: [SHCoachCustomSignatureModel] = []
    
    @State var presentFileMover: Bool = false
    
    @EnvironmentObject var settings: Settings
    
    @State var recordName: String = UUID().uuidString
    
    var body: some View {
        
        List {
            Section(footer: Text("You can change filename generated above by any name you like")) {
                
                TextField("Name", text: $recordName)
                    .foregroundColor(isRecording ? .gray : .primary)
                    .disabled(isRecording)
                
                Button(action: {
                    
                    if isRecording {
                        creator.stopListeningFromMicrophone()
                        creator.createRecordFromRecordedSignature(with: [.title: recordName])
                        
                        recordName = UUID().uuidString
                    } else {
                        do {
                            try creator.startListeningFromMicrophone()
                        } catch {
                            dump(error.localizedDescription)
                        }
                    }
                    
                    isRecording.toggle()
                },
                       label: {
                    Label("Record", systemImage: "waveform")
                        .foregroundColor(.red)
                })
                
            }
            
            Section(header: Text("Your records")) {
                
                if creator.customSignatures.isEmpty {
                    Text("No records")
                } else {
                    ForEach(creator.customSignatures) { r in
                        Text(r.mediaItem.title ?? "Missing title")
                    }
                }
            }
        }
        .fileMover(isPresented: $presentFileMover, file: settings.shazamCatalogUrl, onCompletion: { result in
            switch result {
                
            case .success(let exportedUrl):
                
                settings.shazamCatalogUrl = exportedUrl
                
                NSLog("Saved custom model to \(exportedUrl)")
            case .failure(let error):
                NSLog("ERROR: \(error.localizedDescription)")
            }
        })
        .navigationTitle(Text("Microphone"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                
                Button(action: {
                    
                    guard let catalog = creator.createCustomCatalog() else { return }
                    
                    guard let url = try? creator.export(catalog) else { return }
                    
                    settings.shazamCatalogUrl = url
                    
                    presentFileMover.toggle()
                    
                }, label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                })
                    .disabled(creator.customSignatures.isEmpty)
            }
        }
    }
}
#endif
