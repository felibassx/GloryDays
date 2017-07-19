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

private let reuseIdentifier = "Cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //array para cargar las memorias, es de tipo url porque son archivos
    var memories : [URL] = []
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //se llama a nuestro método de carga de memorias
        self.loadMemories()
        
        //generar boton añadir a la barra de navegacion
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))
        
        
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
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
    func getDocumentsDirectory() -> URL{
        
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
            let imagePath = try getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image, 80){
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbail = resizeImage(image: image, to: 200){
                
                let thumbPath = try getDocumentsDirectory().appendingPathComponent(thumbName)
                
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
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
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
