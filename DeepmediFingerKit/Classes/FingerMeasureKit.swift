

import UIKit
import CoreMotion
import RxSwift
import RxCocoa
import Then

open class FingerMeasurement: NSObject {
    private let bag = DisposeBag()
    
    private let document = Document(),
                notiGenerator = UINotificationFeedbackGenerator()
    
    private let cameraSetup = CameraSetup()
    private let measurementModel = MeasurementModel()
    
    private let model = Model.shared
    private let dataModel = DataModel.shared
    private let device = UIDevice.current
    
    // MARK: property
    private var tapCount = [MeasurementModel.status](),
                noTapCount = [MeasurementModel.status](),
                stopMeasureCount = [MeasurementModel.status](),
                backMeasureCount = [MeasurementModel.status](),
                FRAMES_PER_SECOND: Double = 60,
                rgbMeasurementTime = Double(),
                measurementTimer = Timer(),
                noTapTimer = Timer(),
                motionManager = CMMotionManager(),
    
    // MARK: isTapCheck
    private var filterG = [Float]()
    private let limitTapCount = 60
    
    // MARK: Flag
    private var isDeviceBack = Bool(),
                isTap = Bool(),
                isTorch = true,
                isComplete = false

    public override init() {
        super.init()
        UIApplication.shared.isIdleTimerDisabled = true
        self.measurementModel.bindFingerTap()
        self.rgbMeasurementTime = self.model.measurementTime
        if let openCVstr = OpenCVWrapper.openCVVersionString() {
            print("\(openCVstr)")
        }
    }
    
    deinit {
        print("deinit")
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
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
    
    public func measuredValue(
        _ value: @escaping (Double)->()
    ) {
        let value = self.measurementModel.inputFilteringGvalue
        value
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { filted in
                value(filted)
            })
            .disposed(by: bag)
    }
    
    private func setTorch(camSetup: CameraSetup, torch: Bool) {
        guard camSetup.hasTorch() else { return print("has not torch") }
        switch torch {
        case true:
            camSetup.useCaptureDevice()?.torchMode = .on
        case false:
            camSetup.useCaptureDevice()?.torchMode = .off
        }
    }
    
    /// Accelemeter start
    private func accTimerAndCollectAccelemeterData() {
        self.motionManager.accelerometerUpdateInterval = 1 / 100
        self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (acc, err)  in
            let z = accelemeterData(acc, err)
            if z > 0.0 {
                self.measurementModel.inputAccZback.onNext(true)
                self.measurementModel.inputAccZforward.onNext(false)
            } else {
                self.measurementModel.inputAccZback.onNext(false)
                self.measurementModel.inputAccZforward.onNext(true)
            }
        }
        
        func accelemeterData(
            _ acc: CMAccelerometerData?,
            _ err: Error?
        ) -> Float {
            
            if err != nil {
                self.z = 0.1
            } else {
                guard let accMeasureData = acc?.acceleration else { fatalError("acc measure data error") }
                self.z = Float(accMeasureData.z)
            }
            return self.z
        }
    }
    
    
    private func measurementRGBfromFinger() {
        self.measurementModel
            .outputFingerStatus
            .observe(on: MainScheduler.instance)
            .asDriver(onErrorJustReturn: .noTap)
            .drive(onNext: { status in
                
                if status == .tap && self.tapCount.count <= self.limitTapCount * 12 {
                    
                    if self.tapCount.count == 30 {
                        self.cameraSetup.setUpCatureDevice()
                        self.isTap = true
                    }
                    
                    self.tapCount.append(.tap)
                    self.noTapCount.removeAll()
                    self.stopMeasureCount.removeAll()
                    
                } else if (status == .noTap) {
                    
                    self.noTapCount.append(.noTap)
                    
                } else if (status == .back) || (status == .flip) {
                    
                    self.stopMeasureCount.append(status)
                    self.tapCount.removeAll()
                }
                
                switch status {
                case .tap:
                    defer {
                        if self.tapCount.count == self.limitTapCount * self.model.limitTapTime {
                            self.startTimerAndMakeDocuForAPIcommunication()
                        }
                    }
                    if self.tapCount.count < self.limitTapCount / 2 && self.isComplete {
                        self.setTorch(camSetup: self.cameraSetup, torch: true)
                    }
                case .noTap:
                    if (self.tapCount.count >= 120), (self.noTapCount.count == (self.limitTapCount * 2)) {
                        self.stopMeasurement(error)
                    }
                case .back, .flip:
                    if self.stopMeasureCount.count == 40 {
                        self.stopMeasurement(error)
                    }
                }
            })
            .disposed(by: self.bag)
    }
    
    private func startTimerAndMakeDocuForAPIcommunication() {
        self.dataModel.initRGBData()
        self.isComplete = true
        self.measurementTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.willStartAfterFinshMeasurement(timer: timer)
        }
    }
    
    private func willStartAfterFinshMeasurement(timer: Timer) {
        
        self.rgbMeasurementTime -= 0.1
        self.measurementModel.secondRemaining.onNext(self.rgbMeasurementTime)
        
        if self.rgbMeasurementTime <= 0.0 {
            self.document.madeMeasureData()
            if self.dataModel.rgbDataPath != nil {
                timer.invalidate()
                self.notiGenerator.notificationOccurred(.success)
                self.tapCount.removeAll()
                self.noTapCount.removeAll()
                self.stopMeasureCount.removeAll()
                self.backMeasureCount.removeAll()
                completion()
            }
        }
    }
    
    /// Camera stop시 초기화 되는 요소들
    private func stopElements() {
        self.isComplete = false
        self.measurementTimer.invalidate()
        self.dataModel.gTempData.removeAll()
        self.rgbMeasurementTime = self.model.measurementTime
    }
    
    /// 측정 중 멈춤 후 재시작
    private func stopMeasurement(_ error: (()->())?) {
        self.tapCount.removeAll()
        self.noTapCount.removeAll()
        self.stopMeasureCount.removeAll()
        error?()
    }
}
// MARK: AVCapture Delegate ----------------------------------------------------------------
extension FingerMeasurement: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvimgRef: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { fatalError("cvimg ref") }
        let hasTorch = self.cameraSetup.hasTorch()
        
        CVPixelBufferLockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))
        // MARK: RGB data
        guard let openCVDatas = OpenCVWrapper.preccessbuffer(sampleBuffer, hasTorch: hasTorch, device: UIDevice.current.modelName) else { return print("objc casting error") }
        guard let tap = openCVDatas[0] as? Bool else { return print("objc bool casting error") }
        guard let r = openCVDatas[1] as? Float,
              let g = openCVDatas[2] as? Float,
              let b = openCVDatas[3] as? Float else { return print("objc rgb casting error") }
        
        self.measurementViewModel.inputFingerTap.onNext(tap)
        self.dataModel.collectRGB(r: r, g: g, b: b)
        self.percentage = (Double(self.dataModel.gData.count) / (self.FRAMES_PER_SECOND * Double(self.model.measurementTime)))
        if self.isComplete {
            self.measurementViewModel.inputPercentage.onNext(self.percentage)
        }
        
        CVPixelBufferUnlockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    private func chartUpdateTimer() -> Timer {
        return Timer.scheduledTimer(timeInterval: 1 / self.FRAMES_PER_SECOND,
                                    target: self,
                                    selector: #selector(self.updatedChartData),
                                    userInfo: nil,
                                    repeats: true)
    }
    
    @objc private func updatedChartData() {
        self.measurementViewModel.inputFilteringGvalue.onNext(self.filter(g: self.dataModel.gTempData))
    }
    
    private func filter(g: [Float]) -> Double {
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
