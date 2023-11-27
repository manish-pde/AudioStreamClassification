//
//  ContentViewModel.swift
//  AudioStreamClassification
//
//  Created by Manish on 22/11/23.
//

import Foundation
import AVFoundation
import SoundAnalysis


class ContentViewModel: NSObject, ObservableObject {
    
    @Published private(set) var hasMicAccess = false
    @Published private(set) var result = ""
    
    @Published private(set) var isRunning = false
    
    private var audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    
}

extension ContentViewModel {
 
    func startAnalysis() {
        startListining()
        
        let busIndex = AVAudioNodeBus(0)
        let bufferSize = AVAudioFrameCount(4096)
        let audioFormat = audioEngine.inputNode.outputFormat(forBus: busIndex)

        let request = try! SNClassifySoundRequest(classifierIdentifier: .version1)
        request.windowDuration = CMTimeMakeWithSeconds(1.5, preferredTimescale: 48_000)
        request.overlapFactor = 0.9
        
        analyzer = SNAudioStreamAnalyzer(format: audioFormat)
        try! analyzer?.add(request, withObserver: self)
        
        audioEngine
            .inputNode
            .installTap(
                onBus: busIndex,
                bufferSize: bufferSize,
                format: audioFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                    //self.analysisQueue.async {
                    self.analyzer?.analyze(buffer, atAudioFramePosition: when.sampleTime)
                    //}
                }
        
        try! audioEngine.start()
    }
    
    func startListining() {
        stopListining()
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            stopListining()
            assertionFailure()
        }
        
        isRunning = true
    }
    
    func stopListining() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        analyzer?.removeAllRequests()
        analyzer = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)
        
        isRunning = false
    }
    
    func checkAndSetupPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { success in
                DispatchQueue.main.async {
                    self.hasMicAccess = success
                }
            })
        case .authorized:
            hasMicAccess = true
        default:
            hasMicAccess = false
        }
    }
    
}

extension ContentViewModel: SNResultsObserving {
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        
        guard let result = result as? SNClassificationResult else  { return }
        
        guard let classification = result.classifications.first else { return }
        
        DispatchQueue.main.async {
            self.result = classification.identifier
        }
    }
    
}
