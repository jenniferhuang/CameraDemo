//
//  CameraController.swift
//  AV Foundation
//
//  Created by Jennifer Huang on 2020/7/1.
//  Copyright © 2020 Pranjal Satija. All rights reserved.
//

import AVFoundation
import UIKit

class CameraController{
    var captureSession:AVCaptureSession?
    var frontCamera:AVCaptureDevice?
    var rearCamera:AVCaptureDevice?
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
}
  
extension CameraController{
    
        @available(iOS 11.1, *)
        func prepare(completionHandler:@escaping(Error?)->Void){
            func createCaptureSession(){
                self.captureSession=AVCaptureSession()
            }
            func configureCaptureDevices() throws{
                let cameras = AVCaptureDevice.DiscoverySession(deviceTypes:
                [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
                    mediaType: .video, position: .unspecified).devices
                        
                for camera in cameras{
                    if camera.position==AVCaptureDevice.Position.front{
                        self.frontCamera = camera
                    }
                    if camera.position==AVCaptureDevice.Position.back{
                        self.rearCamera = camera
                        try camera.lockForConfiguration()
                        camera.focusMode = .continuousAutoFocus
                       
                    }
                }
                
            }
            func configureDeviceInputs() throws{
                guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
                
                if let rearCamer = self.rearCamera{
                    self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamer)
                    if captureSession.canAddInput((self.rearCameraInput!)){
                        captureSession.addInput(self.rearCameraInput!)
                    }
                    self.currentCameraPosition = .rear
                }
                else if let frontCamera = self.frontCamera{
                    self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                    if captureSession.canAddInput((self.frontCameraInput!)){
                        captureSession.addInput(self.frontCameraInput!)
                    }
                    else { throw CameraControllerError.inputsAreInvalid}
                    self.currentCameraPosition = .front
                }
                else{throw CameraControllerError.noCamerasAvailable}
                
            }
            func configurePhotoOutput() throws{
                guard let captureSession = self.captureSession else {throw CameraControllerError.captureSessionIsMissing}
                self.photoOutput = AVCapturePhotoOutput()
                self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
                if captureSession.canAddOutput(self.photoOutput!){
                    captureSession.addOutput(self.photoOutput!)
                    captureSession.startRunning()
                }
                
            }
            
            DispatchQueue(label:"prepare").async {
                do{
                    createCaptureSession()
                    try configureCaptureDevices()
                    try configureDeviceInputs()
                    try configurePhotoOutput()
                }
                
                catch{
                    DispatchQueue.main.async {
                        completionHandler(error)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            }
        }
    func displayPreview(on view: UIView) throws{
        guard let captureSession = self.captureSession, captureSession.isRunning else {throw CameraControllerError.captureSessionIsMissing}
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
        
}

extension CameraController{
    public enum CameraPosition {
         case front
         case rear
     }
     enum CameraControllerError: Swift.Error {
             case captureSessionAlreadyRunning
             case captureSessionIsMissing
             case inputsAreInvalid
             case invalidOperation
             case noCamerasAvailable
             case unknown
         }
}

