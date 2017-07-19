//
//  ViewController.swift
//  GloryDays
//
//  Created by Felipe Hernandez on 13-07-17.
//  Copyright © 2017 kafecode. All rights reserved.
//

import UIKit

import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {
    
    @IBOutlet var infoLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //click del boton pera pedir los permisos
    @IBAction func askFormPermission(_ sender: UIButton) {
        
        self.askForPhotosPermissions()
        
    }
    
    //permisos para el audio
    func askForPhotosPermissions(){
        PHPhotoLibrary.requestAuthorization { [unowned self](authStatus) in
            
            //envia el bloque de completacion al hilo principal
            DispatchQueue.main.async {
                if authStatus == .authorized{
                    self.askForRecordPermissions()
                }else{
                    //si no hay autorización se cambia la etiqueta para indicar información
                    self.infoLabel.text = "No se han proporcionado los permisos necesarios para acceder a tu biblioteca de fotos, puedes configurar los permisos desde los ajustes de tu dispositivo"
                }
            }
            
        }
    }
    
    func askForRecordPermissions(){
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self](allowed) in
            DispatchQueue.main.async {
                if allowed{
                    self.askForTranscriptionPermissions()
                }else{
                    //si no hay autorización se cambia la etiqueta para indicar información
                    self.infoLabel.text = "No se han proporcionado los permisos necesarios para grabar , puedes configurar los permisos desde los ajustes de tu dispositivo"
                }
            }
        }
    }
    
    
    func askForTranscriptionPermissions(){
        
        SFSpeechRecognizer.requestAuthorization {[unowned self] (authStatus) in
            if authStatus == .authorized{
                self.authorizationCompleted()
            }else{
                //si no hay autorización se cambia la etiqueta para indicar información
                self.infoLabel.text = "No se han proporcionado los permisos necesarios para transcripción de texto , puedes configurar los permisos desde los ajustes de tu dispositivo"
            }
            
        }
    }
    
    //logica de completacion de los permisos
    func authorizationCompleted(){
        //oculta el actual viewController
        dismiss(animated: true, completion: nil)
    }
    
    
}

