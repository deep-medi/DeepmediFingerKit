//
//  ViewController.swift
//  DeepmediFingerKit
//
//  Created by demianjun@gmail.com on 04/03/2023.
//  Copyright (c) 2023 demianjun@gmail.com. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import DeepmediFingerKit

class ViewController: UIViewController {
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    let captureDevice = AVCaptureDevice(uniqueID: "Capture")
    
    let header = Header()
    let camera = CameraObject()
    
    let fingerMeasureKit = FingerMeasurementKit()
    let fingerMeasureKitModel = FingerMeasureKitModel()
    
    let preview = CameraPreview()
    let previousButton = UIButton().then { b in
        b.setTitle("Previous", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .black
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.completionMethod()
        
        self.camera.initalized(
            delegate:fingerMeasureKit,
            session: session,
            captureDevice: captureDevice
        )
        self.fingerMeasureKitModel.setMeasurementTime(30)
        self.fingerMeasureKitModel.doMeasurementBreath(true)
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        
//        DispatchQueue.global(qos: .background).async {
            self.fingerMeasureKit.startSession()
//        }
    }
    
    override func viewDidLayoutSubviews() {
        preview.setup(
            layer: previewLayer,
            frame: preview.bounds,
            useCornerRadius: true
        )
    }
    
    @objc func prev() {
        self.fingerMeasureKit.stopSession()
        self.dismiss(animated: true)
    }
    
    func completionMethod() {
        fingerMeasureKit.measuredValue { value in
            print("value: \(value)")
        }
        
        fingerMeasureKit.measurementCompleteRatio { ratio in
            print("complete ratio: \(ratio)")
        }
        
        fingerMeasureKit.timesLeft { time in
            print("left time: \(time)")
        }
        
        fingerMeasureKit.stopMeasurement { isStop in
            let status = self.fingerMeasureKit.stoppedStatus()
            guard isStop else {
                return
            }
            print("stop status : ",status)
            self.fingerMeasureKit.stopSession()
            if !self.session.isRunning {
                self.fingerMeasureKit.startSession()
            }
//            let alertVC = UIAlertController(
//                title: "Stopped by \(status)",
//                message: "",
//                preferredStyle: .alert
//            )
//            let action = UIAlertAction(
//                title: "ok",
//                style: .default
//            ) { _ in
//                self.fingerMeasureKit.startSession()
//            }
//            alertVC.addAction(action)
//            self.present(alertVC, animated: false)
        }
        
        fingerMeasureKit.finishedMeasurement { success, rgbPath, accPath, gyroPath in
            print("rgbPath:", rgbPath)
            print("accPath:", accPath)
            print("gyroPath:", gyroPath)
            if success {
                let header = self.header.v2Header(method: .post,
                                                  uri: "uri",
                                                  secretKey: "secretKey",
                                                  apiKey: "apiKey")
                print("header", header)
                self.fingerMeasureKit.stopSession()
            } else {
                print("finished measurement error")
            }
            self.dismiss(animated: true)
        }
    }
    
    func setupUI() {
        self.view.addSubview(preview)
        self.view.addSubview(previousButton)
        
        let width = UIScreen.main.bounds.width * 0.8,
            height = UIScreen.main.bounds.height * 0.8
        
        preview.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(width)
        }
        
        previousButton.snp.makeConstraints { make in
            make.width.height.equalTo(width * 0.3)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80)
        }
        
        previousButton.layer.cornerRadius = (width * 0.3) / 2
        previousButton.addTarget(
            self,
            action: #selector(prev),
            for: .touchUpInside
        )
    }
}
