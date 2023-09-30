//
//  ContentView.swift
//  CarID
//
//  Created by Aryan Sinha on 17/09/23.
//

import UIKit
import CoreML
import Vision
import ImageIO

struct SavedCar {
    var name: String
    var timestamp: Date
}

class ImageClassificationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton! // Added Save button
    
    // MARK: - Recognized Car Name Property
    var recognizedCarName: String?
    
    // MARK: - Saved Cars
    var savedCars: [SavedCar] = [] // Declare the savedCars array here
    
//    override func viewDidLoad() {
//           super.viewDidLoad()
//
//           // Show the Save button by default
//           saveButton.isEnabled = false
//           saveButton.alpha = 0.5 // You can adjust the alpha to make it less prominent
//
//           // Set the button title
//           saveButton.setTitle("Save", for: .normal)
//       }
    
    // MARK: - Image Classification
    
    /// - Tag: MLModelSetup
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Use the "cars.mlmodel" model to recognize cars
            let model = try VNCoreMLModel(for: cars().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    /// - Tag: PerformRequests
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the UI with the results of the classification (updated for car recognition).
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                // We should never end up here, but just "in case"
                self.classificationLabel.text = "I have no idea what it is."
            } else {
                // Sort the classifications by confidence in descending order
                let sortedClassifications = classifications.sorted(by: { $0.confidence > $1.confidence })
                
                // Get the name of the top classification
                let topClassification = sortedClassifications[0]
                let objectName = topClassification.identifier
                
                // Store the recognized car's name
                self.recognizedCarName = objectName
                
                // Display the recognized car's name
                self.classificationLabel.text = "Recognized: \(objectName)"
                
                // To spice things a little, we signal lack of confidence for results below 0.6
                if topClassification.confidence < 0.6 {
                    self.classificationLabel.text = "Maybe \(objectName)..."
                }
            }
        }
    }
    
    // MARK: - Photo Actions
    
    @IBAction func takePicture() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            updateClassifications(for: image)
        }
    }
    
    // MARK: - Save Button Action
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
            if let recognizedCarName = recognizedCarName {
                let savedCar = SavedCar(name: recognizedCarName, timestamp: Date())
                savedCars.append(savedCar)
                
                // Optionally, you can sort the savedCars array by timestamp to display the latest saved cars first.
                savedCars.sort { $0.timestamp > $1.timestamp }
                
                // Clear the recognized car name
                self.recognizedCarName = nil
                
                // Update the user interface (e.g., display a success message)
                let alertController = UIAlertController(title: "Car Saved!", message: "Car: \(recognizedCarName) has been saved.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
