//
//  ModelManager.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/17/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import Foundation
import CoreData

class ModelManager {
    
    static fileprivate let modelManager = ModelManager(modelName: "VirtualTourist")
    
    static func shared() -> ModelManager {
        return modelManager
    }
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    let backgroundContext: NSManagedObjectContext!
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            //self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
    
    func getAllPins() -> [MapPin] {
        let request: NSFetchRequest<MapPin> = MapPin.fetchRequest()
        var pins: [MapPin]!
        do {
            pins = try viewContext.fetch(request)
        }
        catch {
            pins = [MapPin]()
        }
        return pins
    }
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // fatalError() causes the application to generate a crash log and terminate.
                // I should not use this function in a shipping application.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func deletePin(pin: MapPin) {
        let fileManager = FileManager.default
        for path in pin.images! {
            if fileManager.fileExists(atPath: path) {
                try? fileManager.removeItem(atPath: path)
            }
        }
        viewContext.delete(pin)
        saveContext()
    }
    
    fileprivate func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
}

// MARK: - Autosaving

extension ModelManager {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
