//
//  Updater.h
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTPBundleManager.h"
#import "HTTPBundleManager.h"
#import "CoreDataManager.h"
#import "UpdaterDataProvider.h"

@protocol UpdaterDelegate;

@interface Updater : NSObject <UpdaterDataProviderDelegate, HTTPBundleManagerDelegate> {
	
	id<UpdaterDelegate> delegate;
	
	UpdaterDataProvider *dataProvider;
	BOOL checking;
	
	NSArray *availableTours;
	NSMutableArray *updatableTours;
	
	BOOL encounteredErrors;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, readonly, getter=isChecking) BOOL checking;
@property (nonatomic, retain) NSMutableArray *updatableTours;
@property (nonatomic, readonly, getter=didEncounterErrors) BOOL encounteredErrors;

- (void)checkForUpdates;
- (void)performUpdate;

@end

@protocol UpdaterDelegate <NSObject>

- (void)updater:(Updater *)updater hasAvailableUpdates:(NSUInteger)availableUpdates;
- (void)updater:(Updater *)updater didFailWithError:(NSError *)error;
- (void)updaterDidFailToRetrieveToursXML:(Updater *)updater;

@optional

- (void)updater:(Updater *)updater didStartUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)updater:(Updater *)updater didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)pathToFile;
- (void)updater:(Updater *)updater didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)updater:(Updater *)updater didStartUpdatingBundle:(NSString *)bundleName;
- (void)updater:(Updater *)updater didFinishUpdatingBundle:(NSString *)bundleName;
- (void)updaterDidFinish:(Updater *)updater;

@end