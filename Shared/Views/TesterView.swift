//
//  TesterView.swift
//  TesterView
//
//  Created by Javier de Martín Gil on 27/8/21.
//

// Not available on macOS or Catalyst to simplify use cases around
// sampling frecuencies of input devices. Testing's only available on iOS
// devices but a custom catalog can be created from any platform

#if !targetEnvironment(macCatalyst) && !os(macOS)
import SwiftUI
import UniformTypeIdentifiers
import ShazamKit

struct TesterView: View {
    
    @StateObject var identifier = SHCatalogMatcher()
    
    @EnvironmentObject var settings: Settings
    
    @State var fileImportedPresented: Bool = false
    
    @State var isRecording: Bool = false
    
    var body: some View {
        
        NavigationView {
            
            VStack(alignment: .center) {
          
                GeometryReader { g in
                    Button(action: {
                        guard let url = settings.shazamCatalogUrl else { return }

                        try! identifier.match(from: url)
                    }, label: {
                        Text(identifier.state.rawValue)
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .padding()
                            .frame(minWidth: g.size.width * 0.8)
                    })

                        .controlSize(.large)
                        .buttonStyle(.bordered)
                        .headerProminence(.increased)
                        .tint(.red)
                        .padding()
                }

                Text("Load a `.shazamcatalog` file from `Files.app` and test it out!")
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .rounded))
                    .bold()
                
                Spacer()

            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                    Button(action: {
                        fileImportedPresented.toggle()
                    }, label: {
                        Text("Import Catalog")
                    })
                }
            }
            .navigationTitle("Tester")
            .fileImporter(isPresented: $fileImportedPresented, allowedContentTypes: [UTType.shazamCatalog], onCompletion: { result in
                
                switch result {
                    
                case .success(let customCatalogURl):

                    do {
                        try identifier.match(from: customCatalogURl)
                        settings.shazamCatalogUrl = customCatalogURl
                    } catch {
                        NSLog("Error importing custom catalog: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):

                    NSLog(error.localizedDescription)
                }
            })
        }
    }
}
#endif
