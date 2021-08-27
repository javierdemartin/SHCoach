//
//  AVFoundationMockable.swift
//  AVFoundationMockable
//
//  Created by Javier de Martín Gil on 31/8/21.
//

/**
 As of now there
 */

import Foundation
import AVFoundation

/// Interface with functions that our app uses for AVAudioEngine that can also be mocked
/// Helps passing default values to isolate testing for specific interfaces
/// As of now there's no way (for me) to create tests that mock audio coming into the microphone
public protocol AVAudioEngineMockable {
    
    var inputNode: AVAudioInputNode { get }
    
    var outputNode: AVAudioOutputNode { get }
    
    var isRunning: Bool { get }
    
    func attach(_ node: AVAudioNode)
    
    func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?)
    
    func reset()
    
    func start() throws
    
    func stop()
    
    init()
}

/// Make all the functions and properties defined in `AVAudioEngineMockable`
/// available to the real `AVAudioEngine`.
extension AVAudioEngine: AVAudioEngineMockable { }

/// Mock class used on tests to prove the functionality of the framework
public final class FakeMicrophone: AVAudioEngineMockable {
    public var inputNode: AVAudioInputNode
    
    public var isRunning: Bool
    
    public var outputNode: AVAudioOutputNode
    
    required public init() {
        inputNode = AVAudioEngine().inputNode
        outputNode = AVAudioEngine().outputNode
        isRunning = false
    }
    
    public func attach(_ node: AVAudioNode) {
        
    }
    
    public func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {
        
    }
    
    public func reset() {
        
    }
    
    public func start() throws {
        isRunning = true
    }
    
    public func stop() {
        isRunning = false
    }
}
