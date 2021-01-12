//
//  ViewController+Camera.swift
//  ASLTranslator
//
//  Created by Roman Auersvald on 30/10/2020.
//

import UIKit
import Vision
import AVFoundation

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func prepareCamera(){
        
//        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices
        
        let availableDevice = AVCaptureDevice.default(.builtInDualWideCamera,
                                                      for: .video, position: .back)
        captureDevice = availableDevice//s.first
        beginSession()
        
        
    }
    
    func beginSession(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        } catch  {
            print("fuckup")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput){
            captureSession.addOutput(dataOutput)
        }
        
        captureSession.commitConfiguration()
        
        let q = DispatchQueue(label: "bufferDel")
        dataOutput.setSampleBufferDelegate(self, queue: q)
        
//        captureSession.startRunning()
    }
    
    // delegate func
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        let exifOrientation = self.exifOrientationFromDeviceOrientation()
        
//        let imageRequestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: exifOrientation, options: [:])
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch  {
            print(error)
        }
        
    }
    
    
    
    func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let currentDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch currentDeviceOrientation{
        case UIDeviceOrientation.portraitUpsideDown:
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:
            exifOrientation = .down
        case UIDeviceOrientation.portrait:
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
