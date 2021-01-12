//
//  ViewController.swift
//  ASLTranslator
//
//  Created by Roman Auersvald on 30/10/2020.
//

import UIKit
import Vision
import AVFoundation

enum TranslatedCommand:String{
    case del
    case nothing
    case space
    case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
}

class ViewController: UIViewController {

    @IBOutlet weak var imgRecognizedSign: UIImageView!
    @IBOutlet weak var txtviewTranslated: UITextView!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var btnStartStop: UIButton!
    @IBOutlet weak var btnSettings: UIButton!
    
    // Camera properties
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice!
    var devicePosition: AVCaptureDevice.Position = .back
    
    // Vision properties
    var requests = [VNRequest]()
    
    let defaultBufferSize = 3
    var bufferSize = 5
    var commandBuffer = [TranslatedCommand]()
    var currentCommand:TranslatedCommand = .nothing{
        didSet {
            commandBuffer.append(currentCommand)
            if commandBuffer.count == bufferSize{
                if commandBuffer.filter({$0 == currentCommand}).count == bufferSize{
                    showAndSendCommand(currentCommand)
                }
                commandBuffer.removeAll()
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.prepareCamera()
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.prepareCamera()
                    }
                }
            
            case .denied: // The user has previously denied access.
                return

            case .restricted: // The user can't grant access due to restrictions.
                return
        @unknown default:
            fatalError()
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVision()
        resetViews()
    }
    
    
    
    func setupVision(){
        guard let visionModel = try? VNCoreMLModel(for: ASLClassifier_1(configuration: .init()).model) else {return}
        
        let classificationRequest: VNCoreMLRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleClassification)
        
        classificationRequest.imageCropAndScaleOption = .centerCrop
        
        self.requests = [classificationRequest]
    }
    
    func handleClassification(request: VNRequest, error: Error?){
        guard let observations = request.results else {print("no results");return}
        
        let classifications = observations
            .compactMap({$0 as? VNClassificationObservation})
            .filter({$0.confidence > 0.9})
            .map({$0.identifier})
        
        print(classifications)
        
        switch classifications.first{
        case "nothing":
            currentCommand = .nothing
        case "del":
            currentCommand = .del
        case "space":
            currentCommand = .space
        default:
            if classifications.first != nil{
                currentCommand = TranslatedCommand(rawValue: classifications.first!) ?? .nothing
            }else{
                currentCommand = .nothing
            }
        }
    }

    func resetViews(){
        DispatchQueue.main.async {
        self.lblStatus.text = ""
        self.btnStartStop.setTitle("Start", for: .normal)
        self.txtviewTranslated.text = ""
        self.imgRecognizedSign.image = nil
        }
    }
    
    
    @IBAction func resetUI(_ sender: Any) {
            self.resetViews()
    }
    
    @IBAction func toggleTranslation(_ sender: Any) {
        if captureSession.isRunning {
            captureSession.stopRunning()
            DispatchQueue.main.async {
                self.lblStatus.text = "Zastaveno..."
                self.btnStartStop.setTitle("Start", for: .normal)
            }
        }else{
            captureSession.startRunning()
            DispatchQueue.main.async {
                self.lblStatus.text = "Čekám na znak..."
                self.btnStartStop.setTitle("Stop", for: .normal)
            }
        }
    }
    
    func showAndSendCommand(_ command:TranslatedCommand){
        DispatchQueue.main.async {
            if command == .space{
                self.txtviewTranslated.text.append(" ")
                self.imgRecognizedSign.image = nil
            }else if command == .nothing{
                
            }else if command == .del{
                self.txtviewTranslated.text.removeLast()
                self.imgRecognizedSign.image = nil
            }else{
                self.txtviewTranslated.text.append(command.rawValue)
                self.imgRecognizedSign.image = UIImage(named: command.rawValue)
            }
        }

    }
    
}

