//
//  Updater.m
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "Updater.h"

#import	"HTTPBundleManager.h"
#import "ToursXMLTour.h"

@interface Updater (PrivateMethods)

- (NSUInteger)needsUpdating:(NSArray *)remoteTours;
- (void)updateNextTour;
- (void)updateNextTourWithErrors:(BOOL)errors shouldSkipToCurrentFile:(BOOL)skip;
- (void)skipToTourWithName:(NSString *)bundleName andFile:(NSUInteger)file;
- (void)removeTours;
- (void)advanceUpdater;
- (void)completeUpdate;

@end

@implementation Updater

@synthesize delegate, checking, updatableTours, removableTours, filesWithErrors, encounteredErrors;

- (void)dealloc
{
	[dataProvider release];
	[bundleManager release];
	[availableTours release];
	[updatableTours release];
	[removableTours release];
	[filesWithErrors release];
	[super dealloc];
}

- (void)checkForUpdates
{
	// lazy initialization
	if (!dataProvider) {
		dataProvider = [[UpdaterDataProvider alloc] initWithDelegate:self];
	}
	
	// get latest from data provider
	[dataProvider getLatest];
	checking = YES;
}

- (void)performUpdate
{
	[self performUpdate:NO];
}

- (void)performUpdate:(BOOL)quick
{	
	// start queue
	quickUpdate = quick;
	if ([updatableTours count]) {
		[self updateNextTour];
	}
	else {
		if ([removableTours count]) {
			[self removeTours];
		}
		[self completeUpdate];
	}
}

- (void)cancel
{
	if (dataProvider) {
		[dataProvider cancel];
	}
	if (bundleManager) {
		[bundleManager cancel];
	}
}

- (void)updateNextTour
{
	[self updateNextTourWithErrors:NO shouldSkipToCurrentFile:NO];
}

- (void)updateNextTourWithErrors:(BOOL)errors shouldSkipToCurrentFile:(BOOL)skip
{	
	// prep update
	encounteredErrors = errors;
	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
	[self setFilesWithErrors:[NSMutableArray array]];
	if (bundleManager) {
		[bundleManager release];
	}
	bundleManager = [[HTTPBundleManager alloc] init];
	[bundleManager setDelegate:self];
	
	// Check for update type
	if (quickUpdate) {
		
		// Get list of errors
		NSArray *files = [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"filesWithErrors_%@", [remoteTour bundleName]]];
		if (files != nil && [files count]) {
			[bundleManager retrieveOrUpdateBundle:[remoteTour bundleName] withFiles:[[files mutableCopy] autorelease]];
			if ([delegate respondsToSelector:@selector(updater:didStartUpdatingBundle:)]) {
				[delegate updater:self didStartUpdatingBundle:[remoteTour bundleName]];
			}
		}
		else {
			[self advanceUpdater];
			return;
		}
	}
	else {
		if (skip && [[remoteTour bundleName] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"updaterCurrentBundle"]]) {
			[bundleManager retrieveOrUpdateBundle:[remoteTour bundleName] 
									   withTourML:[NSURL URLWithString:[remoteTour bundleTourML]] 
								 startingWithFile:[[NSUserDefaults standardUserDefaults] integerForKey:@"updaterCurrentFile"]];
		}
		else {
			[[NSUserDefaults standardUserDefaults] setObject:[remoteTour bundleName] forKey:@"updaterCurrentBundle"];
			[bundleManager retrieveOrUpdateBundle:[remoteTour bundleName] withTourML:[NSURL URLWithString:[remoteTour bundleTourML]]];
		}
		if ([delegate respondsToSelector:@selector(updater:didStartUpdatingBundle:)]) {
			[delegate updater:self didStartUpdatingBundle:[remoteTour bundleName]];
		}
	}
}

- (void)recheckNextTour
{
	
}

- (void)removeTours
{
	if (!bundleManager) {
		bundleManager = [[HTTPBundleManager alloc] init];
	}
	for (Tour *tour in removableTours) {
		NSError *error = nil;
		if (![bundleManager removeBundle:[tour bundleName] error:&error]) {
			if ([delegate respondsToSelector:@selector(updater:didFailToRemoveBundle:withError:)]) {
				[delegate updater:self didFailToRemoveBundle:[tour bundleName] withError:error];
			}
		}
		else {
			if ([delegate respondsToSelector:@selector(updater:didRemoveBundle:)]) {
				[delegate updater:self didRemoveBundle:[tour bundleName]];
			}
			[CoreDataManager removeTour:tour];
		}
	}
	[bundleManager release];
	bundleManager = nil;
}

- (void)advanceUpdater
{
	// Remove from queue
	[updatableTours removeObjectAtIndex:0];
	
	// Begin updating next bundle, if available
	if ([updatableTours count]) {
		[self updateNextTour];
	}
	else {
		
		// Check for removable tours
		if ([removableTours count]) {
			[self removeTours];
		}
		
		// Complete update
		[self completeUpdate];
	}
}

- (void)completeUpdate
{
	// Reset current tour and file
	[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"updaterCurrentTour"];
	[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"updaterCurrentFile"];
	
	// Notify delegate that update is complete
	if ([delegate respondsToSelector:@selector(updaterDidFinish:)]) {
		[delegate updaterDidFinish:self];
	}
	[bundleManager release];
	bundleManager = nil;
}

- (NSUInteger)needsUpdating:(NSArray *)remoteTours
{
	// Iterate through remote tours, adding tours available for update to queue
	if (updatableTours) {
		[updatableTours release];
	}
	updatableTours = [[NSMutableArray alloc] init];
	for (ToursXMLTour *remoteTour in remoteTours)
	{
		// Get tour from CoreData, and if not present add to queue
		Tour *localTour = [CoreDataManager getTourById:[remoteTour id]];
		if (!localTour) {
			[updatableTours addObject:remoteTour];
		}
		else { 
		
			// Update sort weight for local tour
			[localTour setSortWeight:[remoteTour sortWeight]];
			[CoreDataManager updateTour:localTour];
			
			// If last update resulted in error, make tour available for update
			if ([[localTour errors] boolValue]) {
				[updatableTours addObject:remoteTour];
			}
			
			// Otherwise compare date from XML to date in CoreData
			else {
				NSDate *date = [remoteTour updatedDate];
				if ([[localTour updatedDate] compare:date] == NSOrderedAscending) {
					[updatableTours addObject:remoteTour];
				}
			}
		}
	}
	
	// Iterate through local tours, adding removable tours to queue
	if (removableTours) {
		[removableTours release];
	}
	removableTours = [[NSMutableArray alloc] init];
	NSArray *localTours = [CoreDataManager getTours];
	for (Tour *localTour in localTours) {
		
		// Check remote tours for local tour id
		NSUInteger index = [remoteTours indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			return [[localTour id] isEqualToNumber:[(ToursXMLTour *)obj id]];
		}];
		if (index == NSNotFound) {
			[removableTours addObject:localTour];
		}
	}
	
	return [updatableTours count] + [removableTours count];
}

#pragma mark -
#pragma mark UpdaterDataProviderDelegate Methods

- (void)dataProvider:(UpdaterDataProvider *)dataProvider didFailWithError:(NSError *)error
{
	checking = NO;
	if ([delegate respondsToSelector:@selector(updaterDidFailToRetrieveToursXML:)]) {
		[delegate updaterDidFailToRetrieveToursXML:self];
	}
	if ([delegate respondsToSelector:@selector(updaterDidFinish:)]) {
		[delegate updaterDidFinish:self];
	}
}

- (void)dataProvider:(UpdaterDataProvider *)theDataProvider didRetrieveTours:(NSArray *)tours
{
	// Be sure to hold on to tours, then notify delegate if there are updates available
	checking = NO;
	if (availableTours != nil) {
		[availableTours release];
	}
	availableTours = [tours retain];
	if ([delegate respondsToSelector:@selector(updater:hasAvailableUpdates:)]) {
		[delegate updater:self hasAvailableUpdates:[self needsUpdating:tours]];
	}
	[dataProvider release];
	dataProvider = nil;
}

#pragma mark -
#pragma mark HTTPBundleManagerDelegate Methods

- (void)bundleManager:(HTTPBundleManager *)theBundleManager didFailToRetrieveTourML:(NSURL *)tourMLUrl
{
	encounteredErrors = YES;
	if ([delegate respondsToSelector:@selector(updater:didFailWithError:)]) {
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not retrieve TourML file: %@", tourMLUrl] forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:1001 userInfo:dict];
		[delegate updater:self didFailWithError:error];
	}
	[self advanceUpdater];
}

- (void)bundleManager:(HTTPBundleManager *)theBundleManager didFailWithError:(NSError *)error
{
	// Temporary fix not flag tours as having errors when being given a directory in place of a file.
	// Currently, this is an error with TAP and will be addressed with a PHP fix
	if ([error code] != HTTPRequestFileIsDirectoryError) {
		
		// Flag as errors encountered
		encounteredErrors = YES;
		
		// Update list of files with errors for tour
		[filesWithErrors addObject:[[theBundleManager updatableFiles] objectAtIndex:0]];
		[[NSUserDefaults standardUserDefaults] setObject:filesWithErrors forKey:[NSString stringWithFormat:@"filesWithErrors_%@", [theBundleManager bundleName]]];
		
		// Notify delegate
		if ([delegate respondsToSelector:@selector(updater:didFailWithError:)]) {
			[delegate updater:self didFailWithError:error];
		}
	}
}

- (void)bundleManager:(HTTPBundleManager *)theBundleManager didStartUpdatingFile:(NSString *)filePath fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	[[NSUserDefaults standardUserDefaults] setInteger:fileNumber forKey:@"updaterCurrentFile"];
	if ([delegate respondsToSelector:@selector(updater:didStartUpdatingFile:fileNumber:outOf:)]) {
		[delegate updater:self didStartUpdatingFile:filePath fileNumber:fileNumber outOf:totalFiles];
	}
}

- (void)bundleManager:(HTTPBundleManager *)theBundleManager didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)filePath
{
	if ([delegate respondsToSelector:@selector(updater:didRecieveBytes:outOfTotalBytes:forFile:)]) {
		[delegate updater:self didRecieveBytes:bytes outOfTotalBytes:totalBytes forFile:filePath];
	}
}

- (void)bundleManager:(HTTPBundleManager *)theBundleManager didFinishUpdatingFile:(NSString *)filePath fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	if ([delegate respondsToSelector:@selector(updater:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate updater:self didFinishUpdatingFile:filePath fileNumber:fileNumber outOf:totalFiles];
	}
}

- (void)bundleManager:(HTTPBundleManager *)theBundleManager didRemoveFile:(NSString *)filePath
{
	if ([delegate respondsToSelector:@selector(updater:didRemoveFile:)]) {
		[delegate updater:self didRemoveFile:filePath];
	}
}

- (void)bundleManagerCompletedUpdate:(HTTPBundleManager *)theBundleManager
{	
	// Grab tour from queue, add or update in CoreData
	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
	[CoreDataManager addOrUpdateTourWithId:[remoteTour id]
									 title:[remoteTour title]
								bundleName:[remoteTour bundleName]
								  language:[remoteTour language]
							   updatedDate:[remoteTour updatedDate]
								sortWeight:[remoteTour sortWeight]
									errors:encounteredErrors];
	
	// Clear out list of files with errors if none were encountered
	if (!encounteredErrors) {
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:[NSString stringWithFormat:@"filesWithErrors_%@", [theBundleManager bundleName]]];
	}
	
	// Notfiy delegate
	if ([delegate respondsToSelector:@selector(updater:didFinishUpdatingBundle:)]) {
		[delegate updater:self didFinishUpdatingBundle:[remoteTour bundleName]];
	}
	
	// Remove form queue and check next tour
	[self advanceUpdater];
}

- (void)bundleManagerCompletedQuickUpdate:(HTTPBundleManager *)theBundleManager
{
	// Check to see if the bundle is the one the updater last left off at...
	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
	if ([[remoteTour bundleName] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"updaterCurrentBundle"]]) {
		
		// Turn off quick update
		quickUpdate = NO;
		
		// tell updater to skip to the current file
		[self updateNextTourWithErrors:encounteredErrors shouldSkipToCurrentFile:YES];
	}
	
	// ...otherwise continue with business as usual
	else {
		[self bundleManagerCompletedUpdate:theBundleManager];
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		[self checkForUpdates];
	}
}

@end
