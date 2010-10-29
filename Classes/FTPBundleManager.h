//
//  FTPBundleManager.h
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTPRequest.h"

#define FTP_ROOT @"ftp://10.10.12.91/Documents/Development/MFAGuide/Resources/"
#define FTP_USERNAME @"rbrecher"
#define FTP_PASSWORD @"maqr0ll!"

@protocol FTPBundleManagerDelegate;

@interface FTPBundleManager : NSObject {
	
	id<FTPBundleManagerDelegate> delegate;
	
	FTPRequest *ftpRequest;
	
	NSFileManager *fileManager;
	NSString *bundleName;
	NSMutableArray *bundleFiles;
	NSMutableArray *bundleDirectories;
	NSString *currentBundlePath;
	
	NSUInteger currentFile;
	NSUInteger totalFiles;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) FTPRequest *ftpRequest;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *bundleName;
@property (nonatomic, retain) NSMutableArray *bundleFiles;
@property (nonatomic, retain) NSMutableArray *bundleDirectories;
@property (nonatomic, retain) NSString *currentBundlePath;

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName;

@end

@protocol FTPBundleManagerDelegate <NSObject>

- (void)bundleManager:(FTPBundleManager *)bundleManager didEncounterError:(NSError *)error;
- (void)bundleManager:(FTPBundleManager *)bundleManager didFailWithError:(NSError *)error;

@optional

- (void)bundleManager:(FTPBundleManager *)bundleManager didStartUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)bundleManager:(FTPBundleManager *)bundleManager didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)pathToFile;
- (void)bundleManager:(FTPBundleManager *)bundleManager didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)bundleManagerCompletedUpdate:(FTPBundleManager *)bundleManager;

@end