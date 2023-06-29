

import UIKit
import CoreMotion
import AVKit
import RxSwift
import RxCocoa
import Then

open class FingerMeasurementKit: NSObject {
    public enum StopStatus: String {
        case noTap, flipDevice, notThing
    }
    
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
    private var isDeviceBack = false,
                isTorch = true,
                isComplete = Bool()
    
    public func timesLeft(
        _ time: @escaping (Int)->()
    ) {
        let secondRemaining = self.measurementModel.secondRemaining
        secondRemaining
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { count in
                time(count)
            })
            .disposed(by: bag)
    }
    
    public func measurementCompleteRatio(
        _ com: @escaping((String) -> ())
    ) {
        let ratio = self.measurementModel.measurementCompleteRatio
        ratio
            .asDriver(onErrorJustReturn: "0%")
            .asDriver()
            .drive(onNext: { ratio in
                com(ratio)
            })
            .disposed(by: self.bag)
    }
    ///success: Bool, rgb: URL?, acc: URL?, gyro: URL?
    public func finishedMeasurement(
        _ isSuccess: @escaping((_ success: Bool,_ rgbPath: URL?,_ accPath: URL?,_ gyroPath: URL?) -> ())
    ) {
        let completion = self.measurementModel.measurementComplete
        completion
            .asDriver(onErrorJustReturn: (false, URL(string: ""), URL(string: ""), URL(string: "")))
            .drive(onNext: { result in
                isSuccess(result.0,
                          result.1,
                          result.2,
                          result.3)
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
    
    public func stoppedStatus() -> StopStatus {
        if self.measurementModel.stoppedByNotTap {
            return FingerMeasurementKit.StopStatus.noTap
        } else if self.measurementModel.stoppedByFlipingDevice {
            return FingerMeasurementKit.StopStatus.flipDevice
        }
        return FingerMeasurementKit.StopStatus.notThing
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
        self.measurementRGBfromFinger()
        self.startMeasurement()
        self.prepareMeasurement()
    }
    
    open func stopSession() {
        self.stopMeasurement(torch: false)
    }
    
    open func startMeasurement() {
        self.isComplete = false
        self.accTimerAndCollectAccelemeterData()
        self.gyroTimerAndCollectGyroscopeData()
    }
    
    private func prepareMeasurement() {
        DispatchQueue.global(qos: .background).async {
            self.measurementTime = self.model.measurementTime
            self.measurementModel.bindFingerTap()
            self.cameraSetup.useSession().startRunning()
            self.turnOnThe(torch: true)
        }
    }
    
    private func stopMeasurement(torch: Bool) {
        self.isComplete = true
        self.cameraSetup.useCaptureDevice().exposureMode = .autoExpose
        self.cameraSetup.useSession().stopRunning()
        self.motionManager.stopAccelerometerUpdates()
        self.motionManager.stopGyroUpdates()
        self.turnOnThe(torch: torch)
        self.elementInitalize()
    }
    
    private func elementInitalize() {
        self.measurementTime = self.model.measurementTime
        self.measurementTimer.invalidate()
        self.chartTimer.invalidate()
        self.dataModel.initRGBData()
        self.dataModel.initAccData()
        self.dataModel.initGyroData()
        self.tapCount.removeAll()
        self.noTapCount.removeAll()
        self.stopMeasureCount.removeAll()
    }
    
    private func turnOnThe(
        torch: Bool
    ) {
        guard self.cameraSetup.hasTorch() else {
            print("has not torch")
            return
        }
        
        switch torch {
        case true:
            self.cameraSetup.useCaptureDevice().torchMode = .on
        case false:
            self.cameraSetup.useCaptureDevice().torchMode = .off
        }
    }
    
    /// Accelemeter start
    private func accTimerAndCollectAccelemeterData() {
        self.motionManager.accelerometerUpdateInterval = 1 / 100
        guard let operationQueue = OperationQueue.current else {
            print("acc operation queue return")
            return
        }
        self.motionManager.startAccelerometerUpdates(to: operationQueue) { (acc, err)  in
            let z = self.dataModel.collectAccelemeterData(acc, err)
            self.measurementModel.inputAccZback.onNext(z > 0.0)
            self.measurementModel.inputAccZforward.onNext(z <= 0.0)
            guard self.isDeviceBack else {
                return
            }
            self.isDeviceBack = z <= 0.0 ? false : true
            self.turnOnThe(torch: !self.isDeviceBack)
        }
    }
    
    /// Gyroscope start
    private func gyroTimerAndCollectGyroscopeData() {
        self.motionManager.gyroUpdateInterval = 1 / 100
        guard let operationQueue = OperationQueue.current else {
            print("gyro operation queue return")
            return
        }
        self.motionManager.startGyroUpdates(to: operationQueue) { (gyro, err)  in
            self.dataModel.collectGyroscopeData(gyro, err)
        }
    }
    
    private func measurementRGBfromFinger() {
        let status = self.measurementModel.outputFingerStatus
        status
            .observe(on: MainScheduler.instance)
            .asDriver(onErrorJustReturn: .noTap)
            .drive(onNext: { [weak self] status in
                guard let self = self else { return }
                
                if status == .tap && (self.tapCount.count <= self.limitTapCount * 3) {
                    
                    self.tapCount.append(.tap)
                    self.noTapCount.removeAll()
                    self.stopMeasureCount.removeAll()
                    
                    guard self.tapCount.count == 30 && !self.isComplete else {
                        return
                    }
                        self.chartUpdateTimer()
                        self.cameraSetup.setUpCatureDevice()
                                        
                } else if (status == .noTap) {

                    self.noTapCount.append(.noTap)
                    self.tapCount.removeAll()
                    self.stopMeasureCount.removeAll()

                } else if (status == .back || status == .flip) {

                    self.stopMeasureCount.append(status)
                    self.tapCount.removeAll()
                    self.noTapCount.removeAll()
                }
                self.measurementModel.checkStopStatus(status)
                switch status {
                case .tap:
                    defer {
                        if self.tapCount.count == (self.limitTapCount * self.model.limitTapTime) {
                            self.startTimer()
                        }
                    }
                    guard (self.tapCount.count < self.limitTapCount / 2) && !self.isComplete else {
                        return
                    }
                    self.measurementModel.measurementStop.onNext(false)

                case .noTap:
                    guard self.tapCount.count >= 180 && (self.noTapCount.count == self.limitTapCount * self.model.limitNoTapTime) else {
//                        print("no tap return")
                        return
                    }
                    self.elementInitalize()
                    self.measurementModel.measurementStop.onNext(true)

                case .back, .flip:
                    guard self.stopMeasureCount.count >= 30 else {
//                        print("back, flip return")
                        return
                    }
                    self.isDeviceBack = true
                    self.turnOnThe(torch: false)
                    self.elementInitalize()
                    self.measurementModel.measurementStop.onNext(true)
                }
            })
            .disposed(by: self.bag)
    }
    
    private func startTimer() {
        let completion = self.measurementModel.measurementComplete,
            secondRemaining = self.measurementModel.secondRemaining,
            measurementCompleteRatio = self.measurementModel.measurementCompleteRatio
        
        self.isComplete = true
        self.dataModel.initRGBData()
        self.dataModel.initAccData()
        self.dataModel.initGyroData()
        
        self.measurementTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { timer in
            let ratio = Int(100.0 - self.measurementTime * 100.0 / self.model.measurementTime)
            measurementCompleteRatio.onNext("\(ratio)%")
            secondRemaining.onNext(Int(self.measurementTime))
            self.measurementTime -= 0.1
            if self.measurementTime <= 0.0 {
                
                self.notiGenerator.notificationOccurred(.success)
                
                if self.model.breathMeasurement {
                    self.document.madeMeasureData(data: .rgb)
                    self.document.madeMeasureData(data: .acc)
                    self.document.madeMeasureData(data: .gyro)
                    
                    if let rgbPath = self.dataModel.rgbDataPath,
                       let accPath = self.dataModel.accDataPath,
                       let gyroPath = self.dataModel.gyroDataPath {
                        completion.onNext((success: true,
                                           rgbURL: rgbPath,
                                           accURL: accPath,
                                           gyroURL: gyroPath))
                    } else {
                        completion.onNext((success: false,
                                           rgbURL: URL(string: "there is not rgb path"),
                                           accURL: URL(string: "there is not acc path"),
                                           gyroURL: URL(string: "there is not gyro path")))
                    }
                    
                } else {
                    
                    self.document.madeMeasureData(data: .rgb)
                    
                    if let rgbPath = self.dataModel.rgbDataPath {
                        completion.onNext((success: true,
                                           rgbURL: rgbPath,
                                           accURL: URL(string: "there is not acc path"),
                                           gyroURL: URL(string: "there is not gyro path")))
                    } else {
                        completion.onNext((success: false,
                                           rgbURL: URL(string: "there is not rgb path"),
                                           accURL: URL(string: "there is not acc path"),
                                           gyroURL: URL(string: "there is not gyro path")))
                    }
                }
                self.stopMeasurement(torch: false)
            }
        }
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
        
        CVPixelBufferLockBaseAddress(
            cvimgRef,
            CVPixelBufferLockFlags(rawValue: 0)
        )
        // MARK: RGB data
        guard let openCVDatas = OpenCVWrapper.preccessbuffer(
            sampleBuffer,
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
        self.dataModel.collectRGB(
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
