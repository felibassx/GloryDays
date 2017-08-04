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

import CoreSpotlight
import MobileCoreServices

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, UISearchBarDelegate {
    
    //array para cargar las memorias, es de tipo url porque son archivos
    var memories : [URL] = []
    var filteredMemories : [URL] = []
    
    var currentMemory : URL!
    
    //variables para el audio
    var audioPlayer : AVAudioPlayer?
    var audioRecorder : AVAudioRecorder?
    var recordingURL : URL!
    
    var searchQuery : CSSearchQuery?
    

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
    
    func loadMemories() {
        self.memories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }
        
        for file in files {
            
            let fileName = file.lastPathComponent
            
            if fileName.hasSuffix(".thumb") {
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                let memoryPath =  getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
                
            }
        }
        
        
        filteredMemories = memories
        
        collectionView?.reloadSections(IndexSet(integer: 1))
        
    }
    
    //Obtener ruta del directorio
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
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
        
        do {
            
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            
            if let thumbail = resizeImage(image: image, to: 200) {
                let thumbPath = getDocumentsDirectory().appendingPathComponent(thumbName)
                
                if let jpegData = UIImageJPEGRepresentation(thumbail, 80) {
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
                
            }
            
            
        } catch {
            print("Ha fallado la escritura en disco")
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
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    
    func transcriptionURL(for memory: URL) -> URL {
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
            return self.filteredMemories.count
        }
    }

    //aca se añaden celdas
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
        
        let memory = self.filteredMemories[indexPath.row]
        let memoryName = self.thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageView.image = image
        
        if cell.gestureRecognizers == nil {
            
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
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
                self.currentMemory = self.filteredMemories[index.row]
                
                self.startRecordingMemory()
            }
        }
        
        //fin del gesture al levantar el dedo de la celda
        if sender.state == .ended{
        
            self.finishRecordingMemory(success: true)
            
        }
        
    }
    
    func startRecordingMemory(){
        
        audioPlayer?.stop()
        
        collectionView?.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do{
            
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let recordingSettings = [ AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                                      AVSampleRateKey : 44100,
                                      AVNumberOfChannelsKey : 2,
                                      AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            
        } catch let error {
            print(error)
            finishRecordingMemory(success: false)
        }
        
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
         finishRecordingMemory(success: false)
        }
    }
    
    func finishRecordingMemory(success: Bool) {
        
        collectionView?.backgroundColor = UIColor(red: 97.0/255.0, green: 86.0/255.0, blue: 110.0/255.0, alpha: 1.0)
        
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudioURL = self.currentMemory.appendingPathExtension("m4a")
                
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: memoryAudioURL.path) {
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                
                self.transcribeAudioToText(memory: self.currentMemory)
                
                
            } catch let error {
                print("Ha habido un error \(error)")
            }
        }
        
    }
    
    func transcribeAudioToText(memory: URL){
        
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        
        let request = SFSpeechURLRecognitionRequest(url: audio)
        recognizer?.recognitionTask(with: request, resultHandler: {(result, error) in
            
            guard let result = result else{
                
                print("Ha ocurrido un error al transcribir el audio a texto.")
                return
                
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                
                do{
                    
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    self.indexMemory(memory: memory, text:text)
                    
                }catch{
                    print("Ha ocurrido un error al guardar la transcripción")
                }
            }
        })
        
        
        
    }
    
    func indexMemory(memory: URL, text: String){
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Recuerdos de GloryDays"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)
        
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "cl.felibass", attributeSet: attributeSet)
        
        item.expirationDate = Date.distantFuture
        
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            if let error = error {
                print("Ha ocurrido un error al indexar \(error)")
            }else{
                print("Todo a salido OK al idexar el texto \(text)")
            }
        }
    }
    
    
    //configurar la barra de busqueda
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        
        return header
    }
    
    
    //para que la barra de busqueda solo aparezca en la seccion 0
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        if section == 0{
            return CGSize(width: 0, height: 50)
        }else{
            return CGSize.zero
        }
    }
    
    
    //Reproducir audio y obtener transcripcion
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = self.filteredMemories[indexPath.row]
        
        let fileManager = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if fileManager.fileExists(atPath: audioName.path){
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            }
            
            if fileManager.fileExists(atPath: transcriptionName.path){
                let content = try String(contentsOf: transcriptionName)
                print(content)
            }
            
        } catch  {
            print("Error al cargar el audio")
        }
        
    }
    
    func filterMemories(text: String){
        
        guard text.characters.count > 0 else {
            self.filteredMemories = self.memories
            
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            
            return
        }
        
        
        
        
        var allTheItems : [CSSearchableItem] = []
        
        self.searchQuery?.cancel()
        
        let queryString = "contentDescription == \"*\(text)*\"c"
        self.searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        
        self.searchQuery?.foundItemsHandler = { items in
            allTheItems.append(contentsOf: items)
        }
        
        self.searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allTheItems)
            }
        }
        
        self.searchQuery?.start()
        
    }
    
    func activateFilter(matches: [CSSearchableItem]){
        
        self.filteredMemories = matches.map { item in
            let uniqueID = item.uniqueIdentifier
            let url = URL(fileURLWithPath: uniqueID)
            return url
        }
        
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }
        
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterMemories(text: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
