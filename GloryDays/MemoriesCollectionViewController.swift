//
//  MemoriesCollectionViewController.swift
//  GloryDays
//
//  Created by Felipe Hernandez on 13-07-17.
//  Copyright © 2017 kafecode. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate {
    
    //array para cargar las memorias, es de tipo url porque son archivos
    var memories : [URL] = []
    var currentMemory : URL!
    
    //vaariable para el audio grabado
    var audioRecorder : AVAudioRecorder!
    var recordingURL : URL!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Se inicializa la URL
        self.recordingURL = try? getDocumentsDirectory().appendingPathComponent("memory-recording.m4a")
        
        
        
        //se llama a nuestro método de carga de memorias
        self.loadMemories()
        
        //generar boton añadir a la barra de navegacion
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))
        
        
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
    }
    
    
    //hacemos la llamada cuando la vista este lista
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Aqui la llamada para chequear los permisos
        self.checkForGrantedPermissions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //se chequean los permisos
    func checkForGrantedPermissions(){
        
        //comprobamos que los permisos estén otorgados
        let photosAuth: Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth: Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcriptionAuth: Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        //combinamos los 3 permisos en una variable, authorized será verdadera solo si las
        //3 variables son verdaderas
        let authorized = photosAuth && recordingAuth && transcriptionAuth
        
        //si no hay autorizacion se muestra la pantalla de permisos
        if !authorized{
            //se instancia el ViewController
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ShowTerms"){
                navigationController?.present(vc, animated: true, completion: nil)
            }
        }
        
        
    }
    
    func loadMemories(){
        
        //1. vaciar memorias para no duplicar
        self.memories.removeAll()
        
        //2. se obtienen los archivos desde la ruta indicada
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: [])else{
            return
        }
        
        //3. se recorren los archivos encontrados
        for file in files{
            
            let fileName = file.lastPathComponent
            
            //4. comprobar .thumb
            if fileName.hasSuffix(".thumb"){
                
                //5. quitamos la extensión
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                if let memoryPath = try? getDocumentsDirectory().appendingPathComponent(noExtension){
                
                    //6. cargamos en el array memories
                    memories.append(memoryPath)
                    
                }
                
            }
            
        }
        
        //se recarga la sección número 1
        collectionView?.reloadSections(IndexSet(integer: 1))
    
    }
    
    //Obtener ruta del directorio
    func getDocumentsDirectory() throws -> URL{
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]//selecciono el primer directorio
        return documentDirectory
    }
    
    //Añadir imagen
    func addImagePressed(){
    
        //instanciamos un ViewController de sistema en este caso un UIImagePickerController
        let vc =  UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        
        //lo presentamos
        navigationController?.present(vc, animated: true)
    }
    
    //sobreescribir metodo del UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            self.addNewMemory(image: theImage)
            self.loadMemories()
        }
    }
    
    
    //Metodo para añadir nueva memoria
    func addNewMemory(image: UIImage){
    
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        //guardar en disco
        do {
            let imagePath = try self.getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image, 80){
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbail = resizeImage(image: image, to: 200){
                
                let thumbPath:URL = try self.getDocumentsDirectory().appendingPathComponent(thumbName)
                
                if let jpegData = UIImageJPEGRepresentation(thumbail, 80){
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
            
            
        } catch {
            print("A fallado la escritura en el disco")
        }
    
    }
    
    //generar la miniatura
    func resizeImage(image: UIImage, to width:CGFloat) -> UIImage?{
        let scaleFactor = width / image.size.width
        let height = image.size.height * scaleFactor
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    //generar archivos
    func imageURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("txt")
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // tenemos dos secciones
        
        if section == 0{
            return 0
        }else{
            return self.memories.count
        }
    }

    //aca se añaden celdas
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
        
        let memory = self.memories[indexPath.row]
        let memoryName = try! self.thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: memoryName)
        
        cell.imageView.image = image
        
        //Se aaplican gestureRecognizers
        if cell.gestureRecognizers == nil{
        
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            //estilizar la celda
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 4
            cell.layer.cornerRadius = 10
        }
    
        return cell
    }
    
    //action para gesture
    func memoryLongPressed(sender: UILongPressGestureRecognizer){
        
        //inicio del gesture
        if sender.state == .began{
            //obtener la celda seleccionada
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell){
                self.currentMemory = self.memories[index.row]
                
                self.startRecordingMemory()
            }
        }
        
        //fin del gesture al levantar el dedo de la celda
        if sender.state == .ended{
        
            self.finishRecordingMemory(success: true)
            
        }
        
    }
    
    func startRecordingMemory(){
        
        collectionView?.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            
            try recordingSession.setCategory(AVAudioSessionCategoryRecord)
            try recordingSession.setActive(true)
            
            
            let recordingSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                     AVSampleRateKey: 44100,
                                     AVNumberOfChannelsKey: 2,
                                     AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        } catch let error{
            print(error)
            finishRecordingMemory(success: false)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
         finishRecordingMemory(success: false)
        }
    }
    
    func finishRecordingMemory(success: Bool){
        
        collectionView?.backgroundColor = UIColor(red: 97.0/255.0, green: 86.9/255.0, blue: 110.0/255.0, alpha: 1.0)
        
        audioRecorder.stop()
        
        if success{
            //grabar y transcribir
            do {
                
                let memoryAudioURL = try self.currentMemory.appendingPathExtension("m4a")
                
                //guardar o modificar archivos
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: memoryAudioURL.path){
                    //sustituir el actual archivo por uno nuevo
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                
                //Movemos el archivo a la ruta del dispositivo
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                
                self.transcribeAudioToText(memory: self.currentMemory)
                
            } catch let error {
                print("Ha ocurrido un error: \(error)")
            }
        }
        
        
    }
    
    func transcribeAudioToText(memory: URL){
        
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        
        let request = SFSpeechURLRecognitionRequest(url: audio)
        recognizer?.recognitionTask(with: request, resultHandler: {[unowned self] (result, error) in
            
            guard let result = result else{
                
                print("Ha ocurrido el siguiente error: \(error)")
                return
                
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                
                do{
                    
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                
                }catch{
                    print("Ha ocurrido un error al guardar la transcripción")
                }
            }
        })
        
        
        
    }
    
    
    //configurar la barra de busqueda
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceForHeaderInSection section: Int) -> CGSize {
        
        if section == 0{
            return CGSize(width: 0, height: 50)
        }else{
            return CGSize.zero
        }
        
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
