//
//  CameraObject.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import Foundation
import AVKit

class CameraSetup: NSObject {
    
    static let manager = CameraSetup()
    
    private var session = AVCaptureSession()
    private var captureDevice: AVCaptureDevice?
    private var customISO: Float?
    private let device = UIDevice.current
    
    func initModel(
        session: AVCaptureSession,
        captureDevice: AVCaptureDevice? = nil
    ) {
        self.session = session
        self.captureDevice = captureDevice
    }
    
    func useCaptureDevice() -> AVCaptureDevice? {
        return self.captureDevice
    }
    
    func useSession() -> AVCaptureSession {
        return self.session
    }
    
    func hasTorch() -> Bool {
        guard let torch = self.captureDevice?.hasTorch else { return false }
        return torch
    }
    
    @available(iOS 10.0, *)
    func startDetection() {
        self.session.sessionPreset = .low
        
        if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            self.captureDevice = captureDevice
            if self.session.inputs.isEmpty {
                guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { fatalError("input error") }
                self.session.addInput(input)
            }
        } else if let captureDevice1 = AVCaptureDevice.default(for: .video) {
            self.captureDevice = captureDevice1
            if self.session.inputs.isEmpty {
                guard let input = try? AVCaptureDeviceInput(device: captureDevice1) else { fatalError("input error") }
                self.session.addInput(input)
            }
        } else { // iOS version 13.0 이하
            guard let captureDevice = AVCaptureDevice.default(for: .video) else { fatalError("capture device error") }
            self.captureDevice = captureDevice
            if self.session.inputs.isEmpty {
                guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { fatalError("input error") }
                self.session.addInput(input)
            }
        }
    }
    
    func setupCameraFormat(
        _ framePerSec: Double
    ) {
        var currentFormat: AVCaptureDevice.Format?,
            tempFramePerSec = Double()
        
        guard let captureDeviceFormats = self.captureDevice?.formats else { fatalError("capture device") }
        
        for format in captureDeviceFormats {
            let ranges = format.videoSupportedFrameRateRanges
            let frameRates = ranges[0]
            let videoFormatDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            
            if (frameRates.maxFrameRate == framePerSec) {
                
                if ((videoFormatDimensions.width <= Int32(700) &&
                     videoFormatDimensions.height <= Int32(500))) {
                    currentFormat = format
                    tempFramePerSec = framePerSec
                }
            } else {
                if ((videoFormatDimensions.width <= Int32(700) &&
                     videoFormatDimensions.height <= Int32(500))) {
                    
                    currentFormat = format
                    tempFramePerSec = 30.0
                }
            }
        }
        
        guard let tempCurrentFormat = currentFormat,
              try! self.captureDevice?.lockForConfiguration() != nil else { return print("current format")}
        
        try! self.captureDevice?.lockForConfiguration()
        self.captureDevice?.activeFormat = tempCurrentFormat
        self.captureDevice?.activeVideoMinFrameDuration = CMTime(
            value: 1,
            timescale: Int32(tempFramePerSec)
        )
        self.captureDevice?.activeVideoMaxFrameDuration = CMTime(
            value: 1,
            timescale: Int32(tempFramePerSec)
        )
        self.captureDevice?.unlockForConfiguration()
        
        if self.captureDevice?.hasTorch ?? false {
            self.correctColor()
        }
    }
    
    func setUpISO() {
        if (captureDevice?.iso ?? 30.0) >= 50 {
            self.customISO = 35
        } else if (captureDevice?.iso ?? 30.0) < 50.0 {
            self.customISO = 40
        }
    }
    
    func setUpCatureDevice() {
        try! self.captureDevice?.lockForConfiguration()
        captureDevice?.exposureMode = .locked
        captureDevice?.unlockForConfiguration()
    }
    
    func correctColor() {
        try! self.captureDevice?.lockForConfiguration()
        let gainset = AVCaptureDevice.WhiteBalanceGains(redGain: 1.0,
                                                        greenGain: 1.0, // 3 -> 1 edit
                                                        blueGain: 1.0)
        self.captureDevice?.setWhiteBalanceModeLocked(with: gainset,
                                                      completionHandler: nil)
        self.captureDevice?.unlockForConfiguration()
    }
    
    func setupVideoOutput(
        _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate
    ) {
        let videoOutput = AVCaptureVideoDataOutput()
        let captureQueue = DispatchQueue(label: "catpureQueue")
        
        videoOutput.setSampleBufferDelegate(delegate, queue: captureQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = false
        
        if self.session.canAddOutput(videoOutput) {
            self.session.addOutput(videoOutput)
        } else {
            print("can not output")
        }
    }
}
