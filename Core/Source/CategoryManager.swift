//
//  CategoryManager.swift
//  ProductLayerSDK
//
//  Created by Oliver Drobnik on 24/04/16.
//  Copyright © 2016 Cocoanetics. All rights reserved.
//

import CoreData
import DTFoundation

/// Manages product categories
@objc(PLYCategoryManager) public class CategoryManager: NSObject
{
	private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
	
	override init()
	{
		super.init()
		setupCoreDataStack()
	}
	
	private func addManagedCategory(category: PLYCategory, parentCategory: NSManagedObject? = nil, path: String = "", level: Int = 1, inContext context: NSManagedObjectContext)
	{
		let newEntry = NSEntityDescription.insertNewObjectForEntityForName("ManagedCategory", inManagedObjectContext: context)
		newEntry.setValue(category.key, forKey: "key")
		newEntry.setValue(category.localizedName, forKey: "localizedName")
		
		newEntry.setValue(parentCategory, forKey: "parent")
		
		var currentPath = path
		
		if currentPath.isEmpty
		{
			currentPath = category.localizedName
		}
		else
		{
			currentPath = currentPath + "/" + category.localizedName
		}
		
		newEntry.setValue(currentPath, forKey: "localizedPath")
		newEntry.setValue(level, forKey: "level")
		
		if let subCategories = category.subCategories as? [PLYCategory]
		{
			for subCategory in subCategories
			{
				addManagedCategory(subCategory, parentCategory: newEntry, path: currentPath, level: level+1, inContext: context)
			}
		}
	}
	
	public func mergeCategories(categories: [PLYCategory]) throws
	{
		let fetchRequest = NSFetchRequest(entityName: "ManagedCategory")
		try persistentStoreCoordinator.batchDelete(fetchRequest)
		
		let workerContext = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
		workerContext.persistentStoreCoordinator = persistentStoreCoordinator
		
		var retError: NSError!
		
		workerContext.performBlockAndWait {
			for category in categories
			{
				self.addManagedCategory(category, inContext: workerContext)
			}
			
			do {
				try workerContext.save()
			}
			catch let error as NSError
			{
				retError = error
			}
		}
		
		if retError != nil
		{
			throw retError
		}
	}
	
	public func localizedCategoryPathForKey(categoryKey: String) -> String?
	{
		let workerContext = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
		workerContext.persistentStoreCoordinator = persistentStoreCoordinator
		
		let fetchRequest = NSFetchRequest(entityName: "ManagedCategory")
		fetchRequest.predicate = NSPredicate(format: "key == %@", categoryKey)
		fetchRequest.fetchLimit = 1
		
		guard let results = try? workerContext.executeFetchRequest(fetchRequest) as! [NSManagedObject] where results.count > 0 else
		{
			return nil
		}
		
		if let firstObject = results.first
		{
			return firstObject.valueForKey("localizedPath") as? String
		}
		else
		{
			return nil
		}
	}
	
	public func categoriesMatchingSearch(search: String) throws -> [PLYCategory]
	{
		let workerContext = NSManagedObjectContext(concurrencyType:.MainQueueConcurrencyType)
		workerContext.persistentStoreCoordinator = persistentStoreCoordinator
		
		let fetchRequest = NSFetchRequest(entityName: "ManagedCategory")
		
		if !search.isEmpty
		{
			fetchRequest.predicate = predicateForSearch(search)
		}

		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "localizedPath", ascending: true)]

		let results = try workerContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
		
		if !search.isEmpty
		{
			// return hierarchy structure
			return categoryObjectsStructureFromManagedObjects(results)
		}
		else
		{
			// return flat array
			return categoryObjectsFromManagedObjects(results)
		}
	}
	
	// MARK: - Helpers
	
	private func predicateForSearch(search: String) -> NSPredicate
	{
		let separators = NSCharacterSet.alphanumericCharacterSet().invertedSet
		let parts = search.componentsSeparatedByCharactersInSet(separators)
		
		var subPredicates = [NSPredicate]()
		
		for part in parts
		{
			// skip empty parts
			guard !part.isEmpty else { continue }
			
			let predicate = NSPredicate(format: "localizedName MATCHES[cd] %@", ".*\\b\(part).*")
			subPredicates.append(predicate)
		}
		
		return NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
	}
	
	private func categoryObjectsFromManagedObjects(managedObjects: [NSManagedObject]) -> [PLYCategory]
	{
		var tmpArray = [PLYCategory]()
		
		var allObjectsAndParents = Set<NSManagedObject>()
		
		for managedObject in managedObjects
		{
			let category = PLYCategory()
			
			let key = managedObject.valueForKey("key")
			let localizedName = managedObject.valueForKey("localizedName")
			let localizedPath = managedObject.valueForKey("localizedPath")
			
			// set it via setValue because they are read-only
			category.setValue(key, forKey: "key")
			category.setValue(localizedName, forKey: "localizedName")
			category.setValue(localizedPath, forKey: "localizedPath")
			
			tmpArray.append(category)
		}
		
		return tmpArray
	}
	
	private func categoryObjectsStructureFromManagedObjects(managedObjects: [NSManagedObject]) -> [PLYCategory]
	{
		var tmpArray = [PLYCategory]()
		
		var allObjectsAndParents = Set<NSManagedObject>()
		
		var lookup = Dictionary<NSManagedObjectID, PLYCategory>()
		var rootCategories = Set<NSManagedObjectID>()
		
		for managedObject in managedObjects
		{
			// make sure that we have the found objects plus all parents
			allObjectsAndParents.insert(managedObject)

			var object = managedObject
			
			while let parent = object.valueForKey("parent") as? NSManagedObject
			{
				allObjectsAndParents.insert(parent)
				
				object = parent
				
				let category = PLYCategoryFromManagedCategory(object)
				lookup[object.objectID] = category
			}
			
			if object != managedObject
			{
				// object must be a new root
				rootCategories.insert(object.objectID)
			}
			
			// create PLYCategory for this object
			var category = PLYCategoryFromManagedCategory(managedObject)
			lookup[managedObject.objectID] = category
			
			if let parent = managedObject.valueForKey("parent") as? NSManagedObject
			{
				// append to subCategories of parent
				let parentCategory = lookup[parent.objectID]!
				
				var subCategories = parentCategory.valueForKey("subCategories") as? Array<PLYCategory> ?? Array<PLYCategory>()
				subCategories.append(category)
				parentCategory.setValue(subCategories, forKey: "subCategories")
			}
			else
			{
				// no parent
				rootCategories.insert(managedObject.objectID)
			}
		}
		
		return rootCategories.map { (objectID) -> PLYCategory in
			return lookup[objectID]!
		}
	}
	
	private func PLYCategoryFromManagedCategory(managedCategory: NSManagedObject) -> PLYCategory
	{
		let category = PLYCategory()
		
		let key = managedCategory.valueForKey("key")
		let localizedName = managedCategory.valueForKey("localizedName")
		let localizedPath = managedCategory.valueForKey("localizedPath")
		
		// set it via setValue because they are read-only
		category.setValue(key, forKey: "key")
		category.setValue(localizedName, forKey: "localizedName")
		category.setValue(localizedPath, forKey: "localizedPath")
		
		return category
	}
	
	private var managedObjectModel: NSManagedObjectModel = {
		
		// create model
		let model = NSManagedObjectModel()
		
		// create entity
		var entity = NSEntityDescription()
		entity.name = "ManagedCategory"
		//entity.managedObjectClassName = "PLYManagedCategory"
  
		// create attributes for entity
		
		var properties = [NSPropertyDescription]()
		
		// key
		var keyAttribute = NSAttributeDescription()
		keyAttribute.name = "key"
		keyAttribute.attributeType = .StringAttributeType
		keyAttribute.optional = false
		keyAttribute.indexed = true
		properties.append(keyAttribute)
		
		// category name
		var nameAttribute = NSAttributeDescription()
		nameAttribute.name = "localizedName"
		nameAttribute.attributeType = .StringAttributeType
		nameAttribute.optional = false
		nameAttribute.indexed = true
		properties.append(nameAttribute)

		// localizedPath
		var pathAttribute = NSAttributeDescription()
		pathAttribute.name = "localizedPath"
		pathAttribute.attributeType = .StringAttributeType
		pathAttribute.optional = false
		pathAttribute.indexed = true
		properties.append(pathAttribute)
		
		// localizedPath
		var levelAttribute = NSAttributeDescription()
		levelAttribute.name = "level"
		levelAttribute.attributeType = .Integer16AttributeType
		levelAttribute.optional = false
		levelAttribute.indexed = true
		properties.append(levelAttribute)
		
		// parent
		var parentRelation = NSRelationshipDescription()
		var childrenRelation = NSRelationshipDescription()
		
		parentRelation.name = "parent"
		parentRelation.destinationEntity = entity
		parentRelation.maxCount = 1
		parentRelation.minCount = 0
		parentRelation.inverseRelationship = childrenRelation
		childrenRelation.deleteRule = .NullifyDeleteRule
		properties.append(parentRelation)
		
		// children
		childrenRelation.name = "children"
		childrenRelation.destinationEntity = entity
		childrenRelation.maxCount = 0
		childrenRelation.minCount = 0
		childrenRelation.inverseRelationship = parentRelation
		childrenRelation.deleteRule = .CascadeDeleteRule
		properties.append(childrenRelation)

		
		// set properties on entity
		entity.properties = properties
		
		// add the entity to the model
		model.entities = [entity]
		
		// return model
		return model
	}()
	
	func setupCoreDataStack()
	{
		let managedObjectModel = self.managedObjectModel
		
		let cachesURL = NSURL(fileURLWithPath: NSString.cachesPath())
		let storeURL = cachesURL.URLByAppendingPathComponent("PLYCategoryDB.cache")
		
		persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		
		do
		{
			try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
		}
		catch let error as NSError
		{
			NSLog("%@", error.localizedDescription)
		}
	}
}


extension NSPersistentStoreCoordinator
{
	func batchDelete(fetchRequest: NSFetchRequest) throws
	{
		// create a worker
		let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
		context.persistentStoreCoordinator = self
		
		var retError: NSError!
		
		context.performBlockAndWait
			{
				do
				{
					if #available(iOS 9.0, *)
					{
						let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
						
						try self.executeRequest(deleteRequest, withContext: context)
					}
					else // Fallback on earlier versions
					{
						// make copy of request with some modifications
						let deleteRequest = NSFetchRequest(entityName: fetchRequest.entityName!)
						deleteRequest.predicate = fetchRequest.predicate
						deleteRequest.includesPropertyValues = false
						
						// fetch all
						let result = try context.executeFetchRequest(deleteRequest) as! [NSManagedObject]
						
						// delete
						for object in result
						{
							context.deleteObject(object)
						}
						
						// save context
						try context.save()
					}
				}
				catch let error as NSError
				{
					retError = error
				}
		}
		
		if retError != nil
		{
			throw retError
		}
	}
}
