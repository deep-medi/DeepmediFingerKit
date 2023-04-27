

import UIKit
import CoreMotion
import AVKit
import RxSwift
import RxCocoa
import Then

open class FingerMeasurementKit: NSObject {
    private let bag = DisposeBag()
    
    private let document = Document(),
                notiGenerator = UINotificationFeedbackGenerator()
    
    private let cameraSetup = CameraSetup.manager
    
    private let model = Model.shared
    private let dataModel = DataModel.shared
    private let measurementModel = MeasurementModel()
    
    private let device = UIDevice.current
    
    // MARK: property
    private var tapCount = [MeasurementModel.status](),
                noTapCount = [MeasurementModel.status](),
                stopMeasureCount = [MeasurementModel.status]()
    
    private var FRAMES_PER_SECOND: Double = 60,
                measurementTime = Double(),
                measurementTimer = Timer(),
                chartTimer = Timer(),
                motionManager = CMMotionManager()
    
    // MARK: isTapCheck
    private var filterG = [Float]()
    private let limitTapCount = 60
    
    // MARK: Flag
    private var isDeviceBack = Bool(),
                isTap = Bool(),
                isTorch = true,
                isComplete = false

    public func timesLeft(
        _ time: @escaping (Double)->()
    ) {
        let secondRemaining = self.measurementModel.secondRemaining
        secondRemaining
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: 0.0)
            .drive(onNext: { count in
                time(count)
            })
            .disposed(by: bag)
    }
    
    public func measurementCompleteRatio(
        _ com: @escaping((String) -> ())
    ) {
        let ratio = self.measurementModel.measurementRatio
        ratio
            .asDriver(onErrorJustReturn: "0%")
            .asDriver()
            .drive(onNext: { ratio in
                com(ratio)
            })
            .disposed(by: self.bag)
    }
    
    public func finishedMeasurement(
        _ isSuccess: @escaping((Bool, URL?) -> ())
    ) {
        let completion = self.measurementModel.measurementComplete
        completion
            .asDriver(onErrorJustReturn: (false, URL(string: "")))
            .drive(onNext: { result in
                isSuccess(result.0, result.1)
            })
            .disposed(by: bag)
    }
    
    public func stopMeasurement(
        _ isStop: @escaping((Bool) -> ())
    ) {
        let stop = self.measurementModel.measurementStop
        stop
            .asDriver(onErrorJustReturn: false)
            .asDriver()
            .drive(onNext: { stop in
                isStop(stop)
            })
            .disposed(by: bag)
    }
    
    public func measuredValue(
        _ filtered: @escaping (Double)->()
    ) {
        let value = self.measurementModel.inputFilteringGvalue
        value
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { value in
                filtered(value)
            })
            .disposed(by: bag)
    }
    
    public override init() {
        super.init()
        UIApplication.shared.isIdleTimerDisabled = true
        if let openCVstr = OpenCVWrapper.openCVVersionString() {
            print("\(openCVstr)")
        }
    }
    
    deinit {
        print("deinit")
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    open func startSession() {
        DispatchQueue.main.async {
            self.measurementRGBfromFinger()
            self.measurementModel.bindFingerTap()
            self.measurementTime = self.model.measurementTime
            self.cameraSetup.useSession().startRunning()
            self.accTimerAndCollectAccelemeterData()
            self.setTorch(
                camSetup: self.cameraSetup,
                torch: true
            )
        }
    }
    
    open func stopSession() {
        self.motionManager.stopAccelerometerUpdates()
        self.chartTimer.invalidate()
        self.stopMeasurement()
    }
    
    private func setTorch(
        camSetup: CameraSetup,
        torch: Bool
    ) {
        guard camSetup.hasTorch() else {
            print("has not torch")
            return
        }
        switch torch {
        case true:
            cameraSetup.useCaptureDevice()?.torchMode = .on
        case false:
            cameraSetup.useCaptureDevice()?.torchMode = .off
        }
    }
    
    /// Accelemeter start
    private func accTimerAndCollectAccelemeterData() {
        self.motionManager.accelerometerUpdateInterval = 1 / 100
        self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (acc, err)  in
            let z = accelemeterData(acc, err)
            self.measurementModel.inputAccZback.onNext(z > 0.0)
            self.measurementModel.inputAccZforward.onNext(z <= 0.0)
        }
        
        func accelemeterData(
            _ acc: CMAccelerometerData?,
            _ err: Error?
        ) -> Float {
            var z = Float()
            if err != nil {
                z = 0.1
            } else {
                guard let accMeasureData = acc?.acceleration else {
                    fatalError("acc measure data error")
                    
                }
                z = Float(accMeasureData.z)
            }
            return z
        }
    }
    
    private func measurementRGBfromFinger() {
        let status = self.measurementModel.outputFingerStatus
        status
            .debug()
            .observe(on: MainScheduler.instance)
            .asDriver(onErrorJustReturn: .noTap)
            .drive(onNext: { [weak self] status in
                guard let self = self else { return }
                
                if status == .tap && (self.tapCount.count <= self.limitTapCount * 12) {
                    if self.tapCount.count == 30 {
                        self.chartUpdateTimer()
                        self.cameraSetup.setUpCatureDevice()
                        self.isTap = true
                    }
                    self.tapCount.append(.tap)
                    self.noTapCount.removeAll()
                    self.stopMeasureCount.removeAll()
                    
                } else if (status == .noTap) {
                    
                    self.noTapCount.append(.noTap)
                    
                } else if (status == .back || status == .flip) {
                    
                    self.stopMeasureCount.append(status)
                    self.tapCount.removeAll()
                }
                switch status {
                case .tap:
                    defer {
                        if self.tapCount.count == (self.limitTapCount * self.model.limitTapTime) {
                            self.startTimer()
                        }
                    }
                    guard (self.tapCount.count < self.limitTapCount / 2) && self.isComplete else {
                        return
                    }
                    self.measurementModel.measurementStop.onNext(false)
                    self.setTorch(camSetup: self.cameraSetup, torch: true)
                    
                case .noTap:
                    guard self.tapCount.count >= 120 && (self.noTapCount.count == self.limitTapCount * self.model.limitTapTime) else {
                        print("no tap return")
                        return
                    }
                    self.measurementModel.measurementStop.onNext(true)
                    self.stopMeasurement()
                    
                case .back, .flip:
                    guard self.stopMeasureCount.count == 40 else {
                        print("back, flip return")
                        return
                    }
                    self.measurementModel.measurementStop.onNext(true)
                    self.stopMeasurement()
                }
            })
            .disposed(by: self.bag)
    }
    
    private func startTimer() {
        let completion = self.measurementModel.measurementComplete,
            secondRemaining = self.measurementModel.secondRemaining,
            measurementRatio = self.measurementModel.measurementRatio
            
        self.isComplete = true
        
        self.measurementTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { timer in
            self.measurementTime -= 0.1
            secondRemaining.onNext(self.measurementTime)
            measurementRatio.onNext("\(100 - Int(self.measurementTime * 100.0 / self.model.measurementTime))%")
            if self.measurementTime <= 0.0 {
                self.stopMeasurement()
                self.notiGenerator.notificationOccurred(.success)
                self.document.madeMeasureData()
                if let rgbPath = self.dataModel.rgbDataPath {
                    completion.onNext((result: true, url: rgbPath))
                } else {
                    completion.onNext((result: false, url: URL(string: "")))
                }
            }
        }
    }
    /// 측정 중 멈춤 후 재시작
    private func stopMeasurement() {
        self.cameraSetup.useSession().stopRunning()
        self.motionManager.stopAccelerometerUpdates()
        self.measurementTimer.invalidate()
        self.chartTimer.invalidate()
        self.elementInitalize()
    }
    
    /// Camera stop시 초기화 되는 요소들
    private func elementInitalize() {
        self.isComplete = false
        self.dataModel.initRGBData()
        self.tapCount.removeAll()
        self.noTapCount.removeAll()
        self.stopMeasureCount.removeAll()
        self.setTorch(
            camSetup: self.cameraSetup,
            torch: false
        )
    }
}

// MARK: AVCapture Delegate ----------------------------------------------------------------
extension FingerMeasurementKit: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let cvimgRef: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            fatalError("cvimg ref")
            
        }
        let hasTorch = self.cameraSetup.hasTorch()
        
        CVPixelBufferLockBaseAddress(
            cvimgRef,
            CVPixelBufferLockFlags(rawValue: 0)
        )
        // MARK: RGB data
        guard let openCVDatas = OpenCVWrapper.preccessbuffer(
            sampleBuffer,
            hasTorch: hasTorch,
            device: UIDevice.current.modelName
        ) else {
            print("objc casting error")
            return
        }
        guard let tap = openCVDatas[0] as? Bool else { return print("objc bool casting error") }
        guard let r = openCVDatas[1] as? Float,
              let g = openCVDatas[2] as? Float,
              let b = openCVDatas[3] as? Float else { return print("objc rgb casting error") }
    
        self.measurementModel.inputFingerTap.onNext(tap)
        let timeStamp = (Date().timeIntervalSince1970 * 1000000).rounded()
        self.dataModel.collectRGB(
            timeStamp: timeStamp,
            r: r, g: g, b: b
        )
        CVPixelBufferUnlockBaseAddress(
            cvimgRef,
            CVPixelBufferLockFlags(rawValue: 0)
        )
    }
    
    private func chartUpdateTimer() {
        self.chartTimer = Timer.scheduledTimer(
            timeInterval: 1 / self.FRAMES_PER_SECOND,
            target: self,
            selector: #selector(self.updatedChartData),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func updatedChartData() {
        let filteredG = self.filter(g: self.dataModel.gTempData)
        self.measurementModel.inputFilteringGvalue.onNext(filteredG)
    }
    
    private func filter(
        g: [Float]
    ) -> Double {
        let a = [1.0, -7.30103128, 23.42566938, -43.14485924, 49.89209273, -37.09502293, 17.31790014, -4.64159393, 0.54684548]
        let b = [0.00013253, 0.0, -0.00053013, 0.0, 0.0007952, 0.0, -0.00053013, 0.0, 0.00013253]
        
        var x: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        var y: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        var result = Double()
        
        for i in g.indices {
            x.insert(Double(g[i]), at: 0)
            
            result = ((b[0] * x[0])
                      + (b[1] * x[1])
                      + (b[2] * x[2])
                      + (b[3] * x[3])
                      + (b[4] * x[4])
                      + (b[5] * x[5])
                      + (b[6] * x[6])
                      + (b[7] * x[7])
                      + (b[8] * x[8])
                      - (a[1] * y[0])
                      - (a[2] * y[1])
                      - (a[3] * y[2])
                      - (a[4] * y[3])
                      - (a[5] * y[4])
                      - (a[6] * y[5])
                      - (a[7] * y[6])
                      - (a[8] * y[7]))
            
            y.insert(result, at: 0)
            x.removeLast()
            y.removeLast()
        }
        return result
    }
}
