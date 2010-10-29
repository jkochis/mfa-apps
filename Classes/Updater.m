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

- (NSUInteger)needsUpdating:(NSArray *)tours;
- (void)updateNextTour;

@end

@implementation Updater

@synthesize delegate, checking, updatableTours, encounteredErrors;

- (void)dealloc
{
	[dataProvider release];
	[availableTours release];
	[updatableTours release];
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
	// start queue
	encounteredErrors = NO;
	[self updateNextTour];
}

- (void)updateNextTour
{
	// Update bundle using ftp bundle manager
//	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
//	FTPBundleManager *bundleManager = [[FTPBundleManager alloc] init];
//	[bundleManager setDelegate:self];
//	[bundleManager retrieveOrUpdateBundle:[remoteTour bundleName]];
//	[bundleManager release];
	
	// Update bundle using http bundle manager
	encounteredErrors = NO;
	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
	HTTPBundleManager *bundleManager = [[HTTPBundleManager alloc] init];
	[bundleManager setDelegate:self];
	[bundleManager retrieveOrUpdateBundle:[remoteTour bundleName] withTourML:[NSURL URLWithString:[remoteTour bundleTourML]]];
	[bundleManager release];
	
	// Notify delegate
	if ([delegate respondsToSelector:@selector(updater:didStartUpdatingBundle:)]) {
		[delegate updater:self didStartUpdatingBundle:[remoteTour bundleName]];
	}
}

- (void)removeCurrentAndCheckNextTour
{
	// Remove from queue
	[updatableTours removeObjectAtIndex:0];
	
	// Begin updating next bundle, if available
	if ([updatableTours count]) {
		[self updateNextTour];
	}
	else {
		// Notify delegate that update is complete
		if ([delegate respondsToSelector:@selector(updaterDidFinish:)]) {
			[delegate updaterDidFinish:self];
		}
	}
}

- (NSUInteger)needsUpdating:(NSArray *)tours
{
	// Nterate through tours, adding tours available for update to queue
	updatableTours = [[NSMutableArray alloc] init];
	for (ToursXMLTour *remoteTour in tours)
	{
		// Get tour from CoreData, and if not present add to queue
		Tour *tour = [CoreDataManager getTourById:[remoteTour id]];
		if (!tour) {
			[updatableTours addObject:remoteTour];
		}
		
		// If last update resulted in error, make tour available
		else if ([[tour errors] boolValue]) {
			[updatableTours addObject:remoteTour];
		}
		
		// Otherwise compare date from XML to date in CoreData or look for errors
		else {
			NSDate *date = [remoteTour updatedDate];
			if ([[tour updatedDate] compare:date] == NSOrderedAscending) {
				[updatableTours addObject:remoteTour];
			}
		}
	}
	return [updatableTours count];
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

- (void)dataProvider:(UpdaterDataProvider *)dataProvider didRetrieveTours:(NSArray *)tours
{
	// Be sure to hold on to tours, the notify delegate if there are updates available
	checking = NO;
	availableTours = [tours retain];
	if ([delegate respondsToSelector:@selector(updater:hasAvailableUpdates:)]) {
		[delegate updater:self hasAvailableUpdates:[self needsUpdating:tours]];
	}
}

/*
#pragma mark -
#pragma mark FTPBundleManagerDelegate Methods

- (void)bundleManager:(FTPBundleManager *)bundleManager didEncounterError:(NSError *)error
{
	
}

- (void)bundleManager:(FTPBundleManager *)bundleManager didFailWithError:(NSError *)error
{
	
}

- (void)bundleManager:(FTPBundleManager *)bundleManager didStartUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	if ([delegate respondsToSelector:@selector(updater:didStartUpdatingFile:fileNumber:outOf:)]) {
		[delegate updater:self didStartUpdatingFile:pathToFile fileNumber:fileNumber outOf:totalFiles];
	}
}

- (void)bundleManager:(FTPBundleManager *)bundleManager didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)pathToFile
{
	if ([delegate respondsToSelector:@selector(updater:didRecieveBytes:outOfTotalBytes:forFile:)]) {
		[delegate updater:self didRecieveBytes:bytes outOfTotalBytes:totalBytes forFile:pathToFile];
	}
}

- (void)bundleManager:(FTPBundleManager *)bundleManager didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	if ([delegate respondsToSelector:@selector(updater:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate updater:self didFinishUpdatingFile:pathToFile fileNumber:fileNumber outOf:totalFiles];
	}
}

- (void)bundleManagerCompletedUpdate:(FTPBundleManager *)bundleManager
{	
	// grab tour from queue, add or update in CoreData
	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
	[CoreDataManager addOrUpdateTourWithId:[remoteTour id]
									 title:[remoteTour title]
								bundleName:[remoteTour bundleName]
								  language:[remoteTour language]
							   updatedDate:[NSDate date]];
	
	// notfiy delegate
	if ([delegate respondsToSelector:@selector(updater:didFinishUpdatingBundle:)]) {
		[delegate updater:self didFinishUpdatingBundle:[remoteTour bundleName]];
	}
	
	// remove from queue
	[updatableTours removeObjectAtIndex:0];
	
	// begin updating next bundle, if available
	if ([updatableTours count]) {
		[self updateNextTour];
	}
	else {
		// notify delegate that update is complete
		if ([delegate respondsToSelector:@selector(updaterDidFinish:)]) {
			[delegate updaterDidFinish:self];
		}
	}
}
*/

#pragma mark -
#pragma mark HTTPBundleManagerDelegate Methods

- (void)bundleManager:(HTTPBundleManager *)bundleManager didFailToRetrieveTourML:(NSURL *)tourMLUrl
{
	encounteredErrors = YES;
	if ([delegate respondsToSelector:@selector(updater:didFailWithError:)]) {
		NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not retrieve TourML file: %@", tourMLUrl] forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:1001 userInfo:dict];
		[delegate updater:self didFailWithError:error];
	}
	[self removeCurrentAndCheckNextTour];
}

- (void)bundleManager:(HTTPBundleManager *)bundleManager didFailWithError:(NSError *)error
{
	encounteredErrors = YES;
	if ([delegate respondsToSelector:@selector(updater:didFailWithError:)]) {
		[delegate updater:self didFailWithError:error];
	}
}

- (void)bundleManager:(HTTPBundleManager *)bundleManager didStartUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	if ([delegate respondsToSelector:@selector(updater:didStartUpdatingFile:fileNumber:outOf:)]) {
		[delegate updater:self didStartUpdatingFile:pathToFile fileNumber:fileNumber outOf:totalFiles];
	}
}

- (void)bundleManager:(HTTPBundleManager *)bundleManager didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)pathToFile
{
	if ([delegate respondsToSelector:@selector(updater:didRecieveBytes:outOfTotalBytes:forFile:)]) {
		[delegate updater:self didRecieveBytes:bytes outOfTotalBytes:totalBytes forFile:pathToFile];
	}
}

- (void)bundleManager:(HTTPBundleManager *)bundleManager didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	if ([delegate respondsToSelector:@selector(updater:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate updater:self didFinishUpdatingFile:pathToFile fileNumber:fileNumber outOf:totalFiles];
	}
}

- (void)bundleManagerCompletedUpdate:(HTTPBundleManager *)bundleManager
{	
	// Grab tour from queue, add or update in CoreData
	ToursXMLTour *remoteTour = [updatableTours objectAtIndex:0];
	[CoreDataManager addOrUpdateTourWithId:[remoteTour id]
									 title:[remoteTour title]
								bundleName:[remoteTour bundleName]
								  language:[remoteTour language]
							   updatedDate:[NSDate date]
									errors:encounteredErrors];
	
	// Notfiy delegate
	if ([delegate respondsToSelector:@selector(updater:didFinishUpdatingBundle:)]) {
		[delegate updater:self didFinishUpdatingBundle:[remoteTour bundleName]];
	}
	
	// Remove form queue and check next tour
	[self removeCurrentAndCheckNextTour];
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
