//
//  CameraObject.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import Foundation
import AVKit

public class CameraObject: NSObject {
    let cameraSetup = CameraSetup()
    
    public func initalized(session: AVCaptureSession, captureDevice: AVCaptureDevice?) {
        self.cameraSetup.initModel(session: session, captureDevice: captureDevice)
    }
    
    public func setup(
        delegate object: AVCaptureVideoDataOutputSampleBufferDelegate
    ) {
        self.cameraSetup.startDetection()
        self.cameraSetup.setupCameraFormat(60.0)
        self.cameraSetup.setupVideoOutput(object)
    }
    
    public func previewLayer() -> AVCaptureVideoPreviewLayer {
        return self.cameraSetup.usePreViewLayer()
    }
    
    func AELock() {
        self.cameraSetup.setUpCatureDevice()
    }
}
