//
//  BackgroundUpdater.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "BackgroundUpdater.h"


@implementation BackgroundUpdater

@synthesize delegate, updater, isUpdating;

- (id)initWithDelegate:(id<BackgroundUpdaterDelegate>)theDelegate
{
	if ((self = [super init])) {
		[self setDelegate:theDelegate];
	}
	return self;
}

- (Updater *)updater
{
	if (!updater) {
		updater = [[Updater alloc] init];
		[updater setDelegate:self];
	}
	return updater;
}

- (void)dealloc
{
	[delegate release];
	[updater release];
	[super dealloc];
}

- (void)update
{
	NSLog(@"Checking for updates...");
	isUpdating = YES;
	[[self updater] checkForUpdates];
}

#pragma mark -
#pragma mark UpdaterDelegate Methods

- (void)updater:(Updater *)theUpdater didFailWithError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(backgroundUpdater:didFailWithError:)]) {
		[delegate backgroundUpdater:self didFailWithError:error];
	}
}

- (void)updaterDidFailToRetrieveToursXML:(Updater *)updater
{
	NSLog(@"Failed to retrieve tours.xml");
}

- (void)updater:(Updater *)theUpdater hasAvailableUpdates:(NSUInteger)availableUpdates
{
	NSLog(@"%lu updates available.", availableUpdates);
	if (availableUpdates) {
		NSLog(@"Performing updates...");
		[updater performUpdate];
	}
	else {
		isUpdating = NO;
		if ([delegate respondsToSelector:@selector(backgroundUpdaterDidFinishUpdating:)]) {
			[delegate backgroundUpdaterDidFinishUpdating:self];
		}
	}
}

- (void)updater:(Updater *)theUpdater didStartUpdatingBundle:(NSString *)bundleName
{
	NSLog(@"Updating bundle %@", bundleName);
}

- (void)updater:(Updater *)theUpdater didFinishUpdatingBundle:(NSString *)bundleName
{
	NSLog(@"Finished updating bundle %@", bundleName);
}

- (void)updater:(Updater *)theUpdater didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	NSLog(@"Updated: %@ (%lu of %lu)", pathToFile, fileNumber, totalFiles);
}

- (void)updaterDidFinish:(Updater *)theUpdater;
{
	NSLog(@"Update complete.");
	isUpdating = NO;
	if ([delegate respondsToSelector:@selector(backgroundUpdaterDidFinishUpdating:)]) {
		[delegate backgroundUpdaterDidFinishUpdating:self];
	}
}

@end
