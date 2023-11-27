//
//  ContentView.swift
//  AudioStreamClassification
//
//  Created by Manish on 22/11/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewmodel = ContentViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if viewmodel.isRunning {
                Text("Listining...")
            }
            
            if viewmodel.isRunning {
                Text(viewmodel.result)
            }
            
            if viewmodel.isRunning {
                Button {
                    viewmodel.stopListining()
                } label: {
                    Text("Stop Listining")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    viewmodel.startAnalysis()
                } label: {
                    Text("Start Listining")
                }
                .buttonStyle(.borderedProminent)
            }

        }
        .padding()
        .onAppear {
            viewmodel.checkAndSetupPermission()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
