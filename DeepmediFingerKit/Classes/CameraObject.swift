//
//  CameraObject.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import Foundation
import AVKit

public class FingerCameraObject: NSObject {
    let cameraSetup = CameraSetup.manager
    
    public func fingerKitInitalized(
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        session: AVCaptureSession,
        captureDevice: AVCaptureDevice?
    ) {
        self.cameraSetup.initModel(
            session: session,
            captureDevice: captureDevice
        )
        self.cameraSetup.setupVideoOutput(delegate)
        self.cameraSetup.startDetection()
        self.cameraSetup.setupCameraFormat(60.0)
    }
}
