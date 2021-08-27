//
//  ImportFromFileView.swift
//  ImportFromFileView
//
//  Created by Javier de Martín Gil on 28/8/21.
//

import SwiftUI
import ShazamKit
import SHCoachFramework

struct ImportFromFileView: View {
    
    @EnvironmentObject var settings: Settings
    
    @EnvironmentObject var creator: SHCatalogCreator
    
    @State var fileImportedPresented: Bool = false
    
    @State var presentFileMover: Bool = false
    
    var body: some View {
        
        List {
            
            Section(header: Text("Loaded \(creator.customSignatures.count) files"), footer: Text("Supports: \(settings.supportedAudioInputFiles.compactMap({ $0.localizedDescription }).joined(separator: ", ")).\n\nImport audio files to create a custom `SHCustomCatalog` and then export the file that can be tested on an iOS app.")) {
                
                if creator.customSignatures.isEmpty {
                    Text("Empty")
                } else {
                    ForEach(creator.customSignatures, id: \.self) { u in
                        Text(u.mediaItem.title ?? "Missing title")
                        
                    }
                }
            }
        }
        .fileMover(isPresented: $presentFileMover, file: settings.shazamModelURL, onCompletion: { result in
            switch result {
                
            case .success(let exportedUrl):
                
                settings.shazamModelURL = exportedUrl
                
                print("Saved to \(exportedUrl)")
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
            }
        })
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                
                Button(action: {
                    fileImportedPresented.toggle()
                }, label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                })
                
                Button(action: {

                    guard let catalog = creator.createCustomCatalog() else { fatalError() }


                    guard let url = try? creator.export(catalog) else { return }

                    settings.shazamModelURL = url

                    presentFileMover.toggle()
                }, label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                })
                    .disabled(creator.customSignatures.isEmpty || settings.shazamModelURL == nil)
            }
        }
        .fileImporter(isPresented: $fileImportedPresented, allowedContentTypes: settings.supportedAudioInputFiles, allowsMultipleSelection: true, onCompletion: { result in
            
            switch result {
                
            case .success(let importedFilesURLs):
                
                guard !importedFilesURLs.isEmpty else { return }
                
                for signature in importedFilesURLs {
                    guard let customSignature = creator.generateSignature(from: signature) else { continue }
                    
                    // More properties can be added and be extended by any user that uses this framework
                    creator.customSignatures.append(SHCoachCustomSignatureModel(signature: customSignature, mediaItemProperties: [.title: signature.fileNameWithoutExtension]))
                }
                
            case .failure(let error):
                dump(error)
            }
        })
        .navigationTitle("Import from file")
    }
}
