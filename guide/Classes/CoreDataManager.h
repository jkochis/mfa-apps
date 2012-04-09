//
//  CoreDataManager.h
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Tour.h"

@interface CoreDataManager : NSObject {
	NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (CoreDataManager *)sharedManager;

+ (NSArray *)getTours;
+ (Tour *)getTourById:(NSNumber *)tourId;
+ (Tour *)getTourByBundleName:(NSString *)bundleName;
+ (Tour *)addOrUpdateTourWithId:(NSNumber *)tourId 
						  title:(NSString *)title 
					 bundleName:(NSString *)bundleName 
					   language:(NSString *)language 
					updatedDate:(NSDate *)updatedDate 
					 sortWeight:(NSNumber *)sortWeight
						 errors:(BOOL)errors;
+ (BOOL)updateTour:(Tour *)tour;
+ (BOOL)updateTourUpdatedDate:(NSDate *)updatedDate byId:(NSNumber *)tourId;
+ (BOOL)updateTourSortWeight:(NSNumber *)sortWeight byId:(NSNumber *)tourId;
+ (BOOL)removeTour:(Tour *)tour;

@end
