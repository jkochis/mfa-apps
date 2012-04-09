//
//  CoreDataManager.m
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "CoreDataManager.h"

@implementation CoreDataManager

#pragma mark -
#pragma mark Singleton Methods

static CoreDataManager *sharedUpdatedCoreDataManager = nil;

+ (CoreDataManager *)sharedManager
{
	if (sharedUpdatedCoreDataManager == nil) {
		sharedUpdatedCoreDataManager = [[super allocWithZone:NULL] init];
	}
	return sharedUpdatedCoreDataManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;
}

- (oneway void)release
{
	// do nothing
}

- (id)autorelease
{
	return self;
}

#pragma mark -
#pragma mark CoreData Stack

- (NSManagedObjectContext *)managedObjectContext
{	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Tours" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSURL *storeUrl = [NSURL fileURLWithPath: [documentsDirectory stringByAppendingPathComponent: @"Tours.sqlite"]];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, 
							 nil];
	NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }    
    return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Tour Methods

+ (NSArray *)getTours
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Tour" inManagedObjectContext:managedObjectContext]];
//	[request setSortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"sortWeight" ascending:YES], 
//														  [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES], 
//														  nil]];
	NSArray *results = [managedObjectContext executeFetchRequest:request error:nil];
	if (!results || ![results count]) {
		return nil;
	}
	return results;
}

+ (Tour *)getTourById:(NSNumber *)tourId
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Tour" inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"id == %@", tourId]];
	NSArray *results = [managedObjectContext executeFetchRequest:request error:nil];
	if (!results || ![results count]) {
		return nil;
	}
	return [results objectAtIndex:0];
}

+ (Tour *)getTourByBundleName:(NSString *)bundleName
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Tour" inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"bundleName == %@", bundleName]];
	NSArray *results = [managedObjectContext executeFetchRequest:request error:nil];
	if (!results || ![results count]) {
		return nil;
	}
	return [results objectAtIndex:0];
}

+ (Tour *)addOrUpdateTourWithId:(NSNumber *)tourId 
						  title:(NSString *)title 
					 bundleName:(NSString *)bundleName 
					   language:(NSString *)language 
					updatedDate:(NSDate *)updatedDate 
					 sortWeight:(NSNumber *)sortWeight
						 errors:(BOOL)errors
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	Tour *tour = [CoreDataManager getTourById:tourId];
	if (!tour) {
		tour = (Tour *)[NSEntityDescription insertNewObjectForEntityForName:@"Tour" inManagedObjectContext:managedObjectContext];
	}
	[tour setId:tourId];
	[tour setTitle:title];
	[tour setBundleName:bundleName];
	[tour setLanguage:language];
	[tour setUpdatedDate:updatedDate];
	[tour setSortWeight:sortWeight];
	[tour setErrors:[NSNumber numberWithBool:errors]];
	NSError *error;
	if (![managedObjectContext save:&error]) {
		NSLog(@"%@", [error localizedDescription]);
		return nil;
	}
	return tour;
}

+ (BOOL)updateTour:(Tour *)tour
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	NSError *error;
	if (![managedObjectContext save:&error]) {
		NSLog(@"%@", [error localizedDescription]);
		return NO;
	}
	return YES;
}

+ (BOOL)updateTourUpdatedDate:(NSDate *)updatedDate byId:(NSNumber *)tourId
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	Tour *tour = [CoreDataManager getTourById:tourId];
	if (!tour) {
		return NO;
	}
	[tour setUpdatedDate:updatedDate];
	NSError *error;
	if (![managedObjectContext save:&error]) {
		NSLog(@"%@", [error localizedDescription]);
		return NO;
	}
	return YES;
}

+ (BOOL)updateTourSortWeight:(NSNumber *)sortWeight byId:(NSNumber *)tourId
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	Tour *tour = [CoreDataManager getTourById:tourId];
	if (!tour) {
		return NO;
	}
	[tour setSortWeight:sortWeight];
	NSError *error;
	if (![managedObjectContext save:&error]) {
		NSLog(@"%@", [error localizedDescription]);
		return NO;
	}
	return YES;
}

+ (BOOL)removeTour:(Tour *)tour
{
	NSManagedObjectContext *managedObjectContext = [[CoreDataManager sharedManager] managedObjectContext];
	[managedObjectContext deleteObject:tour];
	NSError *error;
	if (![managedObjectContext save:&error]) {
		NSLog(@"%@", [error localizedDescription]);
		return NO;
	}
	return YES;
}

@end
